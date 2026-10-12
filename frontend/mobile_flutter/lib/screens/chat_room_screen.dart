import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/chat_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/block_user.dart';
import '../widgets/report_user_sheet.dart';
import '../widgets/ui.dart';

/// Phòng chat 1-1 với [userId] (api/chat). Tin mới nhận ngay qua SignalR;
/// không kết nối được thì cứ [pollInterval] hỏi lại server 1 lần.
/// Đầu phòng có câu hỏi phá băng 2 lựa chọn, chọn xong mới thấy người kia chọn gì.
class ChatRoomScreen extends StatefulWidget {
  final String userId;
  final String displayName;
  final String avatarEmoji;
  final String? avatarUrl;

  const ChatRoomScreen({super.key, required this.userId, required this.displayName, this.avatarEmoji = '🎮', this.avatarUrl});

  static const pollInterval = Duration(seconds: 5);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  // Câu mở đầu có sẵn: điền vào ô nhập để người dùng sửa trước khi gửi
  static const _openers = [
    'Hôm nay cậu tính leo rank hay chơi giải trí nhẹ nhàng?',
    'Lúc tryhard cậu hay mở nhạc gì? Cho tớ xin vài bài với.',
    'Chủ nhật của cậu thường ngủ nướng hay leo rank từ sáng?',
  ];

  late final AuthService _auth = context.read<AuthService>();
  late final ChatService _service = ChatService(_auth);
  late final ChatRealtime _realtime = ChatRealtime.factory(_auth);
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _pollTimer;

  ChatRoom? _room;
  final List<ChatMessage> _messages = [];
  bool _hasOlder = false;
  bool _loadingOlder = false;
  bool _sending = false;
  String? _error;

