import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/payment_model.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'checkout_screen.dart';
import 'payment_history_screen.dart';

/// Gói VIP (mở từ Hồ sơ hoặc banner ở Trang chủ). Danh sách gói lấy từ GET api/payment/packages.
class VipScreen extends StatefulWidget {
  const VipScreen({super.key});

  @override
  State<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends State<VipScreen> {
  // Quyền lợi theo gói (giao diện), giá + thời hạn lấy từ backend
  static const _basicPerks = [
    'Khung avatar phát sáng',
    'Bong bóng chat độc quyền',
    'Ưu tiên ghép đội giờ cao điểm',
    'Hạn mức AI 50.000 tokens/tháng',
    '10 gợi ý AI phá băng mỗi ngày',
  ];
  static const _proPerks = [
    'Tất cả quyền lợi của BLUSH Pass',
    'Nhóm kín Pro-Player / Mentor',
    'Coaching chiến thuật 1-1',
    'Hạn mức AI 150.000 tokens/tháng',
    'Gợi ý AI mở đầu không giới hạn',
  ];

  late final PaymentService _service = PaymentService(context.read<AuthService>());
  List<VipPackage>? _packages;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final packages = await _service.getPackages();
      if (mounted) setState(() => _packages = packages);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final text = Theme.of(context).textTheme;
    final packages = _packages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLUSH Pass'),
        actions: [
          IconButton(
            tooltip: 'Lịch sử thanh toán',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen())),
          ),
        ],
      ),
      body: PageBody(
        children: [
          if (user != null && user.isVip) ...[
            _CurrentPlanCard(packageName: user.vipPackageName ?? 'BLUSH Pass', expireAt: user.vipExpireAt),
            const SizedBox(height: AppSpace.xl),
          ],
          Text(user?.isVip == true ? 'Gia hạn hoặc nâng cấp' : 'Nâng cấp trải nghiệm ghép đội', style: text.headlineSmall),
          const SizedBox(height: AppSpace.xs),
          Text('Giá sinh viên. Thanh toán bằng ví MoMo hoặc chuyển khoản VietQR.', style: text.bodySmall),
          const SizedBox(height: AppSpace.xl),
          if (_error != null)
            AppCard(
              child: Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpace.md),
                  ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
          else if (packages == null)
            const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator()))
          else
            for (final package in packages) ...[
              _PlanCard(package: package, perks: package.code == 'month_basic' ? _basicPerks : _proPerks),
              const SizedBox(height: AppSpace.lg),
            ],
        ],
      ),
    );
  }
}

/// Gói đang dùng + ngày hết hạn
class _CurrentPlanCard extends StatelessWidget {
  final String packageName;
  final DateTime? expireAt;

  const _CurrentPlanCard({required this.packageName, required this.expireAt});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      borderColor: ThemeService.yellow.withValues(alpha: 0.6),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: ThemeService.yellow, size: 32),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bạn đang dùng $packageName', style: text.titleSmall),
                if (expireAt != null) Text('Hết hạn ngày ${formatDate(expireAt!)}', style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final VipPackage package;
  final List<String> perks;

  const _PlanCard({required this.package, required this.perks});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final highlighted = package.badge != null;
    final color = package.code == 'month_basic' ? ThemeService.accent : ThemeService.green;

    return AppCard(
      borderColor: highlighted ? color : null,
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(package.name, style: text.titleLarge)),
              if (package.badge != null) Flexible(child: TagChip(package.badge!, color: color)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text.rich(TextSpan(children: [
            TextSpan(text: formatVnd(package.price), style: text.headlineSmall),
            TextSpan(text: ' ${package.periodLabel}', style: text.bodySmall),
          ])),
          if (package.months > 1) Text('Chỉ ${formatVnd(package.monthlyPrice)} mỗi tháng', style: text.bodySmall?.copyWith(color: ThemeService.green)),
          const SizedBox(height: AppSpace.lg),
          for (final perk in perks)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 18, color: color),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(child: Text(perk, style: text.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            width: double.infinity,
            child: highlighted
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(package: package)));
  }
}
