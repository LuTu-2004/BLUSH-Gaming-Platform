import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';
import 'admin_widgets.dart';

/// Trang Người dùng.
/// TODO: vẫn là dữ liệu mẫu (thao tác chỉ đổi trên máy), chờ API quản lý người dùng ở backend.
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUser {
  final String name;
  final String email;
  String role;
  bool isVip;
  bool banned;

  _AdminUser(this.name, this.email, this.role, {this.isVip = false, this.banned = false});
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _users = [
    _AdminUser('Super Admin', 'admin@blush.vn', 'Admin', isVip: true),
    _AdminUser('Hùng Moderator', 'staff@blush.vn', 'Staff', isVip: true),
    _AdminUser('Lưu Phước Nhật Tú', 'gamer@blush.vn', 'User'),
    _AdminUser('ToxicGamer99', 'toxic@gmail.com', 'User', banned: true),
  ];
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final q = _query.toLowerCase();
    final shown = _users.where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();

    return AdminPage(
      children: [
        ResponsiveGrid(
          minItemWidth: 200,
          children: [
            KpiCard(label: 'Thành viên', value: '${_users.length}', icon: Icons.people_outline, color: ThemeService.cyan),
            KpiCard(label: 'VIP', value: '${_users.where((u) => u.isVip).length}', icon: Icons.workspace_premium, color: ThemeService.yellow),
            KpiCard(label: 'Bị khóa', value: '${_users.where((u) => u.banned).length}', icon: Icons.block, color: ThemeService.red),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        AdminPanel(
          title: 'Danh sách người dùng',
          action: const SampleDataBadge(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(hintText: 'Tìm theo tên hoặc email', prefixIcon: Icon(Icons.search)),
                ),
              ),
              for (final u in shown) ...[
                Divider(height: 1, color: t.border),
                ListTile(
                  leading: AppAvatar(fallback: u.name[0].toUpperCase(), size: 40),
                  title: Row(
                    children: [
                      Flexible(child: Text(u.name, style: text.titleSmall, overflow: TextOverflow.ellipsis)),
                      if (u.isVip) ...[const SizedBox(width: AppSpace.xs), const Icon(Icons.workspace_premium, size: 16, color: ThemeService.yellow)],
                    ],
                  ),
                  subtitle: Text('${u.email} · ${u.role}${u.banned ? ' · Đã khóa' : ''}', style: text.bodySmall),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Thao tác',
                    onSelected: (action) => setState(() {
                      switch (action) {
                        case 'ban':
                          u.banned = !u.banned;
                        case 'vip':
                          u.isVip = !u.isVip;
                        default:
                          u.role = action;
                      }
                    }),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'ban', child: Text(u.banned ? 'Mở khóa tài khoản' : 'Khóa tài khoản')),
                      PopupMenuItem(value: 'vip', child: Text(u.isVip ? 'Thu hồi VIP' : 'Cấp VIP thủ công')),
                      const PopupMenuDivider(),
                      for (final r in ['User', 'Staff', 'Admin']) PopupMenuItem(value: r, child: Text('Đặt vai trò $r')),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
