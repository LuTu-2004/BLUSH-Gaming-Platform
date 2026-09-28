import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../services/auth_service.dart';
import '../services/quest_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ui.dart';
import 'chat_room_screen.dart';
import 'vip_screen.dart';

/// Tab Trang chủ: lời chào, chỉ số, điểm danh + nhiệm vụ hôm nay, người chơi đang tìm đồng đội.
class DashboardScreen extends StatefulWidget {
  /// Chuyển sang tab khác (0 Trang chủ, 1 Đồng đội, 2 Xếp hạng, 3 Nhiệm vụ, 4 Hồ sơ)
  final ValueChanged<int>? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _LobbyGamer {
  final String avatar;
  final String name;
  final String mbti;
  final String game;
  final String purpose;
  final int match;
  final bool online;

  const _LobbyGamer(this.avatar, this.name, this.mbti, this.game, this.purpose, this.match, this.online);
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _games = ['Tất cả', 'Liên Quân Mobile', 'Valorant', 'LMHT', 'DTCL', 'PUBG Mobile', 'Free Fire'];

  // TODO: lấy từ backend khi có API sảnh chờ / ghép đội
  static const _lobby = [
    _LobbyGamer('🌸', 'Khánh Linh', 'ENFP', 'Liên Quân Mobile', 'Hội Tấu Hài', 94, true),
    _LobbyGamer('👑', 'Thùy Dung', 'ENFP', 'LMHT', 'Chill & học hỏi', 92, true),
    _LobbyGamer('💥', 'Bảo Nam', 'ESTP', 'PUBG Mobile', 'Săn Booyah', 89, true),
    _LobbyGamer('⚔️', 'Minh Thùy', 'INTP', 'Valorant', 'Chúa Tryhard', 88, true),
    _LobbyGamer('🔥', 'Hoàng Yến', 'ESFP', 'Free Fire', 'Hội Tấu Hài', 86, true),
    _LobbyGamer('🎯', 'Hùng Dũng', 'ISTJ', 'DTCL', 'Leo rank nghiêm túc', 81, false),
  ];

  String _selectedGame = 'Tất cả';
  bool _checkingIn = false;

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

    final lobby = _selectedGame == 'Tất cả' ? _lobby : _lobby.where((g) => g.game == _selectedGame).toList();
    final onlineCount = _lobby.where((g) => g.online).length;

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
              // Wrap: màn hình hẹp thì dòng "đang online" tự xuống hàng thay vì bị tràn
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, size: 10, color: ThemeService.green),
                      const SizedBox(width: AppSpace.xs),
                      Text('$onlineCount đang online', style: text.bodySmall?.copyWith(color: Colors.white70)),
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

        // ── Đang tìm đồng đội ───────────────────────────────────
        const SectionHeader('Đang tìm đồng đội'),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _games.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpace.sm),
            itemBuilder: (_, i) {
              final game = _games[i];
              return ChoiceChip(
                label: Text(game),
                selected: game == _selectedGame,
                onSelected: (_) => setState(() => _selectedGame = game),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpace.md),
        if (lobby.isEmpty)
          AppCard(child: Text('Chưa có ai đang tìm đồng đội cho $_selectedGame.', style: text.bodySmall, textAlign: TextAlign.center))
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < lobby.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 72, color: t.border),
                  _LobbyTile(gamer: lobby[i]),
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

class _LobbyTile extends StatelessWidget {
  final _LobbyGamer gamer;

  const _LobbyTile({required this.gamer});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs),
      leading: Stack(
        children: [
          CircleAvatar(radius: 22, backgroundColor: t.cardHigh, child: Text(gamer.avatar, style: const TextStyle(fontSize: 20))),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: gamer.online ? ThemeService.green : t.textMuted,
                shape: BoxShape.circle,
                border: Border.all(color: t.card, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Flexible(child: Text(gamer.name, style: text.titleSmall, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpace.sm),
          TagChip(gamer.mbti),
        ],
      ),
      subtitle: Text('${gamer.game} · ${gamer.purpose}', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${gamer.match}%', style: text.labelLarge?.copyWith(color: ThemeService.green)),
          IconButton(
            tooltip: 'Nhắn tin',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatRoomScreen(teammateName: gamer.name, teammateAvatar: gamer.avatar)),
            ),
          ),
        ],
      ),
    );
  }
}