  String? get _myId => _auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _subs.add(_realtime.messages.listen(_onMessage));
    _subs.add(_realtime.rooms.listen((room) {
      if (room.id == _room?.id && mounted) setState(() => _room = room);
    }));
    _open();
    _realtime.start().then((_) {
      if (mounted && !_realtime.connected) _pollTimer = Timer.periodic(ChatRoomScreen.pollInterval, (_) => _poll());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _realtime.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() => _error = null);
    try {
      final room = await _service.openRoom(widget.userId);
      final messages = await _service.getMessages(room.id);
      if (!mounted) return;
      setState(() {
        _room = room;
        _messages
          ..clear()
          ..addAll(messages);
        _hasOlder = messages.length >= ChatService.pageSize;
      });
      _scrollToBottom(jump: true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _onMessage(ChatMessage m) {
    if (m.roomId != _room?.id || !mounted) return;
    if (_merge([m])) _scrollToBottom();
  }

  /// Thêm tin chưa có (tin mình gửi về cả qua REST lẫn SignalR -> bỏ trùng theo id). true = có tin mới.
  bool _merge(Iterable<ChatMessage> incoming) {
    final known = _messages.map((m) => m.id).toSet();
    final fresh = incoming.where((m) => !known.contains(m.id)).toList();
    if (fresh.isEmpty) return false;
    setState(() => _messages
      ..addAll(fresh)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
    return true;
  }

  Future<void> _poll() async {
    final room = _room;
    if (room == null) return;
    try {
      final latest = await _service.getMessages(room.id);
      final updated = await _service.getRoom(room.id);
      if (!mounted) return;
      setState(() => _room = updated);
      if (_merge(latest)) _scrollToBottom();
    } on ApiException {
      // Mất mạng tạm thời: lần sau hỏi lại
    }
  }

  Future<void> _loadOlder() async {
    final room = _room;
    if (room == null || _messages.isEmpty) return;
    setState(() => _loadingOlder = true);
    try {
      final older = await _service.getMessages(room.id, before: _messages.first.createdAt);
      if (!mounted) return;
      _merge(older);
      setState(() => _hasOlder = older.length >= ChatService.pageSize);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  Future<void> _send() async {
    final room = _room;
    final content = _textController.text.trim();
    if (room == null || content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final message = await _service.send(room.id, content);
      if (!mounted) return;
      _textController.clear();
      _merge([message]);
      _scrollToBottom();
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message); // giữ nguyên chữ trong ô để gửi lại
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _answer(String choice) async {
    final room = _room;
    if (room == null) return;
    try {
      final updated = await _service.answerIceBreaker(room.id, choice);
      if (mounted) setState(() => _room = updated);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    }
  }

  void _scrollToBottom({bool jump = false}) {
    // Đợi frame vẽ xong tin mới rồi mới cuộn xuống cuối
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final end = _scrollController.position.maxScrollExtent;
      jump ? _scrollController.jumpTo(end) : _scrollController.animateTo(end, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final room = _room;
    final other = room?.other;
    final name = other?.displayName ?? widget.displayName;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(imageUrl: other?.avatarUrl ?? widget.avatarUrl, fallback: other?.avatarEmoji ?? widget.avatarEmoji, size: 36),
            const SizedBox(width: AppSpace.md),
            Expanded(child: Text(name, style: text.titleSmall, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Báo cáo hoặc chặn',
            onSelected: (action) async {
              if (action == 'report') {
                ReportUserSheet.show(context, userId: widget.userId, displayName: name);
              } else if (await confirmAndBlockUser(context, userId: widget.userId, displayName: name) && context.mounted) {
                Navigator.pop(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('Báo cáo vi phạm')),
              PopupMenuItem(value: 'block', child: Text('Chặn')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: AppSpace.page,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: AppSpace.lg),
                          ElevatedButton(onPressed: _open, child: const Text('Thử lại')),
                        ],
                      ),
                    ),
                  )
                : room == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpace.lg),
                        children: [
                          if (_hasOlder)
                            Center(
                              child: TextButton(
                                onPressed: _loadingOlder ? null : _loadOlder,
                                child: Text(_loadingOlder ? 'Đang tải...' : 'Xem tin cũ hơn'),
                              ),
                            ),
                          if (room.iceBreaker case final ib?) _IceBreakerCard(iceBreaker: ib, otherName: name, onAnswer: _answer),
                          if (_messages.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(AppSpace.xl),
                              child: Text('Hai bạn chưa nhắn gì. Gửi lời chào đầu tiên nhé!', textAlign: TextAlign.center, style: text.bodySmall),
                            ),
                          for (final m in _messages) _Bubble(message: m, isMine: m.senderId == _myId),
                        ],
                      ),
          ),
          // Gợi ý câu mở đầu: chỉ hiện khi chưa nhắn gì
          if (room != null && _messages.where((m) => !m.isSystem).isEmpty)
            Material(
              color: ThemeService.accent.withValues(alpha: 0.12),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.lightbulb_outline, color: ThemeService.accent),
                title: Text('Chưa biết mở lời thế nào?', style: text.titleSmall),
                trailing: TextButton(
                  onPressed: () => _textController.text = (List.of(_openers)..shuffle()).first,
                  child: const Text('Gợi ý'),
                ),
              ),
            ),
          // Ô nhập tin nhắn
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.sm, AppSpace.sm),
              decoration: BoxDecoration(color: t.header, border: Border(top: BorderSide(color: t.border))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: room != null,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Nhắn cho $name...',
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                        fillColor: t.card,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  IconButton.filled(tooltip: 'Gửi', onPressed: room == null || _sending ? null : _send, icon: const Icon(Icons.send_rounded)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IceBreakerCard extends StatelessWidget {
  final ChatIceBreaker iceBreaker;
  final String otherName;
  final ValueChanged<String> onAnswer;

  const _IceBreakerCard({required this.iceBreaker, required this.otherName, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ib = iceBreaker;
    final mine = ib.myChoice;
    final theirs = ib.theirChoice;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: AppCard(
        borderColor: ThemeService.accent.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, size: 18, color: ThemeService.accent),
                const SizedBox(width: AppSpace.xs),
                Text('Câu hỏi phá băng', style: text.labelMedium),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Text(ib.question, style: text.titleSmall),
            const SizedBox(height: AppSpace.md),
            if (mine == null)
              Row(
                children: [
                  for (final choice in ['A', 'B']) ...[
                    if (choice == 'B') const SizedBox(width: AppSpace.sm),
                    Expanded(child: OutlinedButton(onPressed: () => onAnswer(choice), child: Text(ib.labelOf(choice), textAlign: TextAlign.center))),
                  ],
                ],
              )
            else ...[
              Text('Bạn chọn: ${ib.labelOf(mine)}', style: text.bodyMedium),
              const SizedBox(height: 2),
              Text(
                theirs != null ? '$otherName chọn: ${ib.labelOf(theirs)}' : 'Đang chờ $otherName trả lời...',
                style: text.bodySmall,
              ),
            ],
            if (mine == null && ib.theyAnswered) ...[
              const SizedBox(height: AppSpace.sm),
              Text('$otherName đã trả lời. Chọn đi để xem bạn ấy chọn gì!', style: text.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _Bubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;

    // Tin hệ thống: nằm giữa, chữ nhỏ
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md, horizontal: AppSpace.xl),
        child: Text(message.content, textAlign: TextAlign.center, style: text.bodySmall),
      );
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? ThemeService.accent : t.card,
          border: isMine ? null : Border.all(color: t.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isMine ? AppRadius.lg : 4),
            bottomRight: Radius.circular(isMine ? 4 : AppRadius.lg),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.content, style: text.bodyMedium?.copyWith(color: isMine ? Colors.white : t.textPrimary)),
            const SizedBox(height: 2),
            Text(formatChatTime(message.createdAt), style: text.labelSmall?.copyWith(color: isMine ? Colors.white70 : t.textMuted)),
          ],
        ),
      ),
    );
  }
}
