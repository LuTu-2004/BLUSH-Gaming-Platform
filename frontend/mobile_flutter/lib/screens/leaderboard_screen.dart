import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import 'chat_room_screen.dart';
import 'quests_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // ── Filters ──
  String _regionFilter = 'Toàn quốc';
  String _gameFilter = 'Tất cả';

  // ── Brand accent colors (same across both modes) ──
  static const _primary = ThemeService.accentLight; // #D2BBFF
  static const _primaryContainer = ThemeService.accent; // #7C3AED
  static const _onPrimaryContainer = Color(0xFFEDE0FF);
  static const _yellow = ThemeService.yellow;
  static const _green = ThemeService.green;

  // ── Data ──
  final List<Map<String, dynamic>> _gamers = [
    {'rank': 1, 'name': 'Kuro_Ace', 'mbti': 'INTJ', 'exp': 28450, 'coins': 3820, 'level': 42, 'avatar': '👑', 'isMe': false},
    {'rank': 2, 'name': 'LinhDan', 'mbti': 'ENFP', 'exp': 25120, 'coins': 3200, 'level': 39, 'avatar': '🌸', 'isMe': false},
    {'rank': 3, 'name': 'MinhShadow', 'mbti': 'ISTP', 'exp': 22980, 'coins': 2750, 'level': 36, 'avatar': '⚔️', 'isMe': false},
    {'rank': 4, 'name': 'BaoBao_TFT', 'mbti': 'INTP', 'exp': 19850, 'coins': 2400, 'level': 34, 'avatar': '🎮', 'isMe': false},
    {'rank': 5, 'name': 'Zeref_Carry', 'mbti': 'ENTJ', 'exp': 18200, 'coins': 2150, 'level': 32, 'avatar': '⚡', 'isMe': false},
    {'rank': 6, 'name': 'MeoMeo_SP', 'mbti': 'ISFJ', 'exp': 16900, 'coins': 1980, 'level': 30, 'avatar': '🐱', 'isMe': false},
    {'rank': 7, 'name': 'HaiDang_Mid', 'mbti': 'ENTP', 'exp': 15400, 'coins': 1820, 'level': 29, 'avatar': '🔥', 'isMe': false},
    {'rank': 8, 'name': 'VyVy_Sniper', 'mbti': 'INFJ', 'exp': 14750, 'coins': 1650, 'level': 28, 'avatar': '🎯', 'isMe': false},
    {'rank': 24, 'name': 'Lưu Phước Nhật Tú', 'mbti': 'INFJ', 'exp': 11850, 'coins': 2450, 'level': 25, 'avatar': '🎮', 'isMe': true},
  ];

  Map<String, dynamic> get _myRank => _gamers.firstWhere((g) => g['isMe'] == true);
  List<Map<String, dynamic>> get _top3 => _gamers.where((g) => (g['rank'] as int) <= 3).toList()..sort((a, b) => (a['rank'] as int).compareTo(b['rank'] as int));
  List<Map<String, dynamic>> get _restList => _gamers.where((g) => (g['rank'] as int) > 3 && g['isMe'] != true).toList();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final theme = context.watch<ThemeService>();

    return Scaffold(
      backgroundColor: theme.bg,
      body: Stack(
        children: [
          // ── MAIN SCROLL ────────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER BANNER ─────────────────────────────────
                _buildHeaderBanner(theme),

                // ── FILTER RAILS ───────────────────────────────────
                _buildFilterRails(theme),
                const SizedBox(height: 8),

                // ── TOP 3 PODIUM ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildPodium(theme),
                ),

                // ── REST LIST HEADER ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top Chiến Binh (Hạng 4 - 20)',
                        style: TextStyle(color: theme.textMuted, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _primaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Cập nhật mỗi 10 phút', style: TextStyle(color: _primary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // ── RANK 4+ LIST ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _restList.map((g) => _buildRankRow(g, theme)).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── STICKY BOTTOM DOCK ─────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildMyRankDock(
              user?.displayName ?? _myRank['name'] as String,
              user?.level ?? _myRank['level'] as int,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // HEADER BANNER
  // ════════════════════════════════════════════════════════════════
  Widget _buildHeaderBanner(ThemeService theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mùa Giải Season 3',
                style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _primaryContainer.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 14, color: _primary),
                    const SizedBox(width: 4),
                    Text('Kết thúc: ', style: TextStyle(color: theme.textMuted, fontSize: 11)),
                    const Text('4 ngày 12 giờ', style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Bảng Xếp Hạng Zone',
            style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.3),
          ),
          const SizedBox(height: 3),
          Text(
            'Top game thủ tích lũy nhiều EXP nhất mùa 3 — lọc theo khu vực & tựa game',
            style: TextStyle(color: theme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // FILTER RAILS
  // ════════════════════════════════════════════════════════════════
  Widget _buildFilterRails(ThemeService theme) {
    final regions = ['Toàn quốc', 'Server TP.HCM', 'Server Hà Nội', 'Server Đà Nẵng'];
    final games = ['Tất cả', 'Valorant', 'Liên Quân', 'LMHT', 'DTCL'];

    return Column(
      children: [
        // Region chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: regions.map((r) {
              final active = _regionFilter == r;
              return GestureDetector(
                onTap: () => setState(() => _regionFilter = r),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? _primaryContainer : theme.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: active ? _primaryContainer : theme.border),
                    boxShadow: active ? [BoxShadow(color: _primaryContainer.withValues(alpha: 0.3), blurRadius: 6)] : null,
                  ),
                  child: Text(
                    r,
                    style: TextStyle(
                      color: active ? _onPrimaryContainer : theme.textMuted,
                      fontWeight: active ? FontWeight.bold : FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),

        // Game chips
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: games.map((g) {
              final active = _gameFilter == g;
              return GestureDetector(
                onTap: () => setState(() => _gameFilter = g),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? _primaryContainer.withValues(alpha: 0.15) : theme.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: active ? _primary.withValues(alpha: 0.4) : theme.border),
                  ),
                  child: Row(
                    children: [
                      if (active) ...[
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: _primary),
                        ),
                      ],
                      Text(
                        g,
                        style: TextStyle(
                          color: active ? _primary : theme.textMuted,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // TOP 3 PODIUM
  // ════════════════════════════════════════════════════════════════
  Widget _buildPodium(ThemeService theme) {
    final rank1 = _top3.firstWhere((g) => g['rank'] == 1);
    final rank2 = _top3.firstWhere((g) => g['rank'] == 2);
    final rank3 = _top3.firstWhere((g) => g['rank'] == 3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _buildPodiumCard(rank2, rank: 2, isCenter: false, theme: theme)),
        const SizedBox(width: 8),
        Expanded(child: _buildPodiumCard(rank1, rank: 1, isCenter: true, theme: theme)),
        const SizedBox(width: 8),
        Expanded(child: _buildPodiumCard(rank3, rank: 3, isCenter: false, theme: theme)),
      ],
    );
  }

  Widget _buildPodiumCard(Map<String, dynamic> gamer, {required int rank, required bool isCenter, required ThemeService theme}) {
    final rankColor = rank == 1
        ? _yellow
        : rank == 2
            ? _primary
            : const Color(0xFFCD7F32);

    return GestureDetector(
      onTap: () => _showGamerDialog(gamer, theme),
      child: Container(
        padding: EdgeInsets.all(isCenter ? 10 : 8),
        decoration: BoxDecoration(
          color: isCenter ? theme.card : theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: rankColor.withValues(alpha: isCenter ? 0.5 : 0.25), width: isCenter ? 1.5 : 1),
          boxShadow: isCenter
              ? [BoxShadow(color: _primaryContainer.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rank crown/medal icon
            Container(
              width: isCenter ? 34 : 26,
              height: isCenter ? 34 : 26,
              decoration: BoxDecoration(
                color: isCenter ? _primaryContainer : _primaryContainer.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isCenter ? Icons.workspace_premium : Icons.military_tech,
                  size: isCenter ? 18 : 14,
                  color: isCenter ? _onPrimaryContainer : _primary,
                ),
              ),
            ),
            SizedBox(height: isCenter ? 6 : 4),

            // Avatar circle
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: isCenter ? 60 : 48,
                  height: isCenter ? 60 : 48,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: rankColor.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Center(
                    child: Text(gamer['avatar'] as String, style: TextStyle(fontSize: isCenter ? 28 : 22)),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isCenter ? 5 : 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: isCenter ? _primaryContainer : theme.cardHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: isCenter ? _onPrimaryContainer : theme.textMuted,
                      fontSize: isCenter ? 9 : 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isCenter ? 5 : 4),

            // Name
            Text(
              gamer['name'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: isCenter ? 12 : 10,
              ),
            ),
            SizedBox(height: isCenter ? 4 : 3),

            // MBTI + Level badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _primaryContainer.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(gamer['mbti'] as String, style: const TextStyle(color: _primary, fontSize: 7, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: theme.cardHigh, borderRadius: BorderRadius.circular(4)),
                  child: Text('Lv.${gamer['level']}', style: TextStyle(color: theme.textMuted, fontSize: 7)),
                ),
              ],
            ),
            SizedBox(height: isCenter ? 5 : 4),

            // EXP stat
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isCenter ? theme.cardHigh : theme.cardHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fmtNum(gamer['exp'] as int),
                    style: TextStyle(
                      color: rankColor,
                      fontWeight: FontWeight.w900,
                      fontSize: isCenter ? 13 : 10,
                    ),
                  ),
                  Text('EXP', style: TextStyle(color: theme.textMuted, fontSize: 8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // RANK ROW (4+)
  // ════════════════════════════════════════════════════════════════
  Widget _buildRankRow(Map<String, dynamic> gamer, ThemeService theme) {
    final isMe = gamer['isMe'] == true;
    final rank = gamer['rank'] as int;

    return GestureDetector(
      onTap: () => _showGamerDialog(gamer, theme),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? _primaryContainer.withValues(alpha: 0.1) : theme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe ? _primaryContainer.withValues(alpha: 0.4) : theme.border,
            width: isMe ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 28,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textMuted, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(width: 10),

            // Avatar circle
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryContainer.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(gamer['avatar'] as String, style: const TextStyle(fontSize: 20))),
                ),
                if (isMe)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: _primaryContainer, borderRadius: BorderRadius.circular(4)),
                      child: const Text('BẠN', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),

            // Name + MBTI + sub
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          gamer['name'] as String,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryContainer.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(gamer['mbti'] as String, style: const TextStyle(color: _primary, fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  Text(
                    'Lv.${gamer['level']} • Game Thủ Sinh Viên',
                    style: TextStyle(color: theme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

            // EXP + Coins
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      _fmtNum(gamer['exp'] as int),
                      style: const TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 3),
                    Text('EXP', style: TextStyle(color: theme.textMuted, fontSize: 9)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _primaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Lv.${gamer['level']}', style: TextStyle(color: theme.textMuted, fontSize: 9)),
                    ),
                    const SizedBox(width: 4),
                    Text('${_fmtNum(gamer['coins'] as int)} BL', style: TextStyle(color: theme.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // STICKY MY RANK FLOATING DOCK
  // ════════════════════════════════════════════════════════════════
  Widget _buildMyRankDock(String userName, int userLevel, ThemeService theme) {
    final me = _myRank;
    final myExp = me['exp'] as int;
    const nextMilestone = 12200;
    final progress = (myExp / nextMilestone).clamp(0.0, 1.0);
    final expLeft = nextMilestone - myExp;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, -4))],
        border: Border.all(color: theme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: rank + avatar + name + stats + CTA
          Row(
            children: [
              // My rank
              const Column(
                children: [
                  Text('#24', style: TextStyle(color: _primary, fontWeight: FontWeight.w900, fontSize: 18, height: 1)),
                  Row(
                    children: [
                      Icon(Icons.arrow_drop_up, color: _green, size: 14),
                      Text('3', style: TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 10),

              // Avatar
              Stack(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(color: _primaryContainer, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'R',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: _primaryContainer, borderRadius: BorderRadius.circular(4)),
                      child: const Text('BẠN', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),

              // Name + sub
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: _primaryContainer.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                          child: const Text('INFJ', style: TextStyle(color: _primary, fontSize: 9, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    Text('Lv.$userLevel • BLUSH Gamer', style: TextStyle(color: theme.textMuted, fontSize: 11)),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_fmtNum(myExp)} EXP',
                    style: const TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    '${_fmtNum(me['coins'] as int)} BL',
                    style: TextStyle(color: theme.textMuted, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // CTA
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestsScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: _primaryContainer.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Text('Cày EXP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 11, color: theme.textMuted),
                          children: [
                            const TextSpan(text: 'Còn '),
                            TextSpan(
                              text: '${_fmtNum(expLeft)} EXP',
                              style: const TextStyle(color: _primary, fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: ' nữa để vào Top 20!'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('+15% BL Thưởng', style: TextStyle(color: _primary, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: theme.border,
                    color: _primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // GAMER DETAIL DIALOG
  // ════════════════════════════════════════════════════════════════
  void _showGamerDialog(Map<String, dynamic> gamer, ThemeService theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: theme.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _primaryContainer.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: _primaryContainer.withValues(alpha: 0.4), width: 2),
                  ),
                  child: Center(child: Text(gamer['avatar'] as String, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(gamer['name'] as String, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: _primaryContainer.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                            child: Text(gamer['mbti'] as String, style: const TextStyle(color: _primary, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      Text('Hạng #${gamer['rank']} • Lv.${gamer['level']}', style: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _statBadge('⚡ EXP', _fmtNum(gamer['exp'] as int), _primary, theme),
                const SizedBox(width: 10),
                _statBadge('🪙 Coins', _fmtNum(gamer['coins'] as int), _yellow, theme),
                const SizedBox(width: 10),
                _statBadge('🛡️ Level', 'Lv.${gamer['level']}', _green, theme),
              ],
            ),
            const SizedBox(height: 20),
            if (gamer['isMe'] != true)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryContainer,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('NHẮN TIN NGAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        teammateName: gamer['name'] as String,
                        teammateAvatar: gamer['avatar'] as String,
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.cardHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Đây là hồ sơ của bạn 🎮', textAlign: TextAlign.center, style: TextStyle(color: theme.textMuted, fontSize: 13)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color, ThemeService theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
            Text(label, style: TextStyle(color: theme.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────
  String _fmtNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return '$n';
  }
}
