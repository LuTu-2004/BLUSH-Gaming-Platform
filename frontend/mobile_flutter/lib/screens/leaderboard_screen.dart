import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/leaderboard_model.dart';
import '../models/onboarding_model.dart';
import '../services/auth_service.dart';
import '../services/match_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'chat_room_screen.dart';

/// Tab Xếp hạng: top game thủ theo EXP (GET api/leaderboard), lọc theo khu vực và tựa game.
/// Danh sách khu vực / game lấy từ GET api/onboarding/options. Kéo xuống để tải lại.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final MatchService _service = MatchService(context.read<AuthService>());

  OnboardingOptions? _options;
  Leaderboard? _board;
  String? _error;
  String? _region; // null = toàn quốc
  int? _gameId; // null = mọi game
  int _requestId = 0; // đổi bộ lọc liên tục: chỉ nhận kết quả của lần gọi mới nhất

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() => _error = null);
    try {
      final options = _options ?? await _service.getOptions();
      final board = await _service.getLeaderboard(region: _region, gameId: _gameId);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _options = options;
        _board = board;
      });
    } on ApiException catch (e) {
      if (mounted && requestId == _requestId) setState(() => _error = e.message);
    }
  }

  void _setFilter({String? region, int? gameId}) {
    setState(() {
      _region = region;
      _gameId = gameId;
      _board = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final options = _options;
    final board = _board;
    final error = _error;

    return RefreshIndicator(
      onRefresh: _load,
      child: PageBody(
        children: [
          Text('Bảng xếp hạng', style: text.headlineSmall),
          const SizedBox(height: AppSpace.xs),
          Text('Top game thủ nhiều EXP nhất', style: text.bodySmall),
          const SizedBox(height: AppSpace.lg),
          if (options != null) ...[
            _ChipRow<String?>(
              options: [(null, 'Toàn quốc'), for (final r in options.regions) (r.code, r.label)],
              selected: _region,
              onSelected: (v) => _setFilter(region: v, gameId: _gameId),
            ),
            const SizedBox(height: AppSpace.sm),
            _ChipRow<int?>(
              options: [(null, 'Tất cả'), for (final g in options.games) (g.id, g.name)],
              selected: _gameId,
              onSelected: (v) => _setFilter(region: _region, gameId: v),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          if (error != null)
            AppCard(
              onTap: _load,
              child: Text('$error Chạm để thử lại.', style: text.bodySmall, textAlign: TextAlign.center),
            )
          else if (board == null)
            const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator()))
          else ...[
            _MyRankCard(me: board.me),
            const SizedBox(height: AppSpace.xl),
            if (board.items.isEmpty)
              AppCard(child: Text('Chưa có dữ liệu cho bộ lọc này.', style: text.bodySmall, textAlign: TextAlign.center))
            else ...[
              if (board.items.length >= 3) ...[
                _Podium(top3: board.items.take(3).toList(), onTap: _showGamer),
                const SizedBox(height: AppSpace.xl),
              ],
              if (board.items.length != 3)
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final g in board.items.skip(board.items.length >= 3 ? 3 : 0)) _RankTile(gamer: g, onTap: () => _showGamer(g)),
                    ],
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  void _showGamer(LeaderboardEntry g) {
    final text = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar(imageUrl: g.avatarUrl, fallback: g.avatarEmoji, size: 72),
            const SizedBox(height: AppSpace.md),
            Text(g.displayName, style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.xs),
            Text(_details(g), style: text.bodySmall, textAlign: TextAlign.center),
            if (!g.isMe) ...[
              const SizedBox(height: AppSpace.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Nhắn tin'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(teammateName: g.displayName, teammateAvatar: g.avatarEmoji)));
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _details(LeaderboardEntry g) => [
      if (g.mbti != null) g.mbti!,
      'Lv.${g.level}',
      if (g.gameName != null) g.gameName!,
    ].join(' · ');

class _ChipRow<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const _ChipRow({required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (_, i) {
          final (value, label) = options[i];
          return ChoiceChip(label: Text(label), selected: value == selected, onSelected: (_) => onSelected(value));
        },
      ),
    );
  }
}

/// Vị trí của bạn: đặt trên cùng, không đè lên danh sách
class _MyRankCard extends StatelessWidget {
  final LeaderboardEntry? me;

  const _MyRankCard({required this.me});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final me = this.me;
    if (me == null) {
      return AppCard(
        child: Text(
          'Bạn chưa có hạng trong bảng này. Chỉ tính game thủ đã tạo hồ sơ chơi game, đúng khu vực và game đang lọc.',
          style: text.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }
    return AppCard(
      borderColor: ThemeService.accent,
      child: Row(
        children: [
          Text('#${me.rank}', style: text.titleLarge),
          const SizedBox(width: AppSpace.md),
          AppAvatar(imageUrl: me.avatarUrl, fallback: me.avatarEmoji, size: 40),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bạn', style: text.titleSmall),
                Text('Lv.${me.level} · ${me.exp} EXP', style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bục top 3: hạng 1 ở giữa và cao hơn
class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  final ValueChanged<LeaderboardEntry> onTap;

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

  Widget _item(BuildContext context, int index, LeaderboardEntry g, double extraHeight) {
    final text = Theme.of(context).textTheme;
    // Màu huy chương theo hạng thật (bằng EXP thì cùng hạng, cùng màu)
    final medal = _medal[(g.rank - 1).clamp(0, 2)];
    return AppCard(
      onTap: () => onTap(g),
      borderColor: g.isMe ? ThemeService.accent : medal.withValues(alpha: 0.7),
      padding: EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.lg + extraHeight, AppSpace.sm, AppSpace.lg),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(imageUrl: g.avatarUrl, fallback: g.avatarEmoji, size: 52),
              Positioned(
                right: -4,
                bottom: -4,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: medal,
                  child: Text('${g.rank}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(g.displayName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(_fmt(g.exp), style: text.labelLarge?.copyWith(color: medal)),
          Text('EXP', style: text.labelSmall),
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  final LeaderboardEntry gamer;
  final VoidCallback onTap;

  const _RankTile({required this.gamer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final mbti = gamer.mbti;
    return ListTile(
      onTap: onTap,
      tileColor: gamer.isMe ? ThemeService.accent.withValues(alpha: 0.08) : null,
      leading: SizedBox(
        width: 76,
        child: Row(
          children: [
            SizedBox(width: 28, child: Text('${gamer.rank}', style: text.titleSmall?.copyWith(color: t.textMuted))),
            const SizedBox(width: AppSpace.sm),
            AppAvatar(imageUrl: gamer.avatarUrl, fallback: gamer.avatarEmoji, size: 40),
          ],
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(gamer.isMe ? '${gamer.displayName} (bạn)' : gamer.displayName, style: text.titleSmall, overflow: TextOverflow.ellipsis)),
          if (mbti != null) ...[
            const SizedBox(width: AppSpace.sm),
            TagChip(mbti),
          ],
        ],
      ),
      subtitle: Text(['Lv.${gamer.level}', if (gamer.gameName != null) gamer.gameName!].join(' · '), style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text('${_fmt(gamer.exp)} EXP', style: text.labelLarge),
    );
  }
}

String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
