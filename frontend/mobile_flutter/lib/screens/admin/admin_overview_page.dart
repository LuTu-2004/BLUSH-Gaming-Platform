import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../models/admin_model.dart';
import '../../models/payment_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/payment_widgets.dart';
import '../../widgets/revenue_charts.dart';
import 'admin_ratings_page.dart';
import 'admin_widgets.dart';

/// Trang Tổng quan: chỉ số chính, doanh thu theo ngày, tỉ trọng, giao dịch gần đây.
/// Dữ liệu: GET api/admin/payments/summary + api/admin/payments/transactions + api/admin/ratings (số liệu đánh giá)
///          + api/admin/acquisition (nguồn người dùng)
class AdminOverviewPage extends StatefulWidget {
  /// Chuyển sang trang khác trong khu quản trị (1 = Giao dịch, 3 = Lịch sử đánh giá)
  final ValueChanged<int> onNavigate;

  const AdminOverviewPage({super.key, required this.onNavigate});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  static const _recentCount = 6;

  late final AdminService _service = AdminService(context.read<AuthService>());
  int _days = 30;
  PaymentSummary? _summary;
  AdminRatingPage? _ratings; // null = không tải được, phần còn lại của trang vẫn hiện
  AcquisitionStats? _acquisition; // như trên
  List<AdminTransaction> _recent = [];
  DateTime? _updatedAt;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final ratings = _service.getRatings(pageSize: 3).then<AdminRatingPage?>((p) => p, onError: (_) => null);
      final acquisition = _service.getAcquisition().then<AcquisitionStats?>((a) => a, onError: (_) => null);
      final results = await Future.wait([_service.getPaymentSummary(days: _days), _service.getTransactions(), ratings, acquisition]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as PaymentSummary;
        _recent = (results[1] as AdminTransactionPage).items.take(_recentCount).toList();
        _ratings = results[2] as AdminRatingPage?;
        _acquisition = results[3] as AcquisitionStats?;
        _updatedAt = DateTime.now();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final accent = t.isDark ? ThemeService.accentLight : ThemeService.accent;
    final s = _summary;
    // Ngày cuối trong daily là hôm nay (backend trả đủ mọi ngày trong khoảng)
    final todayCount = s == null || s.daily.isEmpty ? 0 : s.daily.last.count;

    return AdminPage(
      children: [
        // ── Bộ lọc thời gian: 1 hàng phía trên mọi số liệu ──────────
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<int>(
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
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Làm mới'),
            ),
            if (_updatedAt != null)
              Text('Cập nhật lúc ${_updatedAt!.hour.toString().padLeft(2, '0')}:${_updatedAt!.minute.toString().padLeft(2, '0')}', style: text.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpace.lg),

        if (_error != null)
          AdminPanel(
            title: 'Không tải được số liệu',
            action: TextButton(onPressed: _load, child: const Text('Thử lại')),
            child: Text(_error!, style: text.bodyMedium),
          )
        else if (s == null)
          const Padding(padding: EdgeInsets.all(AppSpace.xxl), child: Center(child: CircularProgressIndicator()))
        else ...[
          // ── Chỉ số chính: 3 nhóm, mỗi nhóm 3 thẻ ───────────────────
          // 3 cột trên máy tính, 2 cột trên máy tính bảng, 1 cột trên điện thoại
          const _GroupLabel('DOANH THU'),
          ResponsiveGrid(
            minItemWidth: 300,
            children: [
              KpiCard(
                label: 'Doanh thu $_days ngày',
                value: formatVnd(s.revenueInRange),
                caption: 'Từ ${s.paidCount} giao dịch thành công',
                icon: Icons.payments_outlined,
                color: ThemeService.green,
                highlight: true,
              ),
              KpiCard(label: 'Hôm nay', value: formatVnd(s.revenueToday), caption: '$todayCount giao dịch thành công', icon: Icons.today_outlined, color: ThemeService.green),
              KpiCard(label: 'Tháng này', value: formatVnd(s.revenueThisMonth), caption: 'Từ ngày 01/${DateTime.now().month.toString().padLeft(2, '0')}', icon: Icons.calendar_month_outlined, color: ThemeService.green),
            ],
          ),
          const _GroupLabel('NGƯỜI DÙNG'),
          ResponsiveGrid(
            minItemWidth: 300,
            children: [
              KpiCard(label: 'Tổng gamer', value: '${s.totalUsers}', caption: 'Không tính tài khoản Staff / Admin', icon: Icons.people_outline, color: ThemeService.cyan),
              KpiCard(label: 'Gamer mới', value: '+${s.newUsersInRange}', caption: 'Đăng ký trong $_days ngày', icon: Icons.person_add_alt, color: ThemeService.cyan),
              KpiCard(label: 'VIP đang dùng', value: '${s.activeVipCount}', caption: 'Gói VIP còn hạn', icon: Icons.workspace_premium, color: ThemeService.yellow),
            ],
          ),
          const _GroupLabel('GIAO DỊCH'),
          ResponsiveGrid(
            minItemWidth: 300,
            children: [
              KpiCard(
                label: 'Giao dịch thành công',
                value: '${s.paidCount}',
                caption: 'Trên ${s.transactionCount} giao dịch trong $_days ngày',
                icon: Icons.check_circle_outline,
                color: ThemeService.green,
              ),
              KpiCard(
                label: 'Tỉ lệ thanh toán thành công',
                value: s.successRate == null ? '—' : '${s.successRate!.round()}%',
                caption: 'Trên các giao dịch đã kết thúc',
                icon: Icons.verified_outlined,
                color: accent,
              ),
              KpiCard(label: 'Đang chờ thanh toán', value: '${s.pendingCount}', caption: 'Đã tạo đơn, chưa trả tiền', icon: Icons.hourglass_top, color: ThemeService.yellow),
            ],
          ),

          if (s.pendingCount > 0) ...[
            const SizedBox(height: AppSpace.md),
            Material(
              color: ThemeService.yellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => widget.onNavigate(1),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.md),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top, color: ThemeService.yellow),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(child: Text('${s.pendingCount} giao dịch đang chờ thanh toán', style: text.bodyMedium)),
                      Text('Xem', style: text.labelLarge?.copyWith(color: accent)),
                      Icon(Icons.chevron_right, color: accent),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),

          // ── Biểu đồ (trái) + tỉ trọng theo phương thức / gói xếp chồng (phải) ──
          SplitRow(
            leftFlex: 3,
            rightFlex: 2,
            left: AdminPanel(
              title: 'Doanh thu theo ngày',
              subtitle: 'Chạm vào cột để xem chi tiết ngày đó',
              child: DailyRevenueChart(daily: s.daily),
            ),
            right: _StackedPanels(
              top: AdminPanel(
                title: 'Theo phương thức thanh toán',
                child: s.byMethod.isEmpty
                    ? Text('Chưa có giao dịch thành công.', style: text.bodySmall, textAlign: TextAlign.center)
                    : RevenueBreakdownList(items: s.byMethod, leading: (item) => PaymentMethodBadge(method: item.key, size: 36)),
              ),
              bottom: AdminPanel(
                title: 'Theo gói',
                child: s.byPackage.isEmpty
                    ? Text('Chưa có giao dịch thành công.', style: text.bodySmall, textAlign: TextAlign.center)
                    : RevenueBreakdownList(items: s.byPackage),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // ── Nguồn người dùng (trái) + điểm đánh giá app (phải) ───────
          SplitRow(
            left: AdminPanel(
              title: 'Nguồn người dùng',
              subtitle: 'Gamer biết BLUSH qua đâu',
              child: _acquisition == null
                  ? Text('Không tải được số liệu nguồn người dùng.', style: text.bodySmall, textAlign: TextAlign.center)
                  : _AcquisitionList(stats: _acquisition!),
            ),
            right: AdminPanel(
              title: 'Đánh giá từ người dùng',
              action: TextButton(onPressed: () => widget.onNavigate(3), child: const Text('Xem lịch sử')),
              child: _ratings == null
                  ? Text('Không tải được số liệu đánh giá.', style: text.bodySmall, textAlign: TextAlign.center)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RatingSummary(stats: _ratings!.stats),
                        // 3 đánh giá mới nhất: cao gần bằng khung Nguồn người dùng bên cạnh
                        for (final r in _ratings!.items) ...[
                          const SizedBox(height: AppSpace.md),
                          Divider(height: 1, color: t.border),
                          const SizedBox(height: AppSpace.md),
                          Row(
                            children: [
                              Expanded(child: Text(r.displayName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                              StarRow(value: r.stars.toDouble(), size: 14),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(r.comment ?? 'Không để lại góp ý', style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // ── Giao dịch gần đây: hết bề ngang ──────────────────────
          AdminPanel(
            title: 'Giao dịch gần đây',
            action: TextButton(onPressed: () => widget.onNavigate(1), child: const Text('Xem tất cả')),
            padding: EdgeInsets.zero,
            child: _recent.isEmpty
                ? Padding(padding: const EdgeInsets.all(AppSpace.lg), child: Text('Chưa có giao dịch.', style: text.bodySmall, textAlign: TextAlign.center))
                : Column(
                    children: [
                      for (var i = 0; i < _recent.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: t.border),
                        _RecentRow(tx: _recent[i]),
                      ],
                    ],
                  ),
          ),
        ],
      ],
    );
  }
}

/// 2 khung xếp chồng, chia đều chiều cao của hàng (màn rộng) để không hụt khoảng trống
class _StackedPanels extends StatelessWidget {
  final Widget top;
  final Widget bottom;

  const _StackedPanels({required this.top, required this.bottom});

  @override
  Widget build(BuildContext context) {
    if (!isWideAdmin(context)) return Column(children: [top, const SizedBox(height: AppSpace.md), bottom]);
    return Column(children: [Expanded(child: top), const SizedBox(height: AppSpace.md), Expanded(child: bottom)]);
  }
}

/// Mỗi nguồn 1 thanh: tên, độ dài theo số người, số người + % trên số đã trả lời
class _AcquisitionList extends StatelessWidget {
  final AcquisitionStats stats;

  const _AcquisitionList({required this.stats});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final maxCount = stats.sources.fold<int>(0, (a, s) => s.count > a ? s.count : a);
    final answeredPercent = stats.totalUsers == 0 ? 0 : (stats.answered * 100 / stats.totalUsers).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${stats.answered}/${stats.totalUsers} gamer đã trả lời ($answeredPercent%)', style: text.bodySmall),
        const SizedBox(height: AppSpace.md),
        for (final s in stats.sources)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                SizedBox(width: 130, child: Text(s.label, style: text.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: maxCount == 0 ? 0 : s.count / maxCount,
                      minHeight: 8,
                      backgroundColor: t.cardHigh,
                      color: ThemeService.cyan,
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    stats.answered == 0 ? '${s.count}' : '${s.count} · ${(s.count * 100 / stats.answered).round()}%',
                    style: text.labelMedium,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpace.md),
        Text('% tính trên số gamer đã trả lời. App hỏi 1 lần sau khảo sát, người dùng có thể bỏ qua.', style: text.bodySmall?.copyWith(color: t.textMuted)),
      ],
    );
  }
}

/// Nhãn nhỏ phía trên mỗi nhóm thẻ chỉ số
class _GroupLabel extends StatelessWidget {
  final String label;

  const _GroupLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.md, 0, AppSpace.sm),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1)),
      );
}

class _RecentRow extends StatelessWidget {
  final AdminTransaction tx;

  const _RecentRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
      child: Row(
        children: [
          PaymentMethodBadge(method: tx.method, size: 32),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.userDisplayName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  [tx.packageName, if (tx.createdAt != null) formatDateTime(tx.createdAt!)].join(' · '),
                  style: text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
    );
  }
}
