import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../services/feed_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../widgets/auth_widgets.dart';
import 'badges_screen.dart';
import 'community_screen.dart';
import 'match_log_screen.dart';
import 'quests_screen.dart';
import 'vip_screen.dart';

/// Danh sách thông báo (GET api/notifications). Bấm vào: đánh dấu đã đọc + mở đúng màn (Zone, Nhiệm vụ, BLUSH Pass).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationApi _api = NotificationApi(context.read<AuthService>());
  List<AppNotification>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _api.getAll();
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _readAll() async {
    try {
      await _api.markAllRead();
      if (mounted) setState(() => _items = [for (final n in _items ?? <AppNotification>[]) n.markRead()]);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    }
  }

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      setState(() => _items = [for (final x in _items!) x.id == n.id ? x.markRead() : x]);
      _api.markRead(n.id).catchError((_) {});
    }
    final link = n.link;
    if (link == null) return;
    Widget? screen;
    if (link == 'vip') {
      screen = const VipScreen();
    } else if (link == 'quests') {
      screen = const QuestsScreen();
    } else if (link == 'badges') {
      screen = const BadgesScreen();
    } else if (link == 'matches') {
      screen = const MatchLogScreen();
    } else if (link.startsWith('zone:')) {
      final zoneId = int.tryParse(link.substring(5));
      try {
        final zones = await FeedService(context.read<AuthService>()).getZones();
        final zone = zones.where((z) => z.id == zoneId).firstOrNull;
        if (zone != null && zone.canAccess) screen = ZoneScreen(zone: zone);
      } on ApiException catch (e) {
        if (mounted) showErrorSnack(context, e.message);
      }
    }
    if (screen != null && mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
  }

  static IconData _iconOf(String type) => switch (type) {
        'PostLiked' => Icons.favorite,
        'PostCommented' => Icons.mode_comment,
        'ReportResolved' => Icons.verified_user,
        'Warning' => Icons.warning_amber_rounded,
        'QuestCompleted' => Icons.task_alt,
        'VipActivated' || 'VipExpiring' => Icons.workspace_premium,
        'BadgeEarned' => Icons.military_tech,
        'MatchToConfirm' || 'MatchConfirmed' => Icons.sports_esports,
        _ => Icons.notifications,
      };

  static Color _colorOf(String type) => switch (type) {
        'PostLiked' => ThemeService.red,
        'Warning' => Colors.orange,
        'QuestCompleted' || 'ReportResolved' => ThemeService.green,
        'VipActivated' || 'VipExpiring' || 'BadgeEarned' => ThemeService.yellow,
        _ => ThemeService.accent,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final items = _items;

    Widget body;
    if (_error != null) {
      body = Center(child: TextButton(onPressed: _load, child: Text('$_error Chạm để thử lại.')));
    } else if (items == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (items.isEmpty) {
      body = Center(child: Text('Chưa có thông báo nào.', style: text.bodyMedium));
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: t.border),
          itemBuilder: (_, i) {
            final n = items[i];
            return ListTile(
              onTap: () => _open(n),
              tileColor: n.isRead ? null : ThemeService.accent.withValues(alpha: 0.06),
              leading: CircleAvatar(
                backgroundColor: _colorOf(n.type).withValues(alpha: 0.15),
                child: Icon(_iconOf(n.type), color: _colorOf(n.type), size: 20),
              ),
              title: Text(n.title, style: n.isRead ? text.bodyMedium : text.titleSmall),
              subtitle: Text(
                [if (n.body != null) n.body!, formatChatTime(n.createdAt)].join('\n'),
                style: text.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: n.body != null,
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (items != null && items.any((n) => !n.isRead)) TextButton(onPressed: _readAll, child: const Text('Đọc tất cả')),
        ],
      ),
      body: body,
    );
  }
}
