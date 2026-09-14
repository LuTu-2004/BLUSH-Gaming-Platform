import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLUSH Dashboard'),
        backgroundColor: const Color(0xFF140E28),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Banner Card
            Card(
              color: const Color(0xFF140E28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF9D4EDD), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF00F5FF),
                      child: Text('🎮', style: TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Game thủ',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Level ${user?.level ?? 1} • MBTI: ${user?.mbti ?? "INFJ"}',
                            style: const TextStyle(color: Color(0xFF00F5FF)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Chip(
                                label: Text('🪙 ${user?.coins ?? 0} Coins'),
                                backgroundColor: Colors.black26,
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text('⚡ ${user?.exp ?? 0} EXP'),
                                backgroundColor: Colors.black26,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '🎮 Phân khu Sảnh đấu gợi ý (Zones)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildZoneCard('Sảnh Tấu Hài Liên Quân', 'Liên Quân Mobile', '512 online', Colors.cyan),
            _buildZoneCard('Chúa Tryhard Leo Rank Valorant', 'Valorant', '384 online', Colors.purple),
            _buildZoneCard('Sảnh VIP Pro-Player Mentors', 'LMHT', 'VIP Only 🔒', Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneCard(String title, String game, String status, Color accentColor) {
    return Card(
      color: const Color(0xFF182C3D),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accentColor.withOpacity(0.2),
          child: Icon(Icons.gamepad, color: accentColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(game),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: accentColor),
          onPressed: () {},
          child: const Text('VÀO ZONE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
