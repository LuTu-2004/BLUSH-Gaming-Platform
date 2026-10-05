import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

// ============================================================
// CÁC KHỐI GIAO DIỆN DÙNG CHUNG
// Màn hình nào cũng dùng lại các widget này thay vì tự vẽ Container + BoxDecoration.
// ============================================================

/// Thẻ nền (card) chuẩn: nền, viền, bo góc, khoảng đệm thống nhất.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpace.lg), this.onTap, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    // Material + InkWell: có hiệu ứng gợn sóng khi bấm
    return Material(
      color: t.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: borderColor ?? t.border),
      ),
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Tiêu đề 1 mục trong trang: chữ thường (không IN HOA), có thể kèm nút bên phải.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Ô số liệu nhỏ: biểu tượng + con số + nhãn (Coins, EXP, Level...)
class StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const StatTile({super.key, required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: text.titleMedium)),
                Text(label, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nhãn nhỏ bo tròn (MBTI, tag sở thích, trạng thái...)
class TagChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const TagChip(this.label, {super.key, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final c = color ?? (t.isDark ? ThemeService.accentLight : ThemeService.accent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: c), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Ảnh đại diện: ảnh từ URL (Google) nếu có, không thì emoji / chữ cái đầu.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallback; // emoji hoặc chữ cái
  final double size;
  final Color? ringColor;

  const AppAvatar({super.key, this.imageUrl, required this.fallback, this.size = 40, this.ringColor});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final url = imageUrl;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringColor == null ? 0 : 2),
      decoration: BoxDecoration(shape: BoxShape.circle, border: ringColor == null ? null : Border.all(color: ringColor!, width: 2)),
      child: CircleAvatar(
        backgroundColor: t.cardHigh,
        foregroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
        child: Text(fallback, style: TextStyle(fontSize: size * 0.42, color: t.textPrimary, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Khung trang chuẩn: cuộn được, lề đều, giới hạn bề ngang trên máy tính bảng.
class PageBody extends StatelessWidget {
  final List<Widget> children;

  const PageBody({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpace.page,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

/// % hợp cạ: vòng tròn tiến độ nhỏ
class MatchBadge extends StatelessWidget {
  final int percent;
  final double size;

  const MatchBadge({super.key, required this.percent, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(child: CircularProgressIndicator(value: percent / 100, strokeWidth: 4, backgroundColor: t.cardHigh, color: ThemeService.green)),
          Text('$percent%', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.textPrimary)),
        ],
      ),
    );
  }
}
