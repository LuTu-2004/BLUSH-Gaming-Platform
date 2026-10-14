import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../models/admin_model.dart';
import '../../models/payment_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/ui.dart';
import 'admin_widgets.dart';

/// Trang Người dùng: tìm kiếm, lọc theo vai trò / trạng thái, khóa / mở khóa, đổi vai trò (api/admin/users).
/// Khóa hoặc đổi vai trò có hiệu lực ngay: người đó bị đăng xuất ở lần gọi API kế tiếp.
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  static const _roleFilters = [(null, 'Mọi vai trò'), ('User', 'Game thủ'), ('Staff', 'Staff'), ('Admin', 'Admin')];
  static const _statusFilters = [(null, 'Mọi trạng thái'), (AdminUser.active, 'Hoạt động'), (AdminUser.suspended, 'Tạm khóa'), (AdminUser.banned, 'Khóa vĩnh viễn')];
  static const _suspendDays = 7;

  late final AdminService _service = AdminService(context.read<AuthService>());
  final _searchController = TextEditingController();
  String? _role;
  String? _status;
  final List<AdminUser> _items = [];
  AdminUserPage? _lastPage; // giữ số liệu KPI
  int _page = 0;
  bool _loading = false;
  bool _analyzing = false;
  String? _error;

  Future<void> _analyzePlaystyles() async {
    setState(() => _analyzing = true);
    try {
      final message = await _service.analyzePlaystyles();
      if (mounted) showSuccessSnack(context, message);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    _items.clear();
    _page = 0;
    await _loadMore();
  }

  Future<void> _loadMore() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _service.getUsers(role: _role, status: _status, search: _searchController.text, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _lastPage = page;
        _page = page.page;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// action: 'unlock' | 'suspend' | 'ban' | 'role:<Role>'
  Future<void> _runAction(AdminUser u, String action) async {
    final (title, message, label) = switch (action) {
      'unlock' => ('Mở khóa tài khoản?', '${u.email} sẽ đăng nhập lại được ngay.', 'Mở khóa'),
      'suspend' => ('Tạm khóa $_suspendDays ngày?', '${u.email} bị đăng xuất ngay và không đăng nhập được trong $_suspendDays ngày.', 'Tạm khóa'),
      'ban' => ('Khóa vĩnh viễn?', '${u.email} bị đăng xuất ngay và không đăng nhập được nữa cho đến khi được mở khóa.', 'Khóa'),
      _ => ('Đổi vai trò?', '${u.email} sẽ thành ${action.substring(5)} và phải đăng nhập lại.', 'Đổi'),
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(label)),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      final updated = switch (action) {
        'unlock' => await _service.setUserStatus(u.id, AdminUser.active),
        'suspend' => await _service.setUserStatus(u.id, AdminUser.suspended, suspendDays: _suspendDays),
        'ban' => await _service.setUserStatus(u.id, AdminUser.banned),
        _ => await _service.setUserRole(u.id, action.substring(5)),
      };
      if (!mounted) return;
      setState(() {
        final index = _items.indexWhere((i) => i.id == u.id);
        if (index >= 0) _items[index] = updated;
      });
      showSuccessSnack(context, 'Đã cập nhật ${updated.email}.');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final myId = context.watch<AuthService>().currentUser?.id;
    final stats = _lastPage;
    final total = stats?.total ?? 0;

    return AdminPage(
      children: [
        ResponsiveGrid(
          minItemWidth: 200,
          children: [
            KpiCard(label: 'Thành viên', value: stats == null ? '-' : '${stats.totalUsers}', icon: Icons.people_outline, color: ThemeService.cyan),
            KpiCard(label: 'VIP đang dùng', value: stats == null ? '-' : '${stats.vipUsers}', icon: Icons.workspace_premium, color: ThemeService.yellow),
            KpiCard(label: 'Đang bị khóa', value: stats == null ? '-' : '${stats.lockedUsers}', icon: Icons.block, color: ThemeService.red),
          ],
        ),
        const SizedBox(height: AppSpace.md),

        // ── AI ghép đội: phân tích hồ sơ cũ (hồ sơ mới tự phân tích khi lưu) ──
        AdminPanel(
          title: 'AI ghép đội',
          subtitle: 'AI đọc phần tự viết để ghép người hợp gu. Hồ sơ mới tự phân tích khi lưu; bấm để phân tích hồ sơ cũ.',
          action: OutlinedButton.icon(
            onPressed: _analyzing ? null : _analyzePlaystyles,
            icon: _analyzing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Phân tích'),
          ),
          child: const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpace.md),

        // ── Bộ lọc ────────────────────────────────────────────
        AdminPanel(
          title: 'Bộ lọc',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _reload(),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên hoặc email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(tooltip: 'Tìm', icon: const Icon(Icons.arrow_forward), onPressed: _reload),
                ),
              ),
              for (final (filters, selected, onSelect) in [
                (_roleFilters, _role, (String? v) => _role = v),
                (_statusFilters, _status, (String? v) => _status = v),
              ]) ...[
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (final (value, label) in filters)
                      ChoiceChip(
                        label: Text(label),
                        selected: selected == value,
                        onSelected: (_) {
                          setState(() => onSelect(value));
                          _reload();
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),

        // ── Danh sách ─────────────────────────────────────────
        AdminPanel(
          title: '$total người dùng',
          action: IconButton(tooltip: 'Tải lại', icon: const Icon(Icons.refresh), onPressed: _loading ? null : _reload),
          padding: EdgeInsets.zero,
          child: _error != null
              ? Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Column(children: [Text(_error!, textAlign: TextAlign.center), TextButton(onPressed: _loadMore, child: const Text('Thử lại'))]),
                )
              : _items.isEmpty && _loading
                  ? const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator()))
                  : _items.isEmpty
                      ? Padding(padding: const EdgeInsets.all(AppSpace.xl), child: Text('Không có người dùng phù hợp.', textAlign: TextAlign.center, style: text.bodySmall))
                      : Column(
                          children: [
                            for (var i = 0; i < _items.length; i++) ...[
                              if (i > 0) Divider(height: 1, color: t.border),
                              _UserTile(user: _items[i], isMe: _items[i].id == myId, onAction: (a) => _runAction(_items[i], a)),
                            ],
                          ],
                        ),
        ),
        if (_items.length < total) ...[
          const SizedBox(height: AppSpace.md),
          Center(
            child: OutlinedButton(
              onPressed: _loading ? null : _loadMore,
              child: Text(_loading ? 'Đang tải...' : 'Tải thêm (${total - _items.length})'),
            ),
          ),
        ],
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final AdminUser user;
  final bool isMe;
  final ValueChanged<String> onAction;

  const _UserTile({required this.user, required this.isMe, required this.onAction});

  String get _statusLabel => switch (user.status) {
        AdminUser.banned => 'Khóa vĩnh viễn',
        AdminUser.deleted => 'Đã tự xóa tài khoản',
        AdminUser.suspended => user.suspendedUntil == null ? 'Tạm khóa' : 'Tạm khóa đến ${formatDateTime(user.suspendedUntil!)}',
        _ => 'Hoạt động',
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final u = user;
    return ListTile(
      leading: AppAvatar(imageUrl: u.avatarUrl, fallback: u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : '?', size: 40),
      title: Row(
        children: [
          Flexible(child: Text(isMe ? '${u.displayName} (bạn)' : u.displayName, style: text.titleSmall, overflow: TextOverflow.ellipsis)),
          if (u.isVip) ...[const SizedBox(width: AppSpace.xs), const Icon(Icons.workspace_premium, size: 16, color: ThemeService.yellow)],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(u.email, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              TagChip(u.role),
              TagChip(_statusLabel, color: u.isLocked ? ThemeService.red : ThemeService.green),
              TagChip('Lv.${u.level}'),
            ],
          ),
        ],
      ),
      isThreeLine: true,
      // Không tự khóa / đổi vai trò chính mình, không thao tác trên tài khoản đã xóa (backend cũng chặn)
      trailing: isMe || u.status == AdminUser.deleted
          ? null
          : PopupMenuButton<String>(
              tooltip: 'Thao tác',
              onSelected: onAction,
              itemBuilder: (_) => [
                if (u.isLocked)
                  const PopupMenuItem(value: 'unlock', child: Text('Mở khóa tài khoản'))
                else ...[
                  const PopupMenuItem(value: 'suspend', child: Text('Tạm khóa ${_AdminUsersPageState._suspendDays} ngày')),
                  const PopupMenuItem(value: 'ban', child: Text('Khóa vĩnh viễn')),
                ],
                const PopupMenuDivider(),
                for (final r in ['User', 'Staff', 'Admin'])
                  if (r != u.role) PopupMenuItem(value: 'role:$r', child: Text('Đặt vai trò $r')),
              ],
            ),
    );
  }
}
