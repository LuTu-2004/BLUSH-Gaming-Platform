import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/feed_model.dart';
import '../services/auth_service.dart';
import '../services/feed_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/post_card.dart';
import '../widgets/ui.dart';
import 'leaderboard_screen.dart';
import 'vip_screen.dart';

/// Tab Cộng đồng: Bảng tin (bài từ các Zone mình tham gia), Zone (danh sách cộng đồng), Xếp hạng.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(tabs: [Tab(text: 'Bảng tin'), Tab(text: 'Zone'), Tab(text: 'Xếp hạng')]),
          Expanded(child: TabBarView(children: [_FeedTab(), _ZonesTab(), LeaderboardScreen()])),
        ],
      ),
    );
  }
}

// ── Danh sách bài có "Tải thêm" (dùng cho Bảng tin và màn 1 Zone) ──────
class _PostList extends StatefulWidget {
  final int? zoneId; // null = bảng tin
  final Widget? header;
  final Widget empty;

  const _PostList({super.key, this.zoneId, this.header, required this.empty});

  @override
  State<_PostList> createState() => _PostListState();
}

class _PostListState extends State<_PostList> {
  late final FeedService _service = FeedService(context.read<AuthService>());
  List<Post>? _posts;
  bool _hasMore = false;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    try {
      final posts = await _service.getPosts(zoneId: widget.zoneId);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _hasMore = posts.length >= FeedService.pageSize;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void addPost(Post post) => setState(() => _posts = [post, ...?_posts]);

  Future<void> _loadMore() async {
    final posts = _posts;
    if (posts == null || posts.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final older = await _service.getPosts(zoneId: widget.zoneId, before: posts.last.createdAt);
      if (!mounted) return;
      setState(() {
        _posts = [...posts, ...older];
        _hasMore = older.length >= FeedService.pageSize;
      });
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final posts = _posts;
    return RefreshIndicator(
      onRefresh: reload,
      child: PageBody(
        children: [
          if (widget.header != null) ...[widget.header!, const SizedBox(height: AppSpace.md)],
          if (_error != null)
            AppCard(onTap: reload, child: Text('$_error Chạm để thử lại.', style: text.bodySmall, textAlign: TextAlign.center))
          else if (posts == null)
            const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator()))
          else if (posts.isEmpty)
            widget.empty
          else ...[
            for (final p in posts) ...[
              PostCard(
                key: ValueKey(p.id),
                post: p,
                showZone: widget.zoneId == null,
                onChanged: (updated) => setState(() => _posts = [for (final x in _posts!) x.id == updated.id ? updated : x]),
                onRemoved: () => setState(() => _posts = _posts!.where((x) => x.id != p.id).toList()),
                onAuthorBlocked: () => setState(() => _posts = _posts!.where((x) => x.author.id != p.author.id).toList()),
              ),
              const SizedBox(height: AppSpace.md),
            ],
            if (_hasMore)
              Center(
                child: OutlinedButton(onPressed: _loadingMore ? null : _loadMore, child: Text(_loadingMore ? 'Đang tải...' : 'Xem bài cũ hơn')),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Bảng tin ────────────────────────────────────────────────────────
class _FeedTab extends StatefulWidget {
  const _FeedTab();

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  final _listKey = GlobalKey<_PostListState>();

  Future<void> _write() async {
    final zones = (await FeedService(context.read<AuthService>()).getZones()).where((z) => z.isMember && z.canAccess).toList();
    if (!mounted) return;
    if (zones.isEmpty) {
      showErrorSnack(context, 'Tham gia 1 Zone trước để đăng bài.');
      DefaultTabController.of(context).animateTo(1);
      return;
    }
    final post = await showPostComposer(context, zones: zones);
    if (post != null) _listKey.currentState?.addPost(post);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _PostList(
      key: _listKey,
      header: AppCard(
        onTap: _write,
        child: Row(
          children: [
            const Icon(Icons.edit_outlined, color: ThemeService.accent),
            const SizedBox(width: AppSpace.md),
            Expanded(child: Text('Chia sẻ chiến tích, rủ đồng đội...', style: text.bodyMedium)),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
      empty: AppCard(
        child: Column(
          children: [
            Text('Bảng tin trống. Tham gia Zone hợp gu để xem bài của mọi người.', style: text.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.sm),
            Builder(builder: (ctx) => TextButton(onPressed: () => DefaultTabController.of(ctx).animateTo(1), child: const Text('Xem các Zone'))),
          ],
        ),
      ),
    );
  }
}

// ── Danh sách Zone ──────────────────────────────────────────────────
class _ZonesTab extends StatefulWidget {
  const _ZonesTab();

  @override
  State<_ZonesTab> createState() => _ZonesTabState();
}

class _ZonesTabState extends State<_ZonesTab> {
  late final FeedService _service = FeedService(context.read<AuthService>());
  List<Zone>? _zones;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final zones = await _service.getZones();
      if (!mounted) return;
      setState(() {
        _zones = zones;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _replace(Zone z) => setState(() => _zones = [for (final x in _zones!) x.id == z.id ? z : x]);

  Future<void> _open(Zone zone) async {
    if (!zone.canAccess) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const VipScreen()));
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ZoneScreen(zone: zone)));
    _load(); // có thể vừa tham gia / rời trong màn Zone
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final zones = _zones;
    return RefreshIndicator(
      onRefresh: _load,
      child: PageBody(
        children: [
          if (_error != null)
            AppCard(onTap: _load, child: Text('$_error Chạm để thử lại.', style: text.bodySmall, textAlign: TextAlign.center))
          else if (zones == null)
            const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator()))
          else ...[
            Text('Zone là cộng đồng theo game và mục đích chơi. Khảo sát xong bạn được xếp vào Zone hợp gu.', style: text.bodySmall),
            const SizedBox(height: AppSpace.md),
            for (final z in zones) ...[
              _ZoneCard(zone: z, onTap: () => _open(z), onChanged: _replace),
              const SizedBox(height: AppSpace.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final Zone zone;
  final VoidCallback onTap;
  final ValueChanged<Zone> onChanged;

  const _ZoneCard({required this.zone, required this.onTap, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(zone.isVipOnly ? Icons.lock_outline : Icons.forum_outlined, color: zone.isVipOnly ? ThemeService.yellow : ThemeService.accent),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.name, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${zone.gameName} · ${zone.purposeLabel} · ${zone.memberCount} thành viên', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (zone.isVipOnly && !zone.canAccess) Text('Dành cho BLUSH Pass Pro', style: text.bodySmall?.copyWith(color: ThemeService.yellow)),
              ],
            ),
          ),
          if (zone.canAccess) _JoinButton(zone: zone, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _JoinButton extends StatefulWidget {
  final Zone zone;
  final ValueChanged<Zone> onChanged;

  const _JoinButton({required this.zone, required this.onChanged});

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    final service = FeedService(context.read<AuthService>());
    setState(() => _busy = true);
    try {
      widget.onChanged(widget.zone.isMember ? await service.leave(widget.zone.id) : await service.join(widget.zone.id));
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.zone.isMember
        ? OutlinedButton(onPressed: _busy ? null : _toggle, child: const Text('Đã tham gia'))
        : ElevatedButton(onPressed: _busy ? null : _toggle, child: const Text('Tham gia'));
  }
}

// ── Màn 1 Zone ──────────────────────────────────────────────────────
class ZoneScreen extends StatefulWidget {
  final Zone zone;

  const ZoneScreen({super.key, required this.zone});

  @override
  State<ZoneScreen> createState() => _ZoneScreenState();
}

class _ZoneScreenState extends State<ZoneScreen> {
  final _listKey = GlobalKey<_PostListState>();
  late Zone _zone = widget.zone;

  Future<void> _write() async {
    final post = await showPostComposer(context, zones: [_zone]);
    if (post != null) _listKey.currentState?.addPost(post);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_zone.name, overflow: TextOverflow.ellipsis),
        actions: [Padding(padding: const EdgeInsets.only(right: AppSpace.sm), child: _JoinButton(zone: _zone, onChanged: (z) => setState(() => _zone = z)))],
      ),
      floatingActionButton: _zone.isMember ? FloatingActionButton.extended(onPressed: _write, icon: const Icon(Icons.edit), label: const Text('Viết bài')) : null,
      body: _PostList(
        key: _listKey,
        zoneId: _zone.id,
        header: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_zone.gameName} · ${_zone.purposeLabel} · ${_zone.memberCount} thành viên', style: text.bodySmall),
              if (_zone.description != null) ...[const SizedBox(height: AppSpace.xs), Text(_zone.description!, style: text.bodyMedium)],
              if (!_zone.isMember) ...[const SizedBox(height: AppSpace.xs), Text('Tham gia Zone để đăng bài.', style: text.bodySmall)],
            ],
          ),
        ),
        empty: AppCard(child: Text('Zone chưa có bài nào. Hãy là người mở đầu!', style: text.bodySmall, textAlign: TextAlign.center)),
      ),
    );
  }
}

// ── Viết bài ────────────────────────────────────────────────────────
/// Mở bảng viết bài, chọn Zone (nếu có nhiều). Trả về bài vừa đăng, null nếu hủy.
Future<Post?> showPostComposer(BuildContext context, {required List<Zone> zones}) => showModalBottomSheet<Post>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _Composer(zones: zones),
    );

class _Composer extends StatefulWidget {
  final List<Zone> zones;

  const _Composer({required this.zones});

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _input = TextEditingController();
  late int _zoneId = widget.zones.first.id;
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_input.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final post = await FeedService(context.read<AuthService>()).createPost(_zoneId, _input.text);
      if (mounted) Navigator.pop(context, post);
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
          Text('Viết bài', style: text.titleMedium),
          const SizedBox(height: AppSpace.md),
          if (widget.zones.length > 1) ...[
            DropdownButtonFormField<int>(
              initialValue: _zoneId,
              decoration: const InputDecoration(labelText: 'Đăng vào Zone'),
              items: [for (final z in widget.zones) DropdownMenuItem(value: z.id, child: Text(z.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _zoneId = v ?? _zoneId),
            ),
            const SizedBox(height: AppSpace.md),
          ],
          TextField(
            controller: _input,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'VD: Tối nay 9h ai leo rank Liên Quân, thiếu 1 trợ thủ!'),
          ),
          const SizedBox(height: AppSpace.sm),
          ElevatedButton(
            onPressed: _sending ? null : _send,
            child: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Đăng bài'),
          ),
        ],
      ),
    );
  }
}
