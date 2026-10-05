import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_model.dart';
import '../models/payment_model.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

/// Số tiền gọn cho trục / nhãn biểu đồ: 49000 -> "49K", 1250000 -> "1,3tr"
String compactVnd(int amount) {
  if (amount >= 1000000) {
    final m = amount / 1000000;
    return '${m >= 10 ? m.round() : m.toStringAsFixed(1).replaceAll('.', ',')}tr';
  }
  if (amount >= 1000) return '${(amount / 1000).round()}K';
  return '$amount';
}

/// "05/10"
String _dayMonth(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// Biểu đồ cột doanh thu theo ngày (1 chuỗi số liệu -> 1 màu, không cần chú thích).
/// Chạm vào cột để xem chi tiết ngày đó; nhãn số chỉ ghi ở cột cao nhất.
class DailyRevenueChart extends StatefulWidget {
  final List<DailyRevenue> daily;

  const DailyRevenueChart({super.key, required this.daily});

  @override
  State<DailyRevenueChart> createState() => _DailyRevenueChartState();
}

class _DailyRevenueChartState extends State<DailyRevenueChart> {
  static const _plotHeight = 150.0;
  int? _selected;

  @override
  void didUpdateWidget(DailyRevenueChart old) {
    super.didUpdateWidget(old);
    if (old.daily.length != widget.daily.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final daily = widget.daily;
    if (daily.isEmpty) return const SizedBox.shrink();

    final barColor = t.isDark ? ThemeService.accentLight : ThemeService.accent;
    final maxRevenue = daily.map((d) => d.revenue).reduce((a, b) => a > b ? a : b);
    final maxIndex = daily.indexWhere((d) => d.revenue == maxRevenue);
    final scaleMax = maxRevenue == 0 ? 1 : maxRevenue;
    final selected = _selected;
    final focus = daily[selected ?? daily.length - 1];

    return Semantics(
      label: 'Biểu đồ doanh thu ${daily.length} ngày, cao nhất ${formatVnd(maxRevenue)} ngày ${_dayMonth(daily[maxIndex].date)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng chi tiết: ngày đang chọn (mặc định hôm nay)
          Row(
            children: [
              Text(selected == null ? 'Hôm nay' : _dayMonth(focus.date), style: text.labelMedium),
              const Spacer(),
              Text(formatVnd(focus.revenue), style: text.titleSmall),
              Text(' · ${focus.count} giao dịch', style: text.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            height: _plotHeight + 16,
            child: Stack(
              children: [
                // Đường đáy (giá trị cao nhất đã ghi số trên cột nên không cần lưới)
                Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 1, color: t.border)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < daily.length; i++)
                      Expanded(
                        // Vùng chạm cao hết biểu đồ (to hơn cột) để dễ bấm
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _selected = _selected == i ? null : i),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Nhãn rộng hơn cột -> cho tràn ra 2 bên thay vì co chữ
                              if (i == maxIndex && maxRevenue > 0)
                                SizedBox(
                                  height: 14,
                                  child: OverflowBox(maxWidth: 80, child: Text(compactVnd(maxRevenue), style: text.labelSmall, softWrap: false)),
                                ),
                              const SizedBox(height: 2),
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 24),
                                  child: Container(
                                    // 2px khe giữa các cột, đầu cột bo 4px
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    height: daily[i].revenue == 0 ? 2 : (_plotHeight - 16) * daily[i].revenue / scaleMax,
                                    decoration: BoxDecoration(
                                      color: daily[i].revenue == 0
                                          ? t.border
                                          : barColor.withValues(alpha: selected == null || selected == i ? 1 : 0.35),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          // Nhãn trục ngang thưa: ngày đầu, giữa, cuối
          Row(
            children: [
              Text(_dayMonth(daily.first.date), style: text.labelSmall),
              const Spacer(),
              if (daily.length > 2) Text(_dayMonth(daily[daily.length ~/ 2].date), style: text.labelSmall),
              const Spacer(),
              Text(_dayMonth(daily.last.date), style: text.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tỉ trọng doanh thu theo nhóm: mỗi dòng ghi thẳng tên + số tiền + %, thanh ngang 1 màu
class RevenueBreakdownList extends StatelessWidget {
  final List<RevenueBreakdown> items;

  /// Biểu tượng đầu dòng (VD: logo phương thức thanh toán)
  final Widget Function(RevenueBreakdown item)? leading;

  const RevenueBreakdownList({super.key, required this.items, this.leading});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final total = items.fold<int>(0, (sum, i) => sum + i.revenue);
    final barColor = t.isDark ? ThemeService.accentLight : ThemeService.accent;

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.md),
          Row(
            children: [
              if (leading != null) ...[leading!(items[i]), const SizedBox(width: AppSpace.md)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(items[i].label, style: text.titleSmall, overflow: TextOverflow.ellipsis)),
                        Text(formatVnd(items[i].revenue), style: text.titleSmall),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : items[i].revenue / total,
                        minHeight: 6,
                        backgroundColor: t.cardHigh,
                        color: barColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${total == 0 ? 0 : (100 * items[i].revenue / total).round()}% · ${items[i].count} giao dịch',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
