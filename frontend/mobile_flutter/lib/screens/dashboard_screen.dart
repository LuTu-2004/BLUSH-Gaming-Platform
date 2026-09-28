import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../api/api_client.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/quest_service.dart';
import 'chat_room_screen.dart';
import 'quests_screen.dart';
import 'vip_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  String _selectedGame = 'Tất cả';

  final List<String> _gameFilters = [
    'Tất cả',
    'Liên Quân Mobile',
    'Valorant',
    'LMHT',
    'DTCL',
    'PUBG Mobile',
    'Free Fire',
  ];

  // Active gamers in lobby (scope-aligned: MBTI + game + purpose)
  final List<Map<String, dynamic>> _lobbyGamers = [
    {
      'avatar': '🌸',
      'name': 'Khánh Linh',
      'age': 20,
      'mbti': 'ENFP',
      'game': 'Liên Quân Mobile',
      'purpose': 'Hội Tấu Hài',
      'match': 94,
      'color': ThemeService.blurple,
      'online': true,
    },
    {
      'avatar': '⚔️',
      'name': 'Minh Thùy',
      'age': 19,
      'mbti': 'INTP',
      'game': 'Valorant',
      'purpose': 'Chúa Tryhard',
      'match': 88,
      'color': ThemeService.fuchsia,
      'online': true,
    },
    {
      'avatar': '👑',
      'name': 'Thùy Dung',
      'age': 21,
      'mbti': 'ENFP',
      'game': 'LMHT',
      'purpose': 'Chill & Học Hỏi',
      'match': 92,
      'color': ThemeService.green,
      'online': true,
    },
    {
      'avatar': '🎯',
      'name': 'Hùng Dũng',
      'age': 22,
      'mbti': 'ISTJ',
      'game': 'DTCL',
      'purpose': 'Leo Rank Nghiêm Túc',
      'match': 81,
      'color': ThemeService.yellow,
      'online': false,
    },
    {
      'avatar': '💥',
      'name': 'Bảo Nam',
      'age': 21,
      'mbti': 'ESTP',
      'game': 'PUBG Mobile',
      'purpose': 'Săn Booyah Squad',
      'match': 89,
      'color': ThemeService.cyan,
      'online': true,
    },
    {
      'avatar': '🔥',
      'name': 'Hoàng Yến',
      'age': 20,
      'mbti': 'ESFP',
      'game': 'Free Fire',
      'purpose': 'Hội Tấu Hài Sảnh Đấu',
      'match': 86,
      'color': ThemeService.pink,
      'online': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool _checkingIn = false;

  Future<void> _checkIn(QuestService quests) async {
    setState(() => _checkingIn = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final message = await quests.checkIn(context.read<AuthService>());
      messenger.showSnackBar(SnackBar(content: Text('$message (+${QuestService.checkInCoins} Coins & +${QuestService.checkInExp} EXP)'), backgroundColor: ThemeService.accent));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message), backgroundColor: ThemeService.red));
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final user = context.watch<AuthService>().currentUser;
    final quests = context.watch<QuestService>();
    final checkedIn = user?.checkedInToday ?? false;

    const primaryPurple = ThemeService.accent;
    const primaryLight = ThemeService.accentLight;
    const pinkAccent = ThemeService.pink;
    const cyanAccent = ThemeService.cyan;
    const greenAccent = ThemeService.green;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HERO BANNER ───────────────────────────────────────────────
            _buildHeroBanner(user, theme, primaryPurple, primaryLight, pinkAccent, cyanAccent),

            // ── BODY CONTENT ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── QUICK STATS ─────────────────────────────────
                      Row(
                        children: [
                          _buildStatChip('🪙', '${user?.coins ?? 0}', 'Coins', ThemeService.yellow, theme),
                          const SizedBox(width: 10),
                          _buildStatChip('⚡', '${user?.exp ?? 0}', 'EXP', primaryLight, theme),
                          const SizedBox(width: 10),
                          _buildStatChip('🛡️', 'Lv.${user?.level ?? 1}', 'Level', pinkAccent, theme),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── 6 ĐẠI CHIẾN TRƯỜNG GAME (GAME CATEGORIES & ZONES) ───────
                      _buildSectionHeader(
                        icon: Icons.sports_esports,
                        iconColor: primaryPurple,
                        title: '6 Đại Chiến Trường Game',
                        badge: 'Zones Meta',
                        badgeColor: cyanAccent,
                        trailing: null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Chọn game yêu thích để lọc danh sách đồng đội ghép cặp tương thích',
                        style: TextStyle(color: theme.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 12),

                      // 6 Games Grid Selector
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: [
                          _buildGameCategoryCard('📱 Liên Quân', 'Liên Quân Mobile', 'MOBA 5v5', pinkAccent, theme),
                          _buildGameCategoryCard('🎯 Valorant', 'Valorant', 'FPS Tac', cyanAccent, theme),
                          _buildGameCategoryCard('👑 LMHT', 'LMHT', 'MOBA PC', ThemeService.accentLight, theme),
                          _buildGameCategoryCard('🎲 DTCL', 'DTCL', 'Auto Battler', ThemeService.yellow, theme),
                          _buildGameCategoryCard('💥 PUBG', 'PUBG Mobile', 'Battle Royale', cyanAccent, theme),
                          _buildGameCategoryCard('🔥 Free Fire', 'Free Fire', 'Survival', pinkAccent, theme),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── LIVE LOBBY SECTION WITH GAME FILTER CHIPS ─────────────────
                      _buildSectionHeader(
                        icon: Icons.groups,
                        iconColor: cyanAccent,
                        title: 'Đang Tìm Đồng Đội',
                        badge: '${_lobbyGamers.where((g) => g['online'] == true).length} Online',
                        badgeColor: greenAccent,
                        trailing: null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Những game thủ sinh viên đang chờ ghép cặp ${_selectedGame == "Tất cả" ? "ngay lúc này" : "cho game $_selectedGame"}',
                        style: TextStyle(color: theme.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 12),

                      // Interactive Game Filter Bar
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _gameFilters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final game = _gameFilters[index];
                            final isSelected = game == _selectedGame;
                            return ChoiceChip(
                              selected: isSelected,
                              showCheckmark: false,
                              label: Text(
                                game,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : theme.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                              selectedColor: primaryPurple,
                              backgroundColor: theme.card,
                              side: BorderSide(
                                color: isSelected ? primaryPurple : theme.border,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedGame = game;
                                  });
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Lobby gamer cards (Filtered by selected game)
                      Builder(
                        builder: (context) {
                          final filteredGamers = _selectedGame == 'Tất cả'
                              ? _lobbyGamers
                              : _lobbyGamers.where((g) => (g['game'] as String).contains(_selectedGame) || _selectedGame.contains(g['game'] as String)).toList();

                          if (filteredGamers.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.border),
                              ),
                              child: Column(
                                children: [
                                  const Text('🎮', style: TextStyle(fontSize: 36)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Chưa có đồng đội online ở game $_selectedGame',
                                    style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hãy chọn game khác hoặc bấm Tìm Đồng Đội để AI ghép ngẫu nhiên!',
                                    style: TextStyle(color: theme.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.5,
                            ),
                            itemCount: filteredGamers.length,
                            itemBuilder: (context, index) {
                              return _buildLobbyCard(filteredGamers[index], theme);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── DAILY QUEST SNAPSHOT ─────────────────────────
                      _buildSectionHeader(
                        icon: Icons.military_tech,
                        iconColor: greenAccent,
                        title: 'Nhiệm Vụ Hôm Nay',
                        badge: '${quests.completedCount}/${quests.totalCount}',
                        badgeColor: greenAccent,
                        trailing: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestsScreen())),
                          child: const Text('Xem chi tiết ›', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: theme.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: greenAccent.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tiến độ hôm nay', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: greenAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: greenAccent.withValues(alpha: 0.4)),
                                  ),
                                  child: Text('${(quests.dailyProgress * 100).round()}% hoàn thành', style: const TextStyle(color: ThemeService.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(value: quests.dailyProgress, minHeight: 8, backgroundColor: Colors.black26, color: const Color(0xFF4ADE80)),
                            ),
                            const SizedBox(height: 14),
                            // Checkin tile
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryPurple.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.calendar_today, color: Color(0xFFD2BBFF), size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Điểm danh hàng ngày', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const Text('+${QuestService.checkInCoins} Coins & +${QuestService.checkInExp} EXP', style: TextStyle(color: ThemeService.accentLight, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: checkedIn ? Colors.white12 : primaryPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  onPressed: checkedIn || _checkingIn ? null : () => _checkIn(quests),
                                  child: Text(checkedIn ? 'Đã Nhận ✓' : 'Nhận Ngay', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── VIP PROMO (if not VIP) ───────────────────────
                      if (user?.isVip != true)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B2CBF), Color(0xFF4C1D95)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFFC700).withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              const Text('👑', style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Nâng cấp VIP Pass', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                                    SizedBox(height: 3),
                                    Text('AI không giới hạn, khung avatar & ưu tiên ghép đội chỉ từ 29K/tháng', style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VipScreen())),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(color: const Color(0xFFFFC700), borderRadius: BorderRadius.circular(10)),
                                  child: const Text('Xem Ngay', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HERO BANNER ──────────────────────────────────────────────────────────
  Widget _buildHeroBanner(
    UserModel? user,
    ThemeService theme,
    Color primaryPurple,
    Color primaryLight,
    Color pinkAccent,
    Color cyanAccent,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.isDark ? const [Color(0xFF0D0B1A), Color(0xFF1A0B2E), Color(0xFF13131B)] : const [Color(0xFFEDE7F6), Color(0xFFE1D5F5), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background glow blobs
          Positioned(
            top: -30,
            left: -40,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Opacity(
                opacity: _pulseAnim.value * (theme.isDark ? 0.25 : 0.15),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryPurple,
                    boxShadow: [BoxShadow(color: primaryPurple, blurRadius: 80, spreadRadius: 20)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: -20,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Opacity(
                opacity: (1.0 - _pulseAnim.value) * (theme.isDark ? 0.2 : 0.1),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pinkAccent,
                    boxShadow: [BoxShadow(color: pinkAccent, blurRadius: 60, spreadRadius: 15)],
                  ),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Row(
                  children: [
                    // Left: Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Live indicator pill
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, __) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: primaryPurple.withValues(alpha: theme.isDark ? 0.25 : 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: primaryPurple.withValues(alpha: 0.5 + _pulseAnim.value * 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.isDark ? primaryLight : primaryPurple,
                                      boxShadow: [BoxShadow(color: primaryLight, blurRadius: 6 * _pulseAnim.value)],
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'AI MATCHING ĐANG HOẠT ĐỘNG',
                                    style: TextStyle(
                                      color: theme.isDark ? const Color(0xFFD2BBFF) : const Color(0xFF6D28D9),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Greeting
                          Text(
                            'Chào, ${user?.displayName ?? 'Game Thủ'} 👋',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: theme.textPrimary,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primaryPurple.withValues(alpha: theme.isDark ? 0.3 : 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  (user?.mbti.isNotEmpty ?? false) ? user!.mbti : 'Chưa có MBTI',
                                  style: TextStyle(
                                    color: theme.isDark ? const Color(0xFFD2BBFF) : primaryPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                [user?.isVip == true ? '👑 VIP' : 'Lv.${user?.level ?? 1}', if (user?.age != null) '${user!.age} tuổi'].join(' • '),
                                style: TextStyle(color: theme.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Bio preview
                          if (user != null && user.bio.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.cardHigh,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.format_quote, color: Color(0xFF00EEFC), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      user.bio,
                                      style: TextStyle(color: theme.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            const SizedBox(height: 8),
                          ],

                          // CTA — Tìm Đồng Đội
                          Row(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 6,
                                  shadowColor: primaryPurple.withValues(alpha: 0.5),
                                ),
                                icon: const Icon(Icons.radar, size: 18),
                                label: const Text('Tìm Đồng Đội', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('AI đang phân tích hồ sơ của bạn... 🤖')),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              // Live count pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: theme.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.border),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.people, color: Color(0xFF4ADE80), size: 16),
                                    SizedBox(width: 6),
                                    Text('127 online', style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Right: Mascot image
                    if (MediaQuery.of(context).size.width > 480) ...[
                      const SizedBox(width: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow ring behind mascot
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, __) => Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryPurple.withValues(alpha: _pulseAnim.value * 0.5),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/mascot.png',
                              height: 140,
                              width: 140,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                height: 140,
                                width: 140,
                                child: Center(child: Text('🎮', style: TextStyle(fontSize: 72))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Bottom fade
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, theme.bg],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LOBBY CARD ────────────────────────────────────────────────────────────
  Widget _buildLobbyCard(Map<String, dynamic> gamer, ThemeService theme) {
    final Color color = gamer['color'] as Color;
    final bool isOnline = gamer['online'] as bool;
    const primaryPurple = ThemeService.accent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOnline ? color.withValues(alpha: 0.4) : theme.border,
          width: 1.2,
        ),
        boxShadow: isOnline ? [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4))] : null,
      ),
      child: Row(
        children: [
          // Avatar + Online dot
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Center(child: Text(gamer['avatar'] as String, style: const TextStyle(fontSize: 24))),
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOnline ? ThemeService.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.card, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      '${gamer['name']}, ${gamer['age']}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryPurple.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(gamer['mbti'] as String, style: TextStyle(color: theme.isDark ? const Color(0xFFD2BBFF) : primaryPurple, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '🎮 ${gamer['game']}',
                  style: TextStyle(fontSize: 11, color: theme.textMuted),
                ),
                Text(
                  '🎯 ${gamer['purpose']}',
                  style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),

          // Match % + Chat button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.electric_bolt, color: Color(0xFFFFC700), size: 11),
                    const SizedBox(width: 2),
                    Text('${gamer['match']}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(
                      teammateName: gamer['name'] as String,
                      teammateAvatar: gamer['avatar'] as String,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryPurple,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: primaryPurple.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Chat', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SECTION HEADER ────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
    required Color badgeColor,
    required Widget? trailing,
  }) {
    final theme = context.watch<ThemeService>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
              ),
              child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  // ── STAT CHIP ─────────────────────────────────────────────────────────────
  Widget _buildStatChip(String emoji, String value, String label, Color color, ThemeService theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: theme.textPrimary)),
                Text(label, style: TextStyle(fontSize: 10, color: theme.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCategoryCard(String title, String fullGameName, String genre, Color accentColor, ThemeService theme) {
    final isSelected = _selectedGame == fullGameName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGame = isSelected ? 'Tất cả' : fullGameName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSelected ? '🎮 Đã bỏ lọc, hiện tất cả game' : '🎮 Đã lọc phân khu đồng đội: $fullGameName'),
            duration: const Duration(seconds: 1),
            backgroundColor: ThemeService.accent,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.18) : theme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : theme.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? [BoxShadow(color: accentColor.withValues(alpha: 0.2), blurRadius: 10)] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.gamepad, color: accentColor, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: theme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    genre,
                    style: TextStyle(color: theme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
