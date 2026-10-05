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
import '../../widgets/payment_widgets.dart';
import 'admin_widgets.dart';

/// Trang Giao dịch: tìm kiếm, lọc, bảng giao dịch, xác nhận chuyển khoản VietQR thủ công.
class AdminTransactionsPage extends StatefulWidget {
  const AdminTransactionsPage({super.key});

  @override
  State<AdminTransactionsPage> createState() => _AdminTransactionsPageState();
}

class _AdminTransactionsPageState extends State<AdminTransactionsPage> {
  static const _statusFilters = [
    (null, 'Tất cả'),
    ('Pending', 'Đang chờ'),
    ('Paid', 'Thành công'),
    ('Failed', 'Thất bại'),
    ('Cancelled', 'Đã hủy'),
  ];
  static const _methodFilters = [(null, 'Mọi phương thức'), ('MoMo', 'MoMo'), ('VietQR', 'VietQR')];

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
          'Chỉ xác nhận khi sao kê ngân hàng đã có khoản ${formatVnd(tx.amount)} cho đơn #${tx.orderCode}. '
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

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final wide = isWideAdmin(context);

    return AdminPage(
      children: [
        // ── Bộ lọc ────────────────────────────────────────────
        AdminPanel(
          title: 'Bộ lọc',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: wide ? 360 : double.infinity,
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _reload(),
                      decoration: InputDecoration(
                        hintText: 'Tìm email, tên hoặc mã đơn',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(tooltip: 'Tìm', icon: const Icon(Icons.arrow_forward), onPressed: _reload),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.sm,
                    children: [
                      for (final (value, label) in _methodFilters)
                        ChoiceChip(
                          label: Text(label),
                          selected: _method == value,
                          onSelected: (_) {
                            setState(() => _method = value);
                            _reload();
                          },
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final (value, label) in _statusFilters)
                    ChoiceChip(
                      label: Text(label),
                      selected: _status == value,
                      onSelected: (_) {
                        setState(() => _status = value);
                        _reload();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),

        // ── Danh sách ─────────────────────────────────────────
        AdminPanel(
          title: '$_total giao dịch',
          subtitle: _items.isEmpty ? null : 'Đang hiện ${_items.length} giao dịch mới nhất',
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
                      ? Padding(padding: const EdgeInsets.all(AppSpace.xl), child: Text('Không có giao dịch phù hợp.', textAlign: TextAlign.center, style: text.bodySmall))
                      : wide
                          ? _TransactionTable(items: _items, onConfirm: _confirm)
                          : Column(
                              children: [
                                for (var i = 0; i < _items.length; i++) ...[
                                  if (i > 0) Divider(height: 1, color: t.border),
                                  _TransactionTile(tx: _items[i], onConfirm: () => _confirm(_items[i])),
                                ],
                              ],
                            ),
        ),
        if (_items.length < _total) ...[
          const SizedBox(height: AppSpace.md),
          Center(
            child: OutlinedButton(
              onPressed: _loading ? null : _loadMore,
              child: Text(_loading ? 'Đang tải...' : 'Tải thêm (${_total - _items.length})'),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Bảng nhiều cột (màn rộng) ───────────────────────────────────────
class _TransactionTable extends StatelessWidget {
  final List<AdminTransaction> items;
  final ValueChanged<AdminTransaction> onConfirm;

  const _TransactionTable({required this.items, required this.onConfirm});

  // Tỉ lệ chiều rộng các cột
  static const _flex = [3, 4, 3, 3, 2, 2, 3, 3];
  static const _headers = ['Mã đơn', 'Người dùng', 'Gói', 'Phương thức', 'Số tiền', 'Trạng thái', 'Thời gian', ''];

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;

    Widget cell(int col, Widget child, {Alignment align = Alignment.centerLeft}) =>
        Expanded(flex: _flex[col], child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm), child: Align(alignment: align, child: child)));

    return Column(
      children: [
        // Hàng tiêu đề
        Container(
          color: t.cardHigh.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.md),
          child: Row(
            children: [
              for (var c = 0; c < _headers.length; c++)
                cell(c, Text(_headers[c], style: text.labelMedium), align: c == 4 ? Alignment.centerRight : Alignment.centerLeft),
            ],
          ),
        ),
        for (var i = 0; i < items.length; i++) ...[
          Divider(height: 1, color: t.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.md),
            child: Row(
              children: [
                cell(0, SelectableText('#${items[i].orderCode}', maxLines: 1, style: text.bodySmall?.copyWith(color: t.textPrimary))),
                cell(
                  1,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i].userDisplayName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(items[i].userEmail, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                cell(2, Text(items[i].packageName, style: text.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis)),
                cell(
                  3,
                  Row(
                    children: [
                      PaymentMethodBadge(method: items[i].method, size: 28),
                      const SizedBox(width: AppSpace.sm),
                      Flexible(child: Text(items[i].method.startsWith('VietQR') ? 'VietQR' : items[i].method, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                cell(4, Text(formatVnd(items[i].amount), style: text.titleSmall), align: Alignment.centerRight),
                cell(5, TransactionStatusChip(items[i].status)),
                cell(
                  6,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i].createdAt != null ? formatDateTime(items[i].createdAt!) : '—', style: text.bodySmall),
                      if (items[i].failureReason != null) Text(items[i].failureReason!, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                cell(
                  7,
                  items[i].canConfirmManually
                      ? OutlinedButton(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: AppSpace.md)),
                          onPressed: () => onConfirm(items[i]),
                          child: const Text('Xác nhận đã nhận tiền', overflow: TextOverflow.ellipsis),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Dạng danh sách (màn hẹp) ────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final AdminTransaction tx;
  final VoidCallback onConfirm;

  const _TransactionTile({required this.tx, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                    Text([tx.packageName, '#${tx.orderCode}', if (tx.createdAt != null) formatDateTime(tx.createdAt!)].join(' · '), style: text.bodySmall),
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
