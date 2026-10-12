import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/chat_model.dart';
import '../services/auth_service.dart';
import '../services/match_log_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ui.dart';

/// Trận đấu & rank: ghi trận đã chơi cùng đồng đội BLUSH (đồng đội xác nhận mới tính nhiệm vụ), xác nhận trận người khác ghi,
/// khai rank từng game. App không đọc được kết quả từ game thật nên dùng cách tự ghi + xác nhận chéo.
class MatchLogScreen extends StatefulWidget {
  const MatchLogScreen({super.key});

  @override
  State<MatchLogScreen> createState() => _MatchLogScreenState();
}

class _MatchLogScreenState extends State<MatchLogScreen> {
  late final MatchLogService _service = MatchLogService(context.read<AuthService>());
  List<MatchLog>? _matches;
  MatchOptions? _options;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final matches = await _service.getMine();
      final options = await _service.getOptions();
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _options = options;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _replace(MatchLog m) => setState(() => _matches = [for (final x in _matches!) x.id == m.id ? m : x]);

  Future<void> _confirm(MatchLog m, bool ok) async {
    try {
      _replace(await _service.confirm(m.id, ok));
      if (mounted) showSuccessSnack(context, ok ? 'Đã xác nhận. Trận được tính vào nhiệm vụ của hai bạn.' : 'Đã báo trận này không đúng.');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    }
  }

  Future<void> _setRank(GameRank game, String? rank) async {
    try {
      final updated = await _service.setRank(game.gameId, rank);
      if (!mounted) return;
      setState(() => _options = MatchOptions(teammates: _options!.teammates, games: [for (final g in _options!.games) g.gameId == updated.gameId ? updated : g]));
      showSuccessSnack(context, rank == null ? 'Đã bỏ rank ${game.gameName}.' : 'Đã lưu rank ${game.gameName}: $rank.');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    }
  }

  Future<void> _logNew() async {
    final options = _options!;
    if (options.teammates.isEmpty) {
      showErrorSnack(context, 'Chỉ ghi trận với đồng đội bạn đã trò chuyện trên BLUSH. Vào tab Đồng đội để bắt chuyện trước nhé.');
      return;
    }
    if (options.games.isEmpty) {
      showErrorSnack(context, 'Thêm game trong Sở thích chơi game trước.');
      return;
    }
    final created = await showModalBottomSheet<MatchLog>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NewMatchSheet(options: options, service: _service),
    );
    if (created != null && mounted) {
      setState(() => _matches = [created, ...?_matches]);
      showSuccessSnack(context, 'Đã ghi trận. Chờ ${created.teammate.displayName} xác nhận.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final matches = _matches;
    final options = _options;
    final myId = context.read<AuthService>().currentUser?.id;

    Widget body;
    if (_error != null) {
      body = Center(child: TextButton(onPressed: _load, child: Text('$_error Chạm để thử lại.')));
    } else if (matches == null || options == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final pending = matches.where((m) => m.canConfirm).toList();
      final history = matches.where((m) => !m.canConfirm).toList();
      body = RefreshIndicator(
        onRefresh: _load,
        child: PageBody(
          children: [
            Text('Ghi lại trận vừa chơi cùng đồng đội BLUSH. Đồng đội xác nhận thì trận được tính vào nhiệm vụ và huy hiệu.', style: text.bodySmall),
            const SizedBox(height: AppSpace.md),
            ElevatedButton.icon(onPressed: _logNew, icon: const Icon(Icons.add), label: const Text('Ghi trận mới')),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xl),
              const SectionHeader('Chờ bạn xác nhận'),
              for (final m in pending) ...[
                _MatchCard(match: m, myId: myId, onConfirm: (ok) => _confirm(m, ok)),
                const SizedBox(height: AppSpace.sm),
              ],
            ],
            const SizedBox(height: AppSpace.xl),
            const SectionHeader('Rank của bạn'),
            if (options.games.isEmpty)
              AppCard(child: Text('Chưa có game nào trong hồ sơ.', style: text.bodySmall))
            else
              for (final g in options.games) ...[
                AppCard(
                  child: Row(
                    children: [
                      Expanded(child: Text(g.gameName, style: text.titleSmall)),
                      if (g.ranks.isEmpty)
                        Text('Không có bảng rank', style: text.bodySmall)
                      else
                        DropdownButton<String?>(
                          value: g.rank,
                          underline: const SizedBox.shrink(),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Chưa khai')),
                            for (final r in g.ranks) DropdownMenuItem<String?>(value: r, child: Text(r)),
                          ],
                          onChanged: (r) => _setRank(g, r),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
              ],
            const SizedBox(height: AppSpace.lg),
            const SectionHeader('Lịch sử trận'),
            if (history.isEmpty)
              AppCard(child: Text('Chưa có trận nào.', style: text.bodySmall, textAlign: TextAlign.center))
            else
              for (final m in history) ...[
                _MatchCard(match: m, myId: myId),
                const SizedBox(height: AppSpace.sm),
              ],
          ],
        ),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Trận đấu & rank')), body: body);
  }
}

class _MatchCard extends StatelessWidget {
  final MatchLog match;
  final String? myId;
  final ValueChanged<bool>? onConfirm;

  const _MatchCard({required this.match, required this.myId, this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final m = match;
    // Hiện người còn lại (không phải mình)
    final partner = m.reporter.id == myId ? m.teammate : m.reporter;
    final (statusLabel, statusColor) = switch (m.status) {
      'Confirmed' => ('Đã xác nhận', ThemeService.green),
      'Rejected' => ('Bị từ chối', ThemeService.red),
      _ => (m.canConfirm ? 'Chờ bạn xác nhận' : 'Chờ ${partner.displayName} xác nhận', Colors.orange),
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(imageUrl: partner.avatarUrl, fallback: partner.avatarEmoji, size: 36),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${m.gameName} cùng ${partner.displayName}', style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(formatChatTime(m.createdAt), style: text.bodySmall),
                  ],
                ),
              ),
              TagChip(m.isWin ? 'Thắng' : 'Thua', color: m.isWin ? ThemeService.green : ThemeService.red),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          if (onConfirm != null)
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => onConfirm!(false), child: const Text('Không đúng'))),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: ElevatedButton(onPressed: () => onConfirm!(true), child: const Text('Xác nhận'))),
              ],
            )
          else
            TagChip(statusLabel, color: statusColor),
        ],
      ),
    );
  }
}

