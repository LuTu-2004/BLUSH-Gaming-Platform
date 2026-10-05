import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/match_model.dart';
import '../services/auth_service.dart';
import '../services/match_service.dart';
import '../services/quest_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ui.dart';
import 'chat_room_screen.dart';
import 'vip_screen.dart';

/// Tab Trang chủ: lời chào, chỉ số, điểm danh + nhiệm vụ hôm nay, người chơi hợp với bạn nhất.
class DashboardScreen extends StatefulWidget {
  /// Chuyển sang tab khác (0 Trang chủ, 1 Đồng đội, 2 Xếp hạng, 3 Nhiệm vụ, 4 Hồ sơ)
  final ValueChanged<int>? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Số người gợi ý hiện ở Trang chủ (xem đủ ở tab Đồng đội)
  static const _topMatchCount = 5;

  List<MatchSuggestion>? _topMatches;
  ApiException? _matchError;
  bool _checkingIn = false;

  @override
  void initState() {
    super.initState();
    _loadTopMatches();
  }

  Future<void> _loadTopMatches() async {
    setState(() => _matchError = null);
    try {
      final list = await MatchService(context.read<AuthService>()).getSuggestions(limit: _topMatchCount);
      if (mounted) setState(() => _topMatches = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _matchError = e);
    }
  }

  Future<void> _checkIn() async {
    setState(() => _checkingIn = true);
    try {
      final message = await context.read<QuestService>().checkIn(context.read<AuthService>());
      if (mounted) showSuccessSnack(context, '$message (+${QuestService.checkInCoins} Coins, +${QuestService.checkInExp} EXP)');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final user = context.watch<AuthService>().currentUser;
    final quests = context.watch<QuestService>();
    final text = Theme.of(context).textTheme;
    if (user == null) return const SizedBox.shrink();

    final topMatches = _topMatches;

    return PageBody(
      children: [
        // ── Lời chào ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpace.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: LinearGradient(
              colors: t.isDark ? const [Color(0xFF2A1452), Color(0xFF1B1B23)] : const [Color(0xFF7C3AED), Color(0xFF9F67FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chào, ${user.displayName} 👋', style: text.headlineSmall?.copyWith(color: Colors.white)),
              const SizedBox(height: AppSpace.xs),
              Text(
                [if (user.mbti.isNotEmpty) user.mbti, 'Level ${user.level}', if (user.age != null) '${user.age} tuổi'].join(' · '),
                style: text.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: AppSpace.lg),
              // Wrap: màn hình hẹp thì dòng "hợp với bạn" tự xuống hàng thay vì bị tràn
              Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: ThemeService.accent),
                    icon: const Icon(Icons.radar, size: 18),
                    label: const Text('Tìm đồng đội'),
                    onPressed: () => widget.onNavigate?.call(1),
                  ),
                  if (topMatches != null && topMatches.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 10, color: ThemeService.green),
                        const SizedBox(width: AppSpace.xs),
                        Text('Hợp nhất: ${topMatches.first.score}%', style: text.bodySmall?.copyWith(color: Colors.white70)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),

        // ── Chỉ số ──────────────────────────────────────────────
        Row(
          children: [
            Expanded(child: StatTile(icon: Icons.monetization_on, color: ThemeService.yellow, value: '${user.coins}', label: 'Coins')),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: StatTile(icon: Icons.bolt, color: t.isDark ? ThemeService.accentLight : ThemeService.accent, value: '${user.exp}', label: 'EXP')),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: StatTile(icon: Icons.shield_outlined, color: ThemeService.green, value: 'Lv.${user.level}', label: 'Level')),
          ],
        ),
        const SizedBox(height: AppSpace.xl),

        // ── Hôm nay: điểm danh + tiến độ nhiệm vụ ────────────────
        SectionHeader('Hôm nay', actionLabel: 'Xem nhiệm vụ', onAction: () => widget.onNavigate?.call(3)),
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.event_available, color: ThemeService.accent),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Điểm danh hằng ngày', style: text.titleSmall),
                        Text('+${QuestService.checkInCoins} Coins, +${QuestService.checkInExp} EXP', style: text.bodySmall),
                      ],
                    ),
                  ),
                  user.checkedInToday
                      ? const TagChip('Đã nhận', color: ThemeService.green, icon: Icons.check)
                      : SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36)),
                            onPressed: _checkingIn ? null : _checkIn,
                            child: const Text('Nhận'),
                          ),
                        ),
                ],
              ),
              Divider(height: AppSpace.xl, color: t.border),
              Row(
                children: [
                  Text('Nhiệm vụ', style: text.bodySmall),
                  const Spacer(),
                  Text('${quests.completedCount}/${quests.totalCount} hoàn thành', style: text.labelMedium),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(value: quests.dailyProgress, minHeight: 6, backgroundColor: t.cardHigh, color: ThemeService.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),

        // ── Hợp với bạn nhất (từ api/match/suggestions) ──────────
        SectionHeader('Hợp với bạn nhất', actionLabel: 'Xem tất cả', onAction: () => widget.onNavigate?.call(1)),
        if (_matchError != null)
          AppCard(
            onTap: _loadTopMatches,
            child: Text(
              _matchError!.code == 'ONBOARDING_REQUIRED' ? 'Làm khảo sát sở thích chơi game để nhận gợi ý đồng đội.' : '${_matchError!.message} Chạm để thử lại.',
              style: text.bodySmall,
              textAlign: TextAlign.center,
            ),
          )
        else if (topMatches == null)
          const Padding(padding: EdgeInsets.all(AppSpace.lg), child: Center(child: CircularProgressIndicator()))
        else if (topMatches.isEmpty)
          AppCard(child: Text('Chưa có ai phù hợp. Thử thêm game hoặc khung giờ trong Hồ sơ nhé.', style: text.bodySmall, textAlign: TextAlign.center))
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < topMatches.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 72, color: t.border),
                  _MatchTile(gamer: topMatches[i]),
                ],
              ],
            ),
          ),

        // ── VIP (chỉ hiện khi chưa là VIP) ──────────────────────
        if (!user.isVip) ...[
          const SizedBox(height: AppSpace.xl),
          AppCard(
            borderColor: ThemeService.yellow.withValues(alpha: 0.6),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VipScreen())),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium, color: ThemeService.yellow, size: 32),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nâng cấp BLUSH Pass', style: text.titleSmall),
                      Text('AI không giới hạn, ưu tiên ghép đội, từ 29K/tháng', style: text.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: t.textMuted),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  final MatchSuggestion gamer;

  const _MatchTile({required this.gamer});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs),
      leading: CircleAvatar(radius: 22, backgroundColor: t.cardHigh, child: Text(gamer.avatarEmoji, style: const TextStyle(fontSize: 20))),
      title: Row(
        children: [
          Flexible(child: Text(gamer.displayName, style: text.titleSmall, overflow: TextOverflow.ellipsis)),
          if (gamer.mbti.isNotEmpty) ...[const SizedBox(width: AppSpace.sm), TagChip(gamer.mbti)],
        ],
      ),
      subtitle: Text(gamer.gameLine, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${gamer.score}%', style: text.labelLarge?.copyWith(color: ThemeService.green)),
          IconButton(
            tooltip: 'Nhắn tin',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatRoomScreen(teammateName: gamer.displayName, teammateAvatar: gamer.avatarEmoji)),
            ),
          ),
        ],
      ),
    );
  }
}
