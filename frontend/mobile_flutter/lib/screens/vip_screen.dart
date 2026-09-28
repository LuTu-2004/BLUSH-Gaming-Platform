import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'checkout_screen.dart';

/// Gói VIP (mở từ Hồ sơ hoặc banner ở Trang chủ).
class VipScreen extends StatelessWidget {
  const VipScreen({super.key});

  static const _plans = [
    _Plan(
      name: 'BLUSH Pass',
      price: '29.000đ',
      color: ThemeService.accent,
      perks: [
        'Khung avatar phát sáng',
        'Bong bóng chat độc quyền',
        'Ưu tiên ghép đội giờ cao điểm',
        'Hạn mức AI 50.000 tokens/tháng',
        '10 gợi ý AI phá băng mỗi ngày',
      ],
    ),
    _Plan(
      name: 'BLUSH Pass Pro',
      price: '49.000đ',
      color: ThemeService.green,
      popular: true,
      perks: [
        'Tất cả quyền lợi của BLUSH Pass',
        'Nhóm kín Pro-Player / Mentor',
        'Coaching chiến thuật 1-1',
        'Hạn mức AI 150.000 tokens/tháng',
        'Gợi ý AI mở đầu không giới hạn',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('BLUSH Pass')),
      body: PageBody(
        children: [
          Text('Nâng cấp trải nghiệm ghép đội', style: text.headlineSmall),
          const SizedBox(height: AppSpace.xs),
          Text('Giá sinh viên, thanh toán bằng VietQR, hủy bất cứ lúc nào.', style: text.bodySmall),
          const SizedBox(height: AppSpace.xl),
          for (final plan in _plans) ...[
            _PlanCard(plan: plan),
            const SizedBox(height: AppSpace.lg),
          ],
        ],
      ),
    );
  }
}

class _Plan {
  final String name;
  final String price;
  final Color color;
  final bool popular;
  final List<String> perks;

  const _Plan({required this.name, required this.price, required this.color, required this.perks, this.popular = false});
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    return AppCard(
      borderColor: plan.popular ? plan.color : null,
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(plan.name, style: text.titleLarge)),
              if (plan.popular) TagChip('Phổ biến nhất', color: plan.color),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text.rich(TextSpan(children: [
            TextSpan(text: plan.price, style: text.headlineSmall),
            TextSpan(text: ' / tháng', style: text.bodySmall),
          ])),
          const SizedBox(height: AppSpace.lg),
          for (final perk in plan.perks)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 18, color: plan.color),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(child: Text(perk, style: text.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            width: double.infinity,
            child: plan.popular
                ? ElevatedButton(onPressed: () => _checkout(context), child: const Text('Chọn gói này'))
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(side: BorderSide(color: t.border)),
                    onPressed: () => _checkout(context),
                    child: const Text('Chọn gói này'),
                  ),
          ),
        ],
      ),
    );
  }

  void _checkout(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(planName: plan.name, price: plan.price)));
  }
}
