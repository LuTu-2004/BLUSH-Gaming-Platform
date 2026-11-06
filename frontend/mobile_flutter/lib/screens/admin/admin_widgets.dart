import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
/// Không có [child] = khung chỉ có tiêu đề + nút (không vẽ đường kẻ, phần thân trống)
class AdminPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? child;
  final EdgeInsetsGeometry padding;

  const AdminPanel({super.key, required this.title, this.subtitle, this.action, this.child, this.padding = const EdgeInsets.all(AppSpace.lg)});

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
            // Cao cố định = nút bấm bên phải -> khung có nút / không nút có tiêu đề cao bằng nhau
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
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
          ),
          if (child != null) ...[
            Divider(height: 1, color: t.border),
            Padding(padding: padding, child: child),
          ],
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
                  child: Text(value, style: text.headlineSmall?.copyWith(fontSize: 24)),
                ),
                const SizedBox(height: 2),
                // Luôn giữ chỗ dòng phụ để các thẻ cùng hàng cao bằng nhau
                Text(caption ?? '', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    return _EqualHeightRow(flexes: [leftFlex, rightFlex], gap: AppSpace.md, children: [left, right]);
  }
}

/// Hàng 2 khối cao bằng nhau theo chiều cao THẬT của khối cao hơn.
/// Không dùng IntrinsicHeight: trên web, chiều cao ước lượng của chữ có lúc hụt vài px
/// so với lúc vẽ thật -> khối cao hơn bị tràn (vạch vàng đen).
/// Cách làm: đo từng khối với chiều cao tự nhiên, rồi đo lại cả hai với chiều cao lớn nhất.
class _EqualHeightRow extends MultiChildRenderObjectWidget {
  final List<int> flexes;
  final double gap;

  const _EqualHeightRow({required this.flexes, required this.gap, required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderEqualHeightRow(flexes, gap);

  @override
  void updateRenderObject(BuildContext context, _RenderEqualHeightRow renderObject) => renderObject
    ..flexes = flexes
    ..gap = gap;
}

class _EqualHeightParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderEqualHeightRow extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _EqualHeightParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _EqualHeightParentData> {
  _RenderEqualHeightRow(this._flexes, this._gap);

  List<int> _flexes;
  set flexes(List<int> v) {
    if (listEquals(v, _flexes)) return;
    _flexes = v;
    markNeedsLayout();
  }

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _EqualHeightParentData) child.parentData = _EqualHeightParentData();
  }

  /// Bề ngang từng khối theo tỉ lệ flex
  List<double> _widths(double width) {
    final total = _flexes.fold<int>(0, (a, b) => a + b);
    final usable = (width - _gap * (childCount - 1)).clamp(0.0, double.infinity);
    return [for (var i = 0; i < childCount; i++) usable * _flexes[i] / total];
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final widths = _widths(width);

    var height = 0.0;
    var child = firstChild;
    for (var i = 0; child != null; i++, child = childAfter(child)) {
      child.layout(BoxConstraints.tightFor(width: widths[i]), parentUsesSize: true);
      if (child.size.height > height) height = child.size.height;
    }

    var x = 0.0;
    child = firstChild;
    for (var i = 0; child != null; i++, child = childAfter(child)) {
      child.layout(BoxConstraints.tightFor(width: widths[i], height: height));
      (child.parentData! as _EqualHeightParentData).offset = Offset(x, 0);
      x += widths[i] + _gap;
    }
    size = constraints.constrain(Size(width, height));
  }

  double _maxChildHeight(double width, double Function(RenderBox child, double width) measure) {
    final widths = _widths(width);
    var height = 0.0;
    var child = firstChild;
    for (var i = 0; child != null; i++, child = childAfter(child)) {
      final h = measure(child, widths[i]);
      if (h > height) height = h;
    }
    return height;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _maxChildHeight(width, (c, w) => c.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) => _maxChildHeight(width, (c, w) => c.getMaxIntrinsicHeight(w));

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}
