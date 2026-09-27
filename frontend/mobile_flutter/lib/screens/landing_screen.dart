import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import 'auth_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    const pinkPrimary = Color(0xFFFFB1C5);
    const pinkAccent = Color(0xFFEB459E);
    const cyanSecondary = Color(0xFF00EEFC);
    final accentText = theme.isDark ? pinkPrimary : pinkAccent;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Header Navbar
              Container(
                color: theme.header,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo & Brand
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              height: 38,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Row(
                                children: [
                                  Icon(Icons.sports_esports, color: accentText, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'BLUSH',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: accentText,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.cardHigh,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: theme.border),
                              ),
                              child: Text(
                                'Matchmaking Radar',
                                style: TextStyle(color: theme.isDark ? cyanSecondary : ThemeService.accent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),

                        // Header Actions
                        Row(
                          children: [
                            IconButton(
                              tooltip: theme.isDark ? 'Chế độ Sáng ☀️' : 'Chế độ Tối 🌙',
                              icon: Icon(
                                theme.isDark ? Icons.wb_sunny : Icons.nightlight_round,
                                color: theme.isDark ? Colors.amber : ThemeService.accent,
                              ),
                              onPressed: () {
                                context.read<ThemeService>().toggleTheme();
                              },
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ThemeService.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 2,
                              ),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(isLogin: true)));
                              },
                              child: const Text('Đăng Nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main Body Content
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Live Hot Badge
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.cardHigh,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: pinkAccent.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: accentText, size: 8),
                                const SizedBox(width: 6),
                                Text(
                                  '🔥 GHÉP ĐỘI AI SỐ 1 CHO SINH VIÊN VN',
                                  style: TextStyle(color: accentText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Hero Titles
                        Text(
                          'TÌM BẠN CHIẾN GAME\nCHUẨN GU & PHONG CÁCH',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            color: theme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Kết nối game thủ bằng phong cách chơi & tính cách, không phải ngoại hình. AI Matching phân Zone thông minh giúp bạn leo rank mượt mà, tạm biệt tạ vàng!',
                          style: TextStyle(color: theme.textMuted, fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 24),

                        // Dual Action CTA Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ThemeService.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 6,
                                  shadowColor: ThemeService.accent.withOpacity(0.4),
                                ),
                                icon: const Icon(Icons.sports_esports),
                                label: const Text('THAM GIA NGAY - ĐĂNG KÝ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(isLogin: false)));
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.cardHigh,
                                  foregroundColor: theme.isDark ? cyanSecondary : ThemeService.accent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: theme.border),
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.explore),
                                label: const Text('KHÁM PHÁ ZONE AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(isLogin: true)));
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Hero Banner Clean Showcase
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: pinkAccent.withOpacity(0.3)),
                            boxShadow: [BoxShadow(color: theme.isDark ? Colors.black38 : Colors.black12, blurRadius: 20)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.asset(
                                'assets/images/hero_banner.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/mascot.png', fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Supported Games Section ("6 Đại Chiến Trường Hỗ Trợ")
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.videogame_asset, color: accentText, size: 22),
                                const SizedBox(width: 8),
                                Text('6 ĐẠI CHIẾN TRƯỜNG HỖ TRỢ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.textPrimary)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.cardHigh,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: theme.border),
                              ),
                              child: Text('Hot Meta', style: TextStyle(color: theme.isDark ? cyanSecondary : ThemeService.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 6 Games Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: [
                            _buildGameCard('Liên Quân Mobile', 'MOBA 5v5', 'Xạ thủ, Đấu sĩ, Trợ thủ', '1.8k+ bạn', pinkAccent, theme),
                            _buildGameCard('Valorant', 'FPS Tac', 'Duelist, Initiator, Smokes', '2.1k+ bạn', theme.isDark ? cyanSecondary : ThemeService.accent, theme),
                            _buildGameCard('LMHT (LoL)', 'MOBA PC', 'Top, Mid, Rừng, Bot, SP', '1.5k+ bạn', const Color(0xFF7C3AED), theme),
                            _buildGameCard('Đấu Trường Chân Lý', 'Auto Battler', 'Cờ nhân phẩm, Flex bài', '1.2k+ bạn', ThemeService.yellow, theme),
                            _buildGameCard('PUBG Mobile / PC', 'Battle Royale', 'Sinh tồn, Bắn tỉa, Squad', '950+ bạn', theme.isDark ? cyanSecondary : ThemeService.accent, theme),
                            _buildGameCard('Free Fire', 'Survival', 'Chiến địa Booyah đỉnh cao', '1.1k+ bạn', pinkAccent, theme),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // How It Works Pipeline (4 Bước Quy Trình Thông Minh)
                        Row(
                          children: [
                            Icon(Icons.hub, color: theme.isDark ? cyanSecondary : ThemeService.accent, size: 22),
                            const SizedBox(width: 8),
                            Text('QUY TRÌNH GHÉP ĐỘI 4 BƯỚC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Hệ thống AI xử lý siêu tốc trong 15 giây, bảo đảm không gặp đồng đội toxic', style: TextStyle(color: theme.textMuted, fontSize: 12)),
                        const SizedBox(height: 16),

                        _buildStepTile('01', 'Khảo Sát Phong Cách Chơi', 'Trả lời 5 câu hỏi trắc nghiệm nhanh: phong cách tryhard leo rank, chill tấu hài, thói quen bật mic hay giờ chơi ban đêm.', pinkAccent, theme),
                        _buildStepTile('02', 'AI Xếp Phân Khu (Zone)', 'Thuật toán phân tích vị trí lane, mức rank thực tế và thời gian biểu sinh viên để xếp bạn vào Zone đồng điệu.', theme.isDark ? cyanSecondary : ThemeService.accent, theme),
                        _buildStepTile('03', 'Nhiệm Vụ & Tích Điểm Karma', 'Hoàn thành trận đấu êm đẹp, nhận đánh giá thân thiện để tăng uy tín và nhận quà skin độc quyền.', const Color(0xFF7C3AED), theme),
                        _buildStepTile('04', 'Lập Party & Chiến Hết Mình', 'Tự động tạo phòng voice chất lượng cao, ping vào game chiến luôn không tốn một giây đợi chờ.', pinkAccent, theme),
                        const SizedBox(height: 40),

                        // 6 Key Features (6 Đặc Quyền Sinh Viên)
                        Row(
                          children: [
                            Icon(Icons.military_tech, color: accentText, size: 22),
                            const SizedBox(width: 8),
                            Text('6 ĐẶC QUYỀN SINH VIÊN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Được tối ưu riêng cho văn hóa gaming giảng đường Việt Nam', style: TextStyle(color: theme.textMuted, fontSize: 12)),
                        const SizedBox(height: 16),

                        _buildFeatureTile(Icons.psychology, 'AI Zone Matching Không Độc Hại', 'Lọc theo tính cách và thói quen giao tiếp, loại trừ hoàn toàn những đối tượng phá game hoặc thích đổ lỗi.', pinkAccent, theme),
                        _buildFeatureTile(Icons.mic, 'Voice Room Siêu Tốc Độ Trễ Cực Thấp', 'Tích hợp công nghệ khử tạp âm phòng net, cân bằng âm lượng tự động để nghe rõ từng tiếng bước chân.', theme.isDark ? cyanSecondary : ThemeService.accent, theme),
                        _buildFeatureTile(Icons.verified_user, 'Bộ Lọc Chống Tạ & Hệ Thống Karma', 'Mỗi thành viên sở hữu điểm Uy Tín Karma. Game thủ có hành vi tốt nhận được huy hiệu vinh danh độc quyền.', const Color(0xFF7C3AED), theme),
                        _buildFeatureTile(Icons.school, 'Đại Chiến Trường Sinh Viên', 'Giải đấu giao lưu nội bộ hàng tháng giữa các trường ĐH Bách Khoa, RMIT, Kinh Tế, FPT, KHTN với tổng thưởng hấp dẫn.', pinkAccent, theme),
                        _buildFeatureTile(Icons.diamond, 'Cửa Hàng VIP Store Đổi Quà Thật', 'Đổi điểm cày cuốc lấy Skin súng Valorant, Thẻ Garena, RP Liên Minh và vé tham quan các trận chung kết quốc gia.', theme.isDark ? cyanSecondary : ThemeService.accent, theme),
                        _buildFeatureTile(Icons.local_cafe, 'Ưu Đãi Cyber Cafe & Trà Sữa', 'Liên kết hơn 500+ Gaming Lounge cao cấp toàn quốc. Giảm tới 30% giờ chơi và nhận voucher nước ngọt miễn phí.', const Color(0xFF7C3AED), theme),
                        const SizedBox(height: 40),

                        // Community Testimonials (Sinh Viên Đánh Giá Thật)
                        Row(
                          children: [
                            Icon(Icons.forum, color: theme.isDark ? cyanSecondary : ThemeService.accent, size: 22),
                            const SizedBox(width: 8),
                            Text('GAMER SINH VIÊN NÓI GÌ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _buildTestimonialCard('Minh Tuấn', 'ĐH Bách Khoa • Valorant Immortal', 'Duo Partner', 'Nhờ BLUSH tìm được duo bắn cực kỳ ăn ý, không còn cảnh solo gánh tạ toxic lúc nửa đêm. Hệ thống lọc phong cách tryhard làm việc rất chuẩn!', pinkAccent, theme),
                        _buildTestimonialCard('Linh Đan', 'ĐH Quốc Tế • LMHT / ĐTCL', 'Chill Gamer', 'Thích nhất triết lý không đánh giá ngoại hình của BLUSH. Mọi người lập party chơi với nhau vì vui vẻ, thoải mái giao tiếp và đúng gu chill của mình.', theme.isDark ? cyanSecondary : ThemeService.accent, theme),
                        _buildTestimonialCard('Hoàng Nam', 'ĐH Ngoại Thương • Liên Quân Mobile', 'Chiến Tướng', 'Hệ thống Zone AI đỉnh thật sự, ghép đúng đồng đội gần trường nên cuối tuần cả nhóm còn hẹn ra Cyber Lounge đánh chung rồi đi trà sữa nữa.', const Color(0xFF7C3AED), theme),
                        const SizedBox(height: 40),

                        // Bottom Conversion Rocket Banner
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: theme.isDark ? theme.cardHigh : const Color(0xFF1F1F2B),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: pinkAccent.withOpacity(0.4)),
                            boxShadow: [BoxShadow(color: ThemeService.accent.withOpacity(0.2), blurRadius: 25)],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(color: pinkAccent, shape: BoxShape.circle),
                                child: const Icon(Icons.rocket_launch, color: Colors.white, size: 28),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'SẮN SÀNG TÌM TRI KỶ CHIẾN GAME ĐÊM NAY?',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tạo tài khoản chỉ với 30 giây bằng Email Sinh viên hoặc Discord để nhận ngay 500 Điểm Karma VIP!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: pinkAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 6,
                                  ),
                                  icon: const Icon(Icons.arrow_forward),
                                  label: const Text('TẠO TÀI KHOẢN MIỄN PHÍ ➔', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(isLogin: false)));
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.verified, color: theme.isDark ? cyanSecondary : const Color(0xFF00EEFC), size: 14),
                                  const SizedBox(width: 4),
                                  const Text('Bảo mật 100% • Không yêu cầu ảnh cá nhân', style: TextStyle(color: Color(0xFF00EEFC), fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Footer
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '© 2025 BLUSH Gaming Vietnam. Tất cả bản quyền được bảo lưu.\nNền tảng kết nối playstyle số 1 cho sinh viên Việt Nam.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.textMuted, fontSize: 11, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(String name, String type, String roles, String count, Color color, ThemeService theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          if (!theme.isDark)
            BoxShadow(color: color.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(type, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.bolt, color: color, size: 14),
            ],
          ),
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textPrimary)),
          Text(roles, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.textMuted, fontSize: 11)),
          Row(
            children: [
              Icon(Icons.circle, color: theme.isDark ? const Color(0xFF00EEFC) : ThemeService.accent, size: 6),
              const SizedBox(width: 4),
              Text(
                'Tìm đội: $count',
                style: TextStyle(
                  color: theme.isDark ? const Color(0xFF00EEFC) : ThemeService.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(String step, String title, String desc, Color color, ThemeService theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          if (!theme.isDark)
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(step, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 11, color: theme.textMuted, height: 1.3)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String desc, Color color, ThemeService theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          if (!theme.isDark)
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 11, color: theme.textMuted, height: 1.3)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(String name, String school, String tag, String text, Color color, ThemeService theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          if (!theme.isDark)
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(name[0], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textPrimary)),
                      Text(school, style: TextStyle(fontSize: 10, color: theme.textMuted)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tag, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"$text"',
            style: TextStyle(fontSize: 12, color: theme.textPrimary, fontStyle: FontStyle.italic, height: 1.4),
          ),
        ],
      ),
    );
  }
}
