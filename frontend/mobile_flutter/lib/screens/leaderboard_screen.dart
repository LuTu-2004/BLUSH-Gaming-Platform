import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'chat_room_screen.dart';

/// Tab Xếp hạng: top game thủ theo EXP, lọc theo khu vực và tựa game.
/// TODO: lấy dữ liệu thật từ backend khi có API bảng xếp hạng.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _RankedGamer {
  final String name;
  final String mbti;
  final int exp;
  final String avatar;
  final String region; // 'HCM' | 'HN'
  final String game;

  const _RankedGamer(this.name, this.mbti, this.exp, this.avatar, this.region, this.game);

  int get level => exp ~/ 100 + 1; // cùng công thức với cột CurrentLevel trong DB
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const _regions = {'Toàn quốc': null, 'TP.HCM': 'HCM', 'Hà Nội': 'HN'};
  static const _games = ['Tất cả', 'Liên Quân Mobile', 'Valorant', 'LMHT', 'DTCL'];

  // EXP mẫu hợp lý với công thức Level = EXP / 100 + 1 (VD: 4150 EXP = Lv.42)
  static const _gamers = [
    _RankedGamer('Kuro_Ace', 'INTJ', 4150, '👑', 'HCM', 'Valorant'),
    _RankedGamer('LinhDan', 'ENFP', 3820, '🌸', 'HN', 'Liên Quân Mobile'),
    _RankedGamer('MinhShadow', 'ISTP', 3560, '⚔️', 'HCM', 'LMHT'),
    _RankedGamer('BaoBao_TFT', 'INTP', 3310, '🎮', 'HN', 'DTCL'),
    _RankedGamer('Zeref_Carry', 'ENTJ', 3050, '⚡', 'HCM', 'LMHT'),
    _RankedGamer('MeoMeo_SP', 'ISFJ', 2890, '🐱', 'HN', 'Liên Quân Mobile'),
    _RankedGamer('HaiDang_Mid', 'ENTP', 2640, '🔥', 'HCM', 'Liên Quân Mobile'),
    _RankedGamer('VyVy_Sniper', 'INFJ', 2480, '🎯', 'HN', 'Valorant'),
  ];

  String _region = 'Toàn quốc';
  String _game = 'Tất cả';

  List<_RankedGamer> get _filtered {
    final regionCode = _regions[_region];
    return _gamers.where((g) => (regionCode == null || g.region == regionCode) && (_game == 'Tất cả' || g.game == _game)).toList()..sort((a, b) => b.exp.compareTo(a.exp));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final user = context.watch<AuthService>().currentUser;
    final list = _filtered;
    // Hạng của bạn = số người có EXP cao hơn + 1 (trong danh sách đang lọc)
    final myExp = user?.exp ?? 0;
    final myRank = list.where((g) => g.exp > myExp).length + 1;

    return PageBody(
      children: [
        Text('Bảng xếp hạng', style: text.headlineSmall),
        const SizedBox(height: AppSpace.xs),
        Text('Mùa 3 · Top game thủ nhiều EXP nhất', style: text.bodySmall),
        const SizedBox(height: AppSpace.lg),
        _ChipRow(options: _regions.keys.toList(), selected: _region, onSelected: (v) => setState(() => _region = v)),
        const SizedBox(height: AppSpace.sm),
        _ChipRow(options: _games, selected: _game, onSelected: (v) => setState(() => _game = v)),
        const SizedBox(height: AppSpace.lg),

        // Vị trí của bạn: đặt trên cùng, không đè lên danh sách
        if (user != null)
          AppCard(
            borderColor: ThemeService.accent,
            child: Row(
              children: [
                Text('#$myRank', style: text.titleLarge),
                const SizedBox(width: AppSpace.md),
                AppAvatar(imageUrl: user.avatarUrl, fallback: user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?', size: 40),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bạn', style: text.titleSmall),
                      Text('Lv.${user.level} · ${user.exp} EXP', style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpace.xl),

        if (list.isEmpty)
          AppCard(child: Text('Chưa có dữ liệu cho bộ lọc này.', style: text.bodySmall, textAlign: TextAlign.center))
        else ...[
          if (list.length >= 3) ...[
            _Podium(top3: list.take(3).toList(), onTap: _showGamer),
            const SizedBox(height: AppSpace.xl),
          ],
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = list.length >= 3 ? 3 : 0; i < list.length; i++) _RankTile(rank: i + 1, gamer: list[i], onTap: () => _showGamer(list[i])),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showGamer(_RankedGamer g) {
    final text = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 36, child: Text(g.avatar, style: const TextStyle(fontSize: 36))),
            const SizedBox(height: AppSpace.md),
            Text(g.name, style: text.titleLarge),
            const SizedBox(height: AppSpace.xs),
            Text('${g.mbti} · Lv.${g.level} · ${g.game}', style: text.bodySmall),
            const SizedBox(height: AppSpace.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Nhắn tin'),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(teammateName: g.name, teammateAvatar: g.avatar)));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ChipRow({required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (_, i) => ChoiceChip(label: Text(options[i]), selected: options[i] == selected, onSelected: (_) => onSelected(options[i])),
      ),
    );
  }
}

/// Bục top 3: hạng 1 ở giữa và cao hơn
class _Podium extends StatelessWidget {
  final List<_RankedGamer> top3;
  final ValueChanged<_RankedGamer> onTap;

  const _Podium({required this.top3, required this.onTap});

  static const _medal = [Color(0xFFFFC700), Color(0xFFC0C7D1), Color(0xFFCD8B5A)]; // vàng, bạc, đồng

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _item(context, 1, top3[1], 0)),
        const SizedBox(width: AppSpace.sm),
        Expanded(child: _item(context, 0, top3[0], AppSpace.xl)),
        const SizedBox(width: AppSpace.sm),
        Expanded(child: _item(context, 2, top3[2], 0)),
      ],
    );
  }

  Widget _item(BuildContext context, int index, _RankedGamer g, double extraHeight) {
    final text = Theme.of(context).textTheme;
    final t = context.watch<ThemeService>();
    return AppCard(
      onTap: () => onTap(g),
      borderColor: _medal[index].withValues(alpha: 0.7),
      padding: EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.lg + extraHeight, AppSpace.sm, AppSpace.lg),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(radius: 26, backgroundColor: t.cardHigh, child: Text(g.avatar, style: const TextStyle(fontSize: 26))),
              Positioned(
                right: -4,
                bottom: -4,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: _medal[index],
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(g.name, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(_fmt(g.exp), style: text.labelLarge?.copyWith(color: _medal[index])),
          Text('EXP', style: text.labelSmall),
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  final int rank;
  final _RankedGamer gamer;
  final VoidCallback onTap;

  const _RankTile({required this.rank, required this.gamer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 72,
        child: Row(
          children: [
            SizedBox(width: 24, child: Text('$rank', style: text.titleSmall?.copyWith(color: t.textMuted))),
            const SizedBox(width: AppSpace.sm),
            CircleAvatar(radius: 20, backgroundColor: t.cardHigh, child: Text(gamer.avatar, style: const TextStyle(fontSize: 18))),
          ],
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(gamer.name, style: text.titleSmall, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpace.sm),
          TagChip(gamer.mbti),
        ],
      ),
      subtitle: Text('Lv.${gamer.level} · ${gamer.game}', style: text.bodySmall),
      trailing: Text('${_fmt(gamer.exp)} EXP', style: text.labelLarge),
    );
  }
}

String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
