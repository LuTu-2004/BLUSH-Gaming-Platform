import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';

// ============================================================
// KHỐI GIAO DIỆN DÙNG CHUNG CỦA TRANG QUẢN TRỊ
// ============================================================

/// Màn hình đủ rộng để hiện menu bên trái + bảng nhiều cột (máy tính, máy tính bảng ngang)
bool isWideAdmin(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

/// Khung nội dung 1 trang: cuộn được, lề rộng hơn trên máy tính, giới hạn bề ngang
class AdminPage extends StatelessWidget {
  final List<Widget> children;

  const AdminPage({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final pad = isWideAdmin(context) ? AppSpace.xl : AppSpace.lg;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, AppSpace.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

/// Khung có tiêu đề (+ nút bên phải) bọc 1 khối nội dung: biểu đồ, bảng...
class AdminPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AdminPanel({super.key, required this.title, this.subtitle, this.action, required this.child, this.padding = const EdgeInsets.all(AppSpace.lg)});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: t.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.sm, AppSpace.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleSmall),
                      if (subtitle != null) Text(subtitle!, style: text.bodySmall),
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
          Divider(height: 1, color: t.border),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Thẻ chỉ số (KPI): nhãn, con số lớn, dòng phụ, biểu tượng góc phải
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final Color color;
  final bool highlight;

  const KpiCard({super.key, required this.label, required this.value, this.caption, required this.icon, required this.color, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: highlight ? color.withValues(alpha: 0.6) : t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpace.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: text.headlineSmall?.copyWith(fontSize: highlight ? 28 : 22)),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(caption!, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Lưới tự chia cột theo bề ngang (mỗi ô tối thiểu [minItemWidth])
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  const ResponsiveGrid({super.key, required this.children, this.minItemWidth = 200, this.spacing = AppSpace.md});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = (constraints.maxWidth / minItemWidth).floor().clamp(1, children.length);
      final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final child in children) SizedBox(width: itemWidth, child: child)],
      );
    });
  }
}

/// 2 khối cạnh nhau trên màn rộng, xếp chồng trên màn hẹp
class SplitRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;

  const SplitRow({super.key, required this.left, required this.right, this.leftFlex = 1, this.rightFlex = 1});

  @override
  Widget build(BuildContext context) {
    if (!isWideAdmin(context)) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: AppSpace.md), right]);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(flex: leftFlex, child: left), const SizedBox(width: AppSpace.md), Expanded(flex: rightFlex, child: right)],
      ),
    );
  }
}

/// Nhãn "Dữ liệu mẫu" cho phần chưa nối backend
class SampleDataBadge extends StatelessWidget {
  const SampleDataBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
      decoration: BoxDecoration(color: ThemeService.yellow.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text('Dữ liệu mẫu', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).brightness == Brightness.dark ? ThemeService.yellow : const Color(0xFFB45309))),
    );
  }
}
