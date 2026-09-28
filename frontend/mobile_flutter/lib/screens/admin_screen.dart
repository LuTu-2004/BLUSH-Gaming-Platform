import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Khu quản trị (Admin): thống kê, quản lý người dùng, mô phỏng chi phí (Chức năng 15, 16, 17).
/// TODO: số liệu thống kê & danh sách user lấy từ backend khi có API.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản trị'),
          bottom: const TabBar(tabs: [Tab(text: 'Thống kê'), Tab(text: 'Người dùng'), Tab(text: 'Chi phí')]),
        ),
        body: const TabBarView(children: [_AnalyticsTab(), _UsersTab(), _CostTab()]),
      ),
    );
  }
}

// ─────────────────────────── Thống kê ───────────────────────────

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  static const _months = ['T4', 'T5', 'T6', 'T7', 'T8', 'T9'];
  static const _newUsers = [120, 260, 410, 580, 820, 1240];
  static const _revenue = [0.6, 1.8, 3.2, 5.1, 7.9, 12.4]; // triệu VNĐ

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Text('Số liệu mẫu (chưa nối backend)', style: text.bodySmall),
        const SizedBox(height: AppSpace.md),
        const Row(
          children: [
            Expanded(child: StatTile(icon: Icons.people_outline, color: ThemeService.accent, value: '3.430', label: 'Người dùng')),
            SizedBox(width: AppSpace.sm),
            Expanded(child: StatTile(icon: Icons.workspace_premium, color: ThemeService.yellow, value: '412', label: 'VIP Pass đã bán')),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        const Row(
          children: [
            Expanded(child: StatTile(icon: Icons.groups_outlined, color: ThemeService.green, value: '1.876', label: 'Party đã lập')),
            SizedBox(width: AppSpace.sm),
            Expanded(child: StatTile(icon: Icons.forum_outlined, color: ThemeService.cyan, value: '640', label: 'Chat được AI cứu')),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        const SectionHeader('Người dùng mới theo tháng'),
        _BarChart(labels: _months, values: _newUsers.map((e) => e.toDouble()).toList(), color: ThemeService.accent, format: (v) => '${v.toInt()}'),
        const SizedBox(height: AppSpace.xl),
        const SectionHeader('Doanh thu VIP (triệu VNĐ)'),
        _BarChart(labels: _months, values: _revenue, color: ThemeService.green, format: (v) => v.toStringAsFixed(1)),
      ],
    );
  }
}

/// Biểu đồ cột đơn giản vẽ bằng Container (không cần thư viện ngoài)
class _BarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final Color color;
  final String Function(double) format;

  const _BarChart({required this.labels, required this.values, required this.color, required this.format});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return AppCard(
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(format(values[i]), style: text.labelSmall),
                      const SizedBox(height: AppSpace.xs),
                      Container(
                        height: 110 * values[i] / maxValue,
                        decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sm))),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(labels[i], style: text.labelSmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Người dùng ───────────────────────────

class _AdminUser {
  final String name;
  final String email;
  String role;
  bool isVip;
  bool banned;

  _AdminUser(this.name, this.email, this.role, {this.isVip = false, this.banned = false});
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
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
    final shown = _users.where((u) => u.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return PageBody(
      children: [
        Row(
          children: [
            Expanded(child: StatTile(icon: Icons.people_outline, color: ThemeService.accent, value: '${_users.length}', label: 'Thành viên')),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: StatTile(icon: Icons.workspace_premium, color: ThemeService.yellow, value: '${_users.where((u) => u.isVip).length}', label: 'VIP')),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: StatTile(icon: Icons.block, color: ThemeService.red, value: '${_users.where((u) => u.banned).length}', label: 'Bị khóa')),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(hintText: 'Tìm theo tên', prefixIcon: Icon(Icons.search)),
        ),
        const SizedBox(height: AppSpace.lg),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) Divider(height: 1, color: t.border),
                ListTile(
                  leading: AppAvatar(fallback: shown[i].name[0].toUpperCase(), size: 40),
                  title: Row(
                    children: [
                      Flexible(child: Text(shown[i].name, style: text.titleSmall, overflow: TextOverflow.ellipsis)),
                      if (shown[i].isVip) ...[const SizedBox(width: AppSpace.xs), const Icon(Icons.workspace_premium, size: 16, color: ThemeService.yellow)],
                    ],
                  ),
                  subtitle: Text('${shown[i].email} · ${shown[i].role}${shown[i].banned ? ' · Đã khóa' : ''}', style: text.bodySmall),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Thao tác',
                    onSelected: (action) => setState(() {
                      final u = shown[i];
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
                      PopupMenuItem(value: 'ban', child: Text(shown[i].banned ? 'Mở khóa tài khoản' : 'Khóa tài khoản')),
                      PopupMenuItem(value: 'vip', child: Text(shown[i].isVip ? 'Thu hồi VIP' : 'Cấp VIP thủ công')),
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

// ─────────────────────────── Chi phí ───────────────────────────

class _CostTab extends StatefulWidget {
  const _CostTab();

  @override
  State<_CostTab> createState() => _CostTabState();
}

class _CostTabState extends State<_CostTab> {
  // Số liệu theo tài liệu (Chức năng 17): AI ~52đ/user Free, ~393đ/user VIP mỗi tháng
  static const _aiCostFree = 52;
  static const _aiCostVip = 393;
  static const _vipPrice = 29000;
  static const _hosting = 500000; // Hosting + tên miền ước tính/tháng

  double _users = 5000;
  double _vipRate = 5; // %

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vipUsers = (_users * _vipRate / 100).round();
    final freeUsers = _users.round() - vipUsers;
    final aiCost = freeUsers * _aiCostFree + vipUsers * _aiCostVip;
    final totalCost = aiCost + _hosting;
    final revenue = vipUsers * _vipPrice;
    final profit = revenue - totalCost;

    return PageBody(
      children: [
        Text('Số người dùng: ${_vnd(_users.round())}', style: text.titleSmall),
        Slider(value: _users, min: 1000, max: 100000, divisions: 99, label: _vnd(_users.round()), onChanged: (v) => setState(() => _users = v)),
        Text('Tỷ lệ mua VIP: ${_vipRate.round()}%', style: text.titleSmall),
        Slider(value: _vipRate, min: 1, max: 20, divisions: 19, label: '${_vipRate.round()}%', onChanged: (v) => setState(() => _vipRate = v)),
        const SizedBox(height: AppSpace.lg),
        AppCard(
          child: Column(
            children: [
              _row(text, 'Chi phí AI / tháng', '${_vnd(aiCost)}đ'),
              _row(text, 'Hosting & tên miền / tháng', '${_vnd(_hosting)}đ'),
              _row(text, 'Tổng chi phí vận hành', '${_vnd(totalCost)}đ', bold: true),
              const Divider(height: AppSpace.xl),
              _row(text, 'Doanh thu VIP ($vipUsers × 29K)', '${_vnd(revenue)}đ'),
              _row(text, 'Lợi nhuận ước tính', '${_vnd(profit)}đ', bold: true, color: profit >= 0 ? ThemeService.green : ThemeService.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(TextTheme text, String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? text.titleSmall : text.bodyMedium)),
          Text(value, style: (bold ? text.titleSmall : text.bodyMedium)?.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// 1234567 -> "1.234.567" (dấu chấm ngăn cách hàng nghìn kiểu Việt Nam)
String _vnd(int n) {
  final s = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write('.');
    out.write(s[i]);
  }
  return out.toString();
}
