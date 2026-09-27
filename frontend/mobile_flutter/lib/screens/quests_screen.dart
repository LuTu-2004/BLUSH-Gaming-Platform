import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../models/zone_model.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  final List<QuestModel> _dailyQuests = [
    QuestModel(id: 1, title: 'Ghép đội 1 lần', desc: 'Sử dụng AI Matching để tìm đồng đội hợp cạ', current: 1, target: 1, rewardCoins: 10, rewardExp: 25, isDone: true, isClaimed: true),
    QuestModel(id: 2, title: 'Đăng 1 bài trên Feed', desc: 'Chia sẻ chiến tích hoặc chiến thuật trên phân khu', current: 0, target: 1, rewardCoins: 15, rewardExp: 30, isDone: false),
    QuestModel(id: 3, title: 'Like 5 bài viết', desc: 'Tương tác xây dựng cộng đồng game thủ sôi nổi', current: 3, target: 5, rewardCoins: 5, rewardExp: 15, isDone: false),
    QuestModel(id: 4, title: 'Chơi 3 trận cùng nhóm BLUSH', desc: 'Vào trận cùng đồng đội từ sảnh đấu BLUSH', current: 3, target: 3, rewardCoins: 20, rewardExp: 50, isDone: true, isClaimed: false),
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
                // Daily Progress Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ThemeService.green.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeService.green.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      )
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
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: ThemeService.green.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Text('🎁', style: TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tiến độ nhiệm vụ hôm nay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimary)),
                                  const SizedBox(height: 2),
                                  const Text('Hoàn thành tất cả để nhận x2 Bonus Coins!', style: TextStyle(fontSize: 12, color: ThemeService.green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: ThemeService.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: ThemeService.green.withOpacity(0.4)),
                            ),
                            child: const Text('2/4 Hoàn thành', style: TextStyle(color: ThemeService.green, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const LinearProgressIndicator(
                          value: 0.5,
                          minHeight: 12,
                          backgroundColor: Colors.black26,
                          color: ThemeService.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Text('⏱️ NHIỆM VỤ HÀNG NGÀY GUILD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.textPrimary)),
                const SizedBox(height: 14),

                // Quests List
                ..._dailyQuests.map((quest) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: quest.isClaimed
                            ? theme.surface
                            : quest.isDone
                                ? ThemeService.green.withOpacity(0.5)
                                : ThemeService.blurple.withOpacity(0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(quest.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text(quest.desc, style: TextStyle(fontSize: 12, color: theme.textMuted)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: quest.isClaimed
                                    ? theme.header
                                    : quest.isDone
                                        ? ThemeService.green
                                        : ThemeService.blurple.withOpacity(0.2),
                                foregroundColor: quest.isDone && !quest.isClaimed ? Colors.black : theme.textMuted,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: Icon(
                                quest.isClaimed ? Icons.check : quest.isDone ? Icons.card_giftcard : Icons.hourglass_top,
                                size: 16,
                              ),
                              onPressed: quest.isDone && !quest.isClaimed
                                  ? () {
                                      setState(() {
                                        quest.isClaimed = true;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Đã nhận +${quest.rewardCoins} Coins & +${quest.rewardExp} EXP! 🎉')),
                                      );
                                    }
                                  : null,
                              label: Text(quest.isClaimed ? 'Đã Nhận' : quest.isDone ? 'Nhận Quà' : 'Chưa Xong', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: ThemeService.yellow.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ThemeService.yellow.withOpacity(0.3)),
                              ),
                              child: Text('🪙 +${quest.rewardCoins} Coins', style: const TextStyle(color: ThemeService.yellow, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: ThemeService.blurple.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ThemeService.blurple.withOpacity(0.3)),
                              ),
                              child: Text('⚡ +${quest.rewardExp} EXP', style: const TextStyle(color: ThemeService.blurple, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
