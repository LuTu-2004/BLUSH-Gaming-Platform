import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

/// Phòng chat 1-1.
/// TODO: chat thời gian thực qua SignalR + câu hỏi phá băng từ backend (bước 4).
class ChatRoomScreen extends StatefulWidget {
  final String teammateName;
  final String teammateAvatar;

  const ChatRoomScreen({super.key, this.teammateName = 'Thùy Dung', this.teammateAvatar = '🌸'});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _Message {
  final String sender; // 'me' | 'them' | 'ai'
  final String text;
  final String time;

  const _Message(this.sender, this.text, this.time);
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  static const _icebreakers = [
    'Hôm nay cậu tính leo rank hay chơi giải trí nhẹ nhàng?',
    'Lúc tryhard cậu hay mở nhạc gì? Cho tớ xin vài bài với.',
    'Chủ nhật của cậu thường ngủ nướng hay leo rank từ sáng?',
  ];

  final List<_Message> _messages = [
    const _Message('ai', 'Hai bạn đã được ghép đội với độ hợp 94%. Bắt đầu trò chuyện nào!', '14:20'),
    const _Message('them', 'Hi bạn! Hôm nay tính leo rank hay chơi tấu hài nè?', '14:21'),
  ];

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _messages.add(_Message('me', text, _formatTime(DateTime.now()))));
    _textController.clear();

    // Đợi frame vẽ xong tin mới rồi mới cuộn xuống cuối
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  // AI gợi ý câu mở đầu: điền vào ô nhập để người dùng sửa trước khi gửi
  void _suggestOpener() {
    _textController.text = (List.of(_icebreakers)..shuffle()).first;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundColor: t.cardHigh, child: Text(widget.teammateAvatar, style: const TextStyle(fontSize: 18))),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.teammateName, style: text.titleSmall, overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: ThemeService.green),
                      const SizedBox(width: 4),
                      Text('Đang online', style: text.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Gợi ý AI: nằm gọn 1 dòng dưới thanh tiêu đề
          Material(
            color: ThemeService.accent.withValues(alpha: 0.12),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.auto_awesome, color: ThemeService.accent),
              title: Text('Chưa biết mở lời thế nào?', style: text.titleSmall),
              subtitle: Text('AI gợi ý câu mở đầu dựa trên điểm chung', style: text.bodySmall),
              trailing: TextButton(onPressed: _suggestOpener, child: const Text('Gợi ý')),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpace.lg),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _Bubble(message: _messages[i]),
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
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Nhắn cho ${widget.teammateName}...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                        fillColor: t.card,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  IconButton.filled(tooltip: 'Gửi', onPressed: _sendMessage, icon: const Icon(Icons.send_rounded)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Message message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;

    // Tin hệ thống / AI: nằm giữa, chữ nhỏ
    if (message.sender == 'ai') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md, horizontal: AppSpace.xl),
        child: Text(message.text, textAlign: TextAlign.center, style: text.bodySmall),
      );
    }

    final isMe = message.sender == 'me';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? ThemeService.accent : t.card,
          border: isMe ? null : Border.all(color: t.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isMe ? AppRadius.lg : 4),
            bottomRight: Radius.circular(isMe ? 4 : AppRadius.lg),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.text, style: text.bodyMedium?.copyWith(color: isMe ? Colors.white : t.textPrimary)),
            const SizedBox(height: 2),
            Text(message.time, style: text.labelSmall?.copyWith(color: isMe ? Colors.white70 : t.textMuted)),
          ],
        ),
      ),
    );
  }
}
