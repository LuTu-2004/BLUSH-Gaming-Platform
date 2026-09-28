import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'auth_screen.dart';

/// Màn giới thiệu cho người chưa đăng nhập.
/// Nội dung bám theo tài liệu chức năng (Chức năng 1 & 2): 4 tính năng cốt lõi, 6 tựa game, quy trình 4 bước.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _features = [
    (Icons.auto_awesome, 'AI Matching', 'Xếp bạn vào Zone phù hợp theo tựa game, vị trí và mục đích chơi.'),
    (Icons.ac_unit, 'Nhiệm vụ phá băng', 'Cùng trả lời 1 câu hỏi tình huống game trước khi chat, bắt chuyện tự nhiên hơn.'),
    (Icons.forum_outlined, 'Trợ lý trò chuyện AI', 'Gợi ý câu mở đầu và chủ đề khi cuộc trò chuyện chững lại.'),
    (Icons.visibility_off_outlined, 'Blind Profile', 'Ẩn ảnh đại diện cho tới khi hai bên kết nối: làm quen bằng tính cách.'),
  ];

  static const _games = ['Liên Quân Mobile', 'Valorant', 'LMHT', 'Đấu Trường Chân Lý', 'PUBG Mobile', 'Free Fire'];

  static const _steps = [
    ('Khảo sát', 'Chọn game, vị trí và mục đích chơi của bạn.'),
    ('AI xếp Zone', 'Hệ thống đưa bạn vào phân khu hợp gu.'),
    ('Làm nhiệm vụ', 'Tích EXP, Coins và huy hiệu mỗi ngày.'),
    ('Lập party', 'Ghép đội với người hợp cạ và vào trận.'),
  ];

  void _openAuth(BuildContext context, {required bool isLogin}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AuthScreen(isLogin: isLogin)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpace.lg,
        title: Image.asset('assets/images/logo.png', height: 32, errorBuilder: (_, __, ___) => Text('BLUSH', style: text.titleLarge)),
        actions: [
          IconButton(
            tooltip: t.isDark ? 'Giao diện sáng' : 'Giao diện tối',
            icon: Icon(t.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: t.toggleTheme,
          ),
          TextButton(onPressed: () => _openAuth(context, isLogin: true), child: const Text('Đăng nhập')),
          const SizedBox(width: AppSpace.sm),
        ],
      ),
      body: PageBody(
        children: [
          // ── Giới thiệu ──────────────────────────────────────────
          const SizedBox(height: AppSpace.md),
          const Align(alignment: Alignment.centerLeft, child: TagChip('Ghép đội bằng AI cho sinh viên', icon: Icons.bolt)),
          const SizedBox(height: AppSpace.md),
          Text('Tìm đồng đội hợp gu, không phải hợp ảnh', style: text.headlineSmall?.copyWith(fontSize: 28)),
          const SizedBox(height: AppSpace.md),
          Text(
            'BLUSH kết nối game thủ bằng phong cách chơi và tính cách. AI xếp bạn vào đúng Zone để leo rank hay giải trí đều có người đồng hành.',
            style: text.bodyLarge?.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: AppSpace.xl),
          ElevatedButton(onPressed: () => _openAuth(context, isLogin: false), child: const Text('Bắt đầu miễn phí')),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton(onPressed: () => _openAuth(context, isLogin: true), child: const Text('Tôi đã có tài khoản')),
          const SizedBox(height: AppSpace.xl),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.asset(
              'assets/images/hero_banner.png',
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: AppSpace.xxl),

          // ── Tính năng cốt lõi ───────────────────────────────────
          const SectionHeader('Tính năng nổi bật'),
          for (final (icon, title, desc) in _features) ...[
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpace.sm),
                    decoration: BoxDecoration(color: ThemeService.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Icon(icon, color: t.isDark ? ThemeService.accentLight : ThemeService.accent),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: text.titleSmall),
                        const SizedBox(height: 2),
                        Text(desc, style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
          const SizedBox(height: AppSpace.xl),

          // ── Tựa game ────────────────────────────────────────────
          const SectionHeader('Tựa game hỗ trợ'),
          Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.sm, children: [for (final g in _games) Chip(label: Text(g))]),
          const SizedBox(height: AppSpace.xxl),

          // ── Quy trình ───────────────────────────────────────────
          const SectionHeader('Bắt đầu trong 4 bước'),
          for (var i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: ThemeService.accent,
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_steps[i].$1, style: text.titleSmall),
                        Text(_steps[i].$2, style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.xl),

          // ── Kêu gọi hành động ───────────────────────────────────
          AppCard(
            borderColor: ThemeService.accent,
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              children: [
                Text('Sẵn sàng tìm đồng đội?', style: text.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: AppSpace.xs),
                Text('Đăng ký miễn phí, chỉ mất 1 phút.', style: text.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: AppSpace.lg),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _openAuth(context, isLogin: false), child: const Text('Tạo tài khoản'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
