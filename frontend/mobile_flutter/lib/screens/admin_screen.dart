import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/admin_model.dart';
import '../models/payment_model.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/payment_widgets.dart';
import '../widgets/revenue_charts.dart';
import '../widgets/ui.dart';

/// Khu quản trị (Admin): doanh thu, giao dịch, quản lý người dùng, mô phỏng chi phí (Chức năng 15, 16, 17).
/// Tổng quan + Giao dịch lấy từ backend (api/admin/payments/*).
/// TODO: tab Người dùng vẫn là dữ liệu mẫu, chờ API quản lý người dùng.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản trị'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [Tab(text: 'Tổng quan'), Tab(text: 'Giao dịch'), Tab(text: 'Người dùng'), Tab(text: 'Chi phí')],
          ),
        ),
        body: const TabBarView(children: [_OverviewTab(), _TransactionsTab(), _UsersTab(), _CostTab()]),
      ),
    );
  }
}

// ─────────────────────────── Tổng quan (doanh thu) ───────────────────────────

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> with AutomaticKeepAliveClientMixin {
  late final AdminService _service = AdminService(context.read<AuthService>());
  int _days = 30;
  PaymentSummary? _summary;
  String? _error;

  @override
  bool get wantKeepAlive => true; // đổi tab không phải tải lại

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final summary = await _service.getPaymentSummary(days: _days);
      if (mounted) setState(() => _summary = summary);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final accent = t.isDark ? ThemeService.accentLight : ThemeService.accent;
    final s = _summary;

    return PageBody(
      children: [
        // Bộ lọc khoảng thời gian: 1 hàng phía trên các biểu đồ
        Row(
          children: [
            Expanded(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 ngày')),
                  ButtonSegment(value: 30, label: Text('30 ngày')),
                ],
                selected: {_days},
                showSelectedIcon: false,
                onSelectionChanged: (v) {
                  setState(() => _days = v.first);
                  _load();
                },
              ),
            ),
            IconButton(tooltip: 'Tải lại', icon: const Icon(Icons.refresh), onPressed: _load),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        if (_error != null)
          AppCard(onTap: _load, child: Text('$_error Chạm để thử lại.', textAlign: TextAlign.center, style: text.bodySmall))
        else if (s == null)
          const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator()))
        else ...[
          // ── Số chính: doanh thu trong kỳ + biểu đồ theo ngày ─────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doanh thu $_days ngày', style: text.labelMedium),
                const SizedBox(height: AppSpace.xs),
                Text(formatVnd(s.revenueInRange), style: text.headlineSmall?.copyWith(fontSize: 30)),
                const SizedBox(height: AppSpace.xs),
                Text('${s.paidCount} giao dịch thành công / ${s.transactionCount} giao dịch', style: text.bodySmall),
                const SizedBox(height: AppSpace.lg),
                DailyRevenueChart(daily: s.daily),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(child: StatTile(icon: Icons.today_outlined, color: ThemeService.green, value: compactVnd(s.revenueToday), label: 'Hôm nay')),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: StatTile(icon: Icons.calendar_month_outlined, color: ThemeService.green, value: compactVnd(s.revenueThisMonth), label: 'Tháng này')),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.verified_outlined,
                  color: accent,
                  value: s.successRate == null ? '—' : '${s.successRate!.round()}%',
                  label: 'Tỉ lệ thành công',
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: StatTile(icon: Icons.workspace_premium, color: ThemeService.yellow, value: '${s.activeVipCount}', label: 'VIP đang dùng')),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(child: StatTile(icon: Icons.people_outline, color: accent, value: '${s.totalUsers}', label: 'Gamer')),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: StatTile(icon: Icons.person_add_alt, color: ThemeService.cyan, value: '+${s.newUsersInRange}', label: 'Mới $_days ngày')),
            ],
          ),
          if (s.pendingCount > 0) ...[
            const SizedBox(height: AppSpace.sm),
            AppCard(
              borderColor: ThemeService.yellow.withValues(alpha: 0.6),
              padding: const EdgeInsets.all(AppSpace.md),
              onTap: () => DefaultTabController.of(context).animateTo(1),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top, color: ThemeService.yellow),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(child: Text('${s.pendingCount} giao dịch đang chờ thanh toán', style: text.bodyMedium)),
                  Icon(Icons.chevron_right, color: t.textMuted),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.xl),
          const SectionHeader('Theo phương thức thanh toán'),
          AppCard(
            child: s.byMethod.isEmpty
                ? Text('Chưa có giao dịch thành công.', style: text.bodySmall, textAlign: TextAlign.center)
                : RevenueBreakdownList(items: s.byMethod, leading: (item) => PaymentMethodBadge(method: item.key, size: 36)),
          ),
          const SizedBox(height: AppSpace.xl),
          const SectionHeader('Theo gói'),
          AppCard(
            child: s.byPackage.isEmpty
                ? Text('Chưa có giao dịch thành công.', style: text.bodySmall, textAlign: TextAlign.center)
                : RevenueBreakdownList(items: s.byPackage),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────── Giao dịch ───────────────────────────

class _TransactionsTab extends StatefulWidget {
  const _TransactionsTab();

  @override
  State<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<_TransactionsTab> with AutomaticKeepAliveClientMixin {
  static const _statusFilters = [
    (null, 'Tất cả'),
    ('Pending', 'Đang chờ'),
    ('Paid', 'Thành công'),
    ('Failed', 'Thất bại'),
    ('Cancelled', 'Đã hủy'),
  ];
  static const _methodFilters = [
    (null, 'Mọi phương thức'),
    ('MoMo', 'MoMo'),
    ('VNPay', 'VNPay'),
    ('ZaloPay', 'ZaloPay'),
    ('VietQR', 'VietQR'),
  ];

  late final AdminService _service = AdminService(context.read<AuthService>());
  final _searchController = TextEditingController();
  String? _status;
  String? _method;
  final List<AdminTransaction> _items = [];
  int _total = 0;
  int _page = 0;
  bool _loading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

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
      final page = await _service.getTransactions(status: _status, method: _method, search: _searchController.text, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _total = page.total;
        _page = page.page;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm(AdminTransaction tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã nhận tiền?'),
        content: Text(
          'Chỉ xác nhận khi sao kê ngân hàng đã có khoản ${formatVnd(tx.amount)} với nội dung "BLUSH ${tx.orderCode}". '
          'Gói ${tx.packageName} sẽ được kích hoạt cho ${tx.userEmail}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để sau')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final updated = await _service.confirmBankTransfer(tx.orderCode);
      if (!mounted) return;
      setState(() {
        final index = _items.indexWhere((i) => i.orderCode == tx.orderCode);
        if (index >= 0) _items[index] = updated;
      });
      showSuccessSnack(context, 'Đã kích hoạt ${updated.packageName} cho ${updated.userEmail}.');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    }
  }

  Widget _chipRow<T>(List<(T?, String)> options, T? selected, ValueChanged<T?> onSelected) => SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final (value, label) in options) ...[
              ChoiceChip(label: Text(label), selected: selected == value, onSelected: (_) => onSelected(value)),
              const SizedBox(width: AppSpace.sm),
            ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;

    return PageBody(
      children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _reload(),
          decoration: InputDecoration(
            hintText: 'Tìm email, tên hoặc mã đơn',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(tooltip: 'Tìm', icon: const Icon(Icons.arrow_forward), onPressed: _reload),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        _chipRow<String>(_statusFilters, _status, (v) {
          setState(() => _status = v);
          _reload();
        }),
        const SizedBox(height: AppSpace.sm),
        _chipRow<String>(_methodFilters, _method, (v) {
          setState(() => _method = v);
          _reload();
        }),
        const SizedBox(height: AppSpace.md),
        Text('$_total giao dịch', style: text.labelMedium),
        const SizedBox(height: AppSpace.sm),
        if (_error != null)
          AppCard(onTap: _loadMore, child: Text('$_error Chạm để thử lại.', textAlign: TextAlign.center, style: text.bodySmall))
        else if (_items.isEmpty && _loading)
          const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator()))
        else if (_items.isEmpty)
          AppCard(child: Text('Không có giao dịch phù hợp.', textAlign: TextAlign.center, style: text.bodySmall))
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < _items.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: t.border),
                  _AdminTransactionTile(transaction: _items[i], onConfirm: () => _confirm(_items[i])),
                ],
              ],
            ),
          ),
        if (_items.length < _total) ...[
          const SizedBox(height: AppSpace.md),
          OutlinedButton(
            onPressed: _loading ? null : _loadMore,
            child: Text(_loading ? 'Đang tải...' : 'Tải thêm (${_total - _items.length})'),
          ),
        ],
      ],
    );
  }
}

class _AdminTransactionTile extends StatelessWidget {
  final AdminTransaction transaction;
  final VoidCallback onConfirm;

  const _AdminTransactionTile({required this.transaction, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tx = transaction;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PaymentMethodBadge(method: tx.method, size: 36),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.userDisplayName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(tx.userEmail, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      [tx.packageName, '#${tx.orderCode}', if (tx.createdAt != null) formatDateTime(tx.createdAt!)].join(' · '),
                      style: text.bodySmall,
                    ),
                    if (tx.failureReason != null) Text(tx.failureReason!, style: text.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatVnd(tx.amount), style: text.titleSmall),
                  const SizedBox(height: 2),
                  TransactionStatusChip(tx.status),
                ],
              ),
            ],
          ),
          if (tx.canConfirmManually) ...[
            const SizedBox(height: AppSpace.sm),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
                onPressed: onConfirm,
                icon: const Icon(Icons.task_alt, size: 18),
                label: const Text('Xác nhận đã nhận tiền'),
              ),
            ),
          ],
        ],
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
