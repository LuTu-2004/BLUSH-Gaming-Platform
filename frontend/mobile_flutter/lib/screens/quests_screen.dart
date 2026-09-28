import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quest_model.dart';
import '../services/auth_service.dart';
import '../services/quest_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ui.dart';

/// Tab Nhiệm vụ: tiến độ hôm nay + danh sách nhiệm vụ hằng ngày.
class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quests = context.watch<QuestService>();
    final text = Theme.of(context).textTheme;

    final body = PageBody(
      children: [
        // ── Tiến độ hôm nay ─────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Tiến độ hôm nay', style: text.titleMedium)),
                  Text('${quests.completedCount}/${quests.totalCount}', style: text.titleMedium),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              Text('Hoàn thành tất cả để nhận x2 Coins thưởng', style: text.bodySmall),
              const SizedBox(height: AppSpace.md),
              _ProgressBar(value: quests.dailyProgress, height: 8),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),

        const SectionHeader('Nhiệm vụ hằng ngày'),
        for (final quest in quests.dailyQuests) ...[
          _QuestTile(quest: quest),
          const SizedBox(height: AppSpace.md),
        ],
      ],
    );

    // Có AppBar (nút quay lại) khi được mở từ Trang chủ; ở tab dưới thì không cần
    return Navigator.canPop(context) ? Scaffold(appBar: AppBar(title: const Text('Nhiệm vụ')), body: body) : body;
  }
}

class _QuestTile extends StatelessWidget {
  final QuestModel quest;

  const _QuestTile({required this.quest});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final canClaim = quest.isDone && !quest.isClaimed;

    return AppCard(
      borderColor: canClaim ? ThemeService.accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quest.title, style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(quest.desc, style: text.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              _ClaimButton(quest: quest),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(child: _ProgressBar(value: quest.progress)),
              const SizedBox(width: AppSpace.sm),
              Text('${quest.current}/${quest.target}', style: text.labelMedium),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              TagChip('+${quest.rewardCoins} Coins', color: ThemeService.yellow, icon: Icons.monetization_on),
              const SizedBox(width: AppSpace.sm),
              TagChip('+${quest.rewardExp} EXP', color: t.isDark ? ThemeService.accentLight : ThemeService.accent, icon: Icons.bolt),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  final QuestModel quest;

  const _ClaimButton({required this.quest});

  @override
  Widget build(BuildContext context) {
    if (quest.isClaimed) {
      return const TagChip('Đã nhận', color: ThemeService.green, icon: Icons.check);
    }
    if (!quest.isDone) {
      return const TagChip('Đang làm');
    }
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36)),
        onPressed: () {
          context.read<QuestService>().claim(quest, context.read<AuthService>());
          showSuccessSnack(context, 'Đã nhận +${quest.rewardCoins} Coins và +${quest.rewardExp} EXP');
        },
        child: const Text('Nhận quà'),
      ),
    );
  }
}

/// Thanh tiến độ dùng chung 1 màu cho mọi nhiệm vụ
class _ProgressBar extends StatelessWidget {
  final double value;
  final double height;

  const _ProgressBar({required this.value, this.height = 6});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(value: value, minHeight: height, backgroundColor: t.cardHigh, color: ThemeService.accent),
    );
  }
}
