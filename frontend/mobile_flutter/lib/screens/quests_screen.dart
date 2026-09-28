import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/quest_service.dart';
import '../services/theme_service.dart';

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final quests = context.watch<QuestService>();

    return Scaffold(
      backgroundColor: theme.bg,
      // Có AppBar (nút back) khi được mở từ Dashboard; ở tab dưới thì không cần
      appBar: Navigator.canPop(context) ? AppBar(title: const Text('Nhiệm Vụ'), backgroundColor: theme.header, elevation: 0) : null,
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
                    border: Border.all(color: ThemeService.green.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeService.green.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: ThemeService.green.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text('🎁', style: TextStyle(fontSize: 22)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Tiến độ nhiệm vụ hôm nay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimary)),
                                      const SizedBox(height: 2),
                                      const Text('Hoàn thành tất cả để nhận x2 Bonus Coins!', style: TextStyle(fontSize: 12, color: ThemeService.green, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: ThemeService.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: ThemeService.green.withValues(alpha: 0.4)),
                            ),
                            child: Text('${quests.completedCount}/${quests.totalCount} Hoàn thành', style: const TextStyle(color: ThemeService.green, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: quests.dailyProgress,
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
                ...quests.dailyQuests.map((quest) {
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
                                ? ThemeService.green.withValues(alpha: 0.5)
                                : ThemeService.blurple.withValues(alpha: 0.3),
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
                                        : ThemeService.blurple.withValues(alpha: 0.2),
                                foregroundColor: quest.isDone && !quest.isClaimed ? Colors.black : theme.textMuted,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: Icon(
                                quest.isClaimed
                                    ? Icons.check
                                    : quest.isDone
                                        ? Icons.card_giftcard
                                        : Icons.hourglass_top,
                                size: 16,
                              ),
                              onPressed: quest.isDone && !quest.isClaimed
                                  ? () {
                                      quests.claim(quest, context.read<AuthService>());
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Đã nhận +${quest.rewardCoins} Coins & +${quest.rewardExp} EXP! 🎉')),
                                      );
                                    }
                                  : null,
                              label: Text(
                                  quest.isClaimed
                                      ? 'Đã Nhận'
                                      : quest.isDone
                                          ? 'Nhận Quà'
                                          : 'Chưa Xong',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Thanh tiến trình từng nhiệm vụ (VD: 3/5 = 60%)
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: quest.progress,
                                  minHeight: 6,
                                  backgroundColor: Colors.black26,
                                  color: quest.isDone ? ThemeService.green : ThemeService.blurple,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('${quest.current}/${quest.target}', style: TextStyle(color: theme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: ThemeService.yellow.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ThemeService.yellow.withValues(alpha: 0.3)),
                              ),
                              child: Text('🪙 +${quest.rewardCoins} Coins', style: const TextStyle(color: ThemeService.yellow, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: ThemeService.blurple.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ThemeService.blurple.withValues(alpha: 0.3)),
                              ),
                              child: Text('⚡ +${quest.rewardExp} EXP', style: const TextStyle(color: ThemeService.blurple, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
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
