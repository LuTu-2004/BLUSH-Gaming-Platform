import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

/// Màn chào cho người chưa đăng nhập: ảnh game phủ cả màn, 3 trang lướt giới thiệu tính năng, 2 nút cố định dưới đáy.
/// Chỉ nói tính năng app đang có thật (test/honest_claims_test.dart kiểm tra).
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static const _slides = [
    (
      Icons.auto_awesome,
      'Ghép đội thông minh',
      'Tìm đồng đội hợp gu,\nkhông phải hợp ảnh',
      'Gợi ý theo game, rank, khung giờ, khu vực và phong cách chơi của bạn.',
    ),
    (
      Icons.ac_unit,
      'Phá băng & trợ lý AI',
      'Bắt chuyện\nkhông còn ngại',
      'Cùng trả lời câu hỏi tình huống game, AI gợi ý câu mở đầu khi cuộc trò chuyện chững lại.',
    ),
    (
      Icons.emoji_events_outlined,
      'Nhiệm vụ & xếp hạng',
      'Chơi cùng nhau,\ncùng lên level',
      'Làm nhiệm vụ mỗi ngày để nhận EXP, Coins và leo bảng xếp hạng theo tỉnh/thành.',
    ),
  ];

  static const _deepBlack = Color(0xFF08070C); // đáy màn: nền của chữ + 2 nút

  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openAuth({required bool isLogin}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AuthScreen(isLogin: isLogin)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _deepBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ảnh cao hơn màn 1 chút, đẩy lên trên để cắt dòng chữ in sẵn ở mép trên ảnh (đè lên logo)
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.18,
            left: 0,
            right: 0,
            bottom: 0,
            // Phóng nhẹ, neo đáy: mép trên càng ra xa khung nhìn ở mọi tỉ lệ màn hình
            child: Transform.scale(
              scale: 1.08,
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/images/hero_banner.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: ThemeService.accentContainer),
              ),
            ),
          ),
          // Trong suốt ở trên, đen đậm dần xuống dưới -> chữ và 2 nút tách hẳn khỏi chi tiết ảnh, ở cả 2 theme
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x0008070C), Color(0x3308070C), Color(0xD908070C), _deepBlack],
                stops: [0, 0.45, 0.72, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 36,
                        errorBuilder: (_, __, ___) => Text('BLUSH', style: text.titleLarge?.copyWith(color: Colors.white)),
                      ),
                      const Spacer(),
                      // Nền tròn tối riêng để icon không chìm vào vùng sáng của ảnh
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: IconButton(
                          tooltip: t.isDark ? 'Giao diện sáng' : 'Giao diện tối',
                          icon: Icon(t.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: Colors.white),
                          onPressed: t.toggleTheme,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 220,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) => _Slide(slide: _slides[i]),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  // Chấm trang: chấm đang xem dài hơn, bấm để nhảy tới trang đó
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        GestureDetector(
                          onTap: () => _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _page ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page ? ThemeService.accentLight : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: () => _openAuth(isLogin: false),
                    child: const Text('Bắt đầu miễn phí'),
                  ),
                  const SizedBox(height: 12),
                  // Nút phụ: viền mờ để dồn chú ý vào nút tím
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    onPressed: () => _openAuth(isLogin: true),
                    child: const Text('Tôi đã có tài khoản'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final (IconData, String, String, String) slide;

  const _Slide({required this.slide});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (icon, label, title, desc) = slide;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
          decoration: BoxDecoration(
            color: ThemeService.accent.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: ThemeService.accentLight.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: ThemeService.accentLight),
              const SizedBox(width: AppSpace.xs),
              Text(label, style: text.labelMedium?.copyWith(color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text(title, style: text.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.15)),
        const SizedBox(height: AppSpace.sm),
        Text(desc, style: text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }
}
