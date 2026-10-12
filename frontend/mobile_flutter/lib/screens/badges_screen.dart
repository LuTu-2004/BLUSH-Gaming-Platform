import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/payment_model.dart';
import '../services/auth_service.dart';
import '../services/badge_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Hồ sơ → Huy hiệu: đã nhận (có màu, ngày nhận) và chưa nhận (mờ, kèm điều kiện để nhận)
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  List<AppBadge>? _badges;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final badges = await BadgeService(context.read<AuthService>()).getMine();
      if (!mounted) return;
      setState(() {
        _badges = badges;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final badges = _badges;
    final earnedCount = badges?.where((b) => b.earned).length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Huy hiệu')),
      body: _error != null
          ? Center(child: TextButton(onPressed: _load, child: Text('$_error Chạm để thử lại.')))
          : badges == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: PageBody(
                    children: [
                      Text('Đã nhận $earnedCount/${badges.length} huy hiệu', style: text.titleMedium),
                      const SizedBox(height: AppSpace.md),
                      for (final b in badges) ...[
                        _BadgeTile(badge: b),
                        const SizedBox(height: AppSpace.sm),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final AppBadge badge;

  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final earnedAt = badge.earnedAt;
    return AppCard(
      borderColor: badge.earned ? ThemeService.yellow.withValues(alpha: 0.6) : null,
      child: Row(
        children: [
          // Chưa nhận: emoji mờ
          Opacity(opacity: badge.earned ? 1 : 0.3, child: Text(badge.icon, style: const TextStyle(fontSize: 32))),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.name, style: text.titleSmall?.copyWith(color: badge.earned ? null : t.textMuted)),
                if (badge.description != null) Text(badge.description!, style: text.bodySmall),
                if (earnedAt != null) Text('Nhận ngày ${formatDate(earnedAt)}', style: text.labelSmall?.copyWith(color: ThemeService.green)),
              ],
            ),
          ),
          if (!badge.earned) Icon(Icons.lock_outline, size: 18, color: t.textMuted),
        ],
      ),
    );
  }
}
