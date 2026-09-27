import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';

class VipScreen extends StatelessWidget {
  const VipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    return Scaffold(
      backgroundColor: theme.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Header with 3D Graphic Accent
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B2CBF), Color(0xFF140E28)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: ThemeService.yellow.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeService.blurple.withOpacity(0.2),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: ThemeService.yellow.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: ThemeService.yellow.withOpacity(0.4)),
                              ),
                              child: const Text('👑 ĐẶC QUYỀN HỘI VIÊN VIP', style: TextStyle(color: ThemeService.yellow, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'MỞ KHÓA TRẢI NGHIỆM GAMING ĐỈNH CAO',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Giá cực "Sinh Viên" — Chỉ từ 29K/tháng • Thanh toán quét VietQR siêu tốc',
                              style: TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (MediaQuery.of(context).size.width > 600) ...[
                        const SizedBox(width: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/esports_hub.png',
                            height: 120,
                            width: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Plan Cards Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 650;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Plan 29K Basic
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: _buildPlanCard(
                            context: context,
                            name: 'BLUSH Pass Basic',
                            price: '29K',
                            period: '/tháng',
                            isPopular: false,
                            color: ThemeService.blurple,
                            bullets: [
                              'Khung avatar động phát sáng Neon',
                              'Bong bóng chat độc quyền',
                              'Ưu tiên ghép đội giờ cao điểm',
                              'Hạn mức AI: 50.000 tokens/tháng',
                              '10 gợi ý AI phá băng / ngày',
                            ],
                            theme: theme,
                          ),
                        ),
                        if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),

                        // Plan 49K Pro
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: _buildPlanCard(
                            context: context,
                            name: 'BLUSH Pass Pro 🔥',
                            price: '49K',
                            period: '/tháng',
                            isPopular: true,
                            color: ThemeService.green,
                            bullets: [
                              'Tất cả quyền lợi từ gói 29K',
                              'Truy cập nhóm kín Pro-Player / Mentors',
                              'Esports Coaching chiến thuật 1-1',
                              'Hạn mức AI: 150.000 tokens/tháng',
                              'Trợ lý AI mở đầu không giới hạn',
                              'Ưu tiên ghép đội VIP Level cao nhất',
                            ],
                            theme: theme,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String name,
    required String price,
    required String period,
    required bool isPopular,
    required Color color,
    required List<String> bullets,
    required ThemeService theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: isPopular ? 2 : 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isPopular ? 0.15 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: const Text('🔥 PHỔ BIẾN NHẤT', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ),
          Text(name, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(price, style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: theme.textPrimary)),
              Text(period, style: TextStyle(color: theme.textMuted, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),

          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: color),
                    const SizedBox(width: 10),
                    Expanded(child: Text(b, style: TextStyle(fontSize: 13, color: theme.textPrimary))),
                  ],
                ),
              )),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutScreen(planName: name, price: price),
                ),
              );
            },
            child: const Text('CHỌN GÓI NÀY ➔', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