class _NewMatchSheet extends StatefulWidget {
  final MatchOptions options;
  final MatchLogService service;

  const _NewMatchSheet({required this.options, required this.service});

  @override
  State<_NewMatchSheet> createState() => _NewMatchSheetState();
}

class _NewMatchSheetState extends State<_NewMatchSheet> {
  late ChatUser _teammate = widget.options.teammates.first;
  late GameRank _game = widget.options.games.first;
  bool _win = true;
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final match = await widget.service.create(teammateId: _teammate.id, gameId: _game.gameId, win: _win);
      if (mounted) Navigator.pop(context, match);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ghi trận mới', style: text.titleMedium),
          const SizedBox(height: AppSpace.md),
          DropdownButtonFormField<ChatUser>(
            initialValue: _teammate,
            decoration: const InputDecoration(labelText: 'Chơi cùng'),
            items: [for (final t in widget.options.teammates) DropdownMenuItem(value: t, child: Text(t.displayName, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => setState(() => _teammate = v ?? _teammate),
          ),
          const SizedBox(height: AppSpace.md),
          DropdownButtonFormField<GameRank>(
            initialValue: _game,
            decoration: const InputDecoration(labelText: 'Game'),
            items: [for (final g in widget.options.games) DropdownMenuItem(value: g, child: Text(g.gameName))],
            onChanged: (v) => setState(() => _game = v ?? _game),
          ),
          const SizedBox(height: AppSpace.md),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Thắng'), icon: Icon(Icons.emoji_events_outlined)),
              ButtonSegment(value: false, label: Text('Thua'), icon: Icon(Icons.sentiment_dissatisfied_outlined)),
            ],
            selected: {_win},
            onSelectionChanged: (s) => setState(() => _win = s.first),
          ),
          const SizedBox(height: AppSpace.md),
          ElevatedButton(
            onPressed: _sending ? null : _send,
            child: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Gửi cho đồng đội xác nhận'),
          ),
        ],
      ),
    );
  }
}
