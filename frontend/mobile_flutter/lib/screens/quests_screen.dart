import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/quest_model.dart';
import '../services/auth_service.dart';
import '../services/quest_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ui.dart';

/// Tab Nhiệm vụ: tiến độ hôm nay + nhiệm vụ ngày / tuần / mùa (GET api/quest).
/// Trang chủ tải danh sách lúc mở app, tab dưới tải lại mỗi lần mở, kéo xuống để tải lại.
class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quests = context.watch<QuestService>();
    final text = Theme.of(context).textTheme;
    final error = quests.error;

    Widget body;
    if (!quests.hasLoaded) {
      // Chưa có dữ liệu: đang tải / lỗi
      body = Center(
        child: error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: AppSpace.page,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpace.lg),
                    ElevatedButton(
                      onPressed: quests.isLoading ? null : () => quests.load(context.read<AuthService>()),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () => quests.load(context.read<AuthService>()),
        child: PageBody(
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
                  Text('Nhiệm vụ hằng ngày làm mới lúc 0h mỗi ngày', style: text.bodySmall),
                  const SizedBox(height: AppSpace.md),
                  _ProgressBar(value: quests.dailyProgress, height: 8),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xl),

            for (final (title, list) in [
              ('Nhiệm vụ hằng ngày', quests.dailyQuests),
              ('Nhiệm vụ tuần', quests.weeklyQuests),
              ('Nhiệm vụ mùa giải', quests.seasonalQuests),
            ])
              if (list.isNotEmpty) ...[
                SectionHeader(title),
                for (final quest in list) ...[
                  _QuestTile(quest: quest),
                  const SizedBox(height: AppSpace.md),
                ],
                const SizedBox(height: AppSpace.md),
              ],
          ],
        ),
      );
    }

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

class _ClaimButton extends StatefulWidget {
  final QuestModel quest;

  const _ClaimButton({required this.quest});

  @override
  State<_ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends State<_ClaimButton> {
  bool _claiming = false;

  Future<void> _claim() async {
    final quest = widget.quest;
    setState(() => _claiming = true);
    try {
      final message = await context.read<QuestService>().claim(quest, context.read<AuthService>());
      if (mounted) showSuccessSnack(context, '$message (+${quest.rewardCoins} Coins, +${quest.rewardExp} EXP)');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
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
        onPressed: _claiming ? null : _claim,
        child: _claiming
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Nhận quà'),
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
