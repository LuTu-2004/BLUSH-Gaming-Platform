import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import 'chat_room_screen.dart';

class MatchFeedScreen extends StatefulWidget {
  const MatchFeedScreen({super.key});

  @override
  State<MatchFeedScreen> createState() => _MatchFeedScreenState();
}

class _MatchFeedScreenState extends State<MatchFeedScreen> {
  bool _blindProfile = true;

  final List<Map<String, dynamic>> _profiles = [
    {
      'name': 'Khánh Linh',
      'age': 20,
      'mbti': 'ENFP',
      'match': 94,
      'avatar': '🌸',
      'game': 'Liên Quân Mobile',
      'lane': 'Trợ Thủ / SP',
      'bio': 'Tìm đồng đội Mid/AD leo rank Cao Thủ nghiêm túc, mic rõ không toxic!',
      'interests': ['Tryhard', 'Liên Quân', 'Voice Chat', 'K-Pop'],
      'color': ThemeService.accent,
    },
    {
      'name': 'Minh Thùy',
      'age': 19,
      'mbti': 'INTP',
      'match': 88,
      'avatar': '🎮',
      'game': 'Valorant',
      'lane': 'Khởi Tranh / Initiator',
      'bio': 'Chuyên cày sảnh tấu hài giải trí sau giờ học, voice chat ca hát',
      'interests': ['Valorant', 'FPS', 'Anime', 'Music'],
      'color': ThemeService.fuchsia,
    },
    {
      'name': 'Thùy Dung',
      'age': 21,
      'mbti': 'ENFP',
      'match': 92,
      'avatar': '👑',
      'game': 'LMHT',
      'lane': 'Đường Giữa / Mid',
      'bio': 'Chuyên solo Mid gank team, leo rank Kim Cương nghiêm túc!',
      'interests': ['LMHT', 'Solo Mid', 'Tryhard', 'Co-op'],
      'color': ThemeService.green,
    },
  ];

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
                // ── TOP HEADER FILTER BAR ──────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: ThemeService.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt, color: ThemeService.yellow, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'AI GỢI Ý ĐỒNG ĐỘI HỢP CẠ',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: ThemeService.accent,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Ẩn Avatar (Blind Profile)',
                            style: TextStyle(fontSize: 12, color: theme.textMuted, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _blindProfile,
                            activeColor: ThemeService.accent,
                            onChanged: (val) {
                              setState(() {
                                _blindProfile = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── PROFILE CARDS ──────────────────────────────────────
                ..._profiles.map((item) {
                  final Color color = item['color'] as Color;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: color.withOpacity(0.35), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── CARD HEADER: Cyber Banner ──────────────────
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(22),
                              topRight: Radius.circular(22),
                            ),
                            gradient: LinearGradient(
                              colors: [color.withOpacity(0.7), color.withOpacity(0.1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: _blindProfile
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: Colors.black26,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white30),
                                            ),
                                            child: const Icon(Icons.visibility_off, size: 40, color: Colors.white),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            '🔒 CHẾ ĐỘ BẢO MẬT BLIND PROFILE',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                                          ),
                                        ],
                                      )
                                    : Text(item['avatar'] as String, style: const TextStyle(fontSize: 72)),
                              ),
                              // Match % badge
                              Positioned(
                                top: 14,
                                right: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: ThemeService.yellow),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.electric_bolt, color: ThemeService.yellow, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item['match']}% AI HỢP CẠ',
                                        style: const TextStyle(color: ThemeService.yellow, fontSize: 12, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── CARD BODY ──────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + MBTI
                              Row(
                                children: [
                                  Text(
                                    '${item['name']}, ${item['age']}',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.textPrimary),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ThemeService.accent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: ThemeService.accent.withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      item['mbti'] as String,
                                      style: const TextStyle(color: ThemeService.accent, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Game + Lane
                              Row(
                                children: [
                                  Icon(Icons.sports_esports, color: ThemeService.cyan, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${item['game']} • Vị trí: ${item['lane']}',
                                    style: const TextStyle(color: ThemeService.cyan, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Bio
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.cardHigh,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.border),
                                ),
                                child: Text(
                                  '"${item['bio']}"',
                                  style: TextStyle(color: theme.textMuted, fontSize: 13, height: 1.4, fontStyle: FontStyle.italic),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Interest Tags
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: (item['interests'] as List<String>)
                                    .map((tag) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: color.withOpacity(0.25)),
                                          ),
                                          child: Text('#$tag', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 20),

                              // Action Button
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 4,
                                ),
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('BẮT CHUYỆN NGAY ➔', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatRoomScreen(
                                        teammateName: item['name'] as String,
                                        teammateAvatar: item['avatar'] as String,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
