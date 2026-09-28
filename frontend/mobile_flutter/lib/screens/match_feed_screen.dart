import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'chat_room_screen.dart';

/// Tab Đồng đội: AI gợi ý người chơi hợp cạ.
/// TODO: lấy danh sách từ backend khi có API ghép đội (bước 3-4).
class MatchFeedScreen extends StatefulWidget {
  const MatchFeedScreen({super.key});

  @override
  State<MatchFeedScreen> createState() => _MatchFeedScreenState();
}

class _Gamer {
  final String name;
  final int age;
  final String mbti;
  final int match; // % hợp cạ
  final String avatar;
  final String game;
  final String position;
  final String bio;
  final List<String> tags;

  const _Gamer(this.name, this.age, this.mbti, this.match, this.avatar, this.game, this.position, this.bio, this.tags);
}

class _MatchFeedScreenState extends State<MatchFeedScreen> {
  bool _blindProfile = true;

  static const _gamers = [
    _Gamer('Khánh Linh', 20, 'ENFP', 94, '🌸', 'Liên Quân Mobile', 'Trợ thủ', 'Tìm đồng đội Mid/AD leo rank Cao Thủ nghiêm túc, mic rõ, không toxic.', ['Tryhard', 'Voice chat', 'K-Pop']),
    _Gamer('Thùy Dung', 21, 'ENFP', 92, '👑', 'LMHT', 'Đường giữa', 'Chuyên solo Mid, đang leo Kim Cương.', ['Solo Mid', 'Tryhard', 'Co-op']),
    _Gamer('Minh Thùy', 19, 'INTP', 88, '🎮', 'Valorant', 'Initiator', 'Cày sảnh giải trí sau giờ học, thích voice chat ca hát.', ['FPS', 'Anime', 'Âm nhạc']),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Text('Gợi ý cho bạn', style: text.headlineSmall),
        const SizedBox(height: AppSpace.xs),
        Text('AI chọn theo MBTI, game và lối chơi của bạn', style: text.bodySmall),
        const SizedBox(height: AppSpace.md),
        // Ô bật/tắt ẩn ảnh: full chiều ngang, thẳng hàng với các thẻ bên dưới
        AppCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            value: _blindProfile,
            onChanged: (v) => setState(() => _blindProfile = v),
            secondary: const Icon(Icons.visibility_off_outlined),
            title: Text('Ẩn ảnh đại diện (Blind Profile)', style: text.titleSmall),
            subtitle: Text('Kết nối bằng tính cách trước, ảnh hiện sau khi đã trò chuyện', style: text.bodySmall),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        for (final g in _gamers) ...[
          _GamerCard(gamer: g, blind: _blindProfile),
          const SizedBox(height: AppSpace.md),
        ],
      ],
    );
  }
}

class _GamerCard extends StatelessWidget {
  final _Gamer gamer;
  final bool blind;

  const _GamerCard({required this.gamer, required this.blind});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Blind Profile: thay ảnh bằng biểu tượng khóa
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: t.cardHigh, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: blind ? Icon(Icons.lock_outline, color: t.textMuted) : Text(gamer.avatar, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text('${gamer.name}, ${gamer.age}', style: text.titleMedium, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: AppSpace.sm),
                        TagChip(gamer.mbti),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${gamer.game} · ${gamer.position}', style: text.bodySmall),
                  ],
                ),
              ),
              _MatchBadge(percent: gamer.match),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(gamer.bio, style: text.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpace.sm),
          Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.xs, children: [for (final tag in gamer.tags) TagChip(tag, color: t.textMuted)]),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Bắt chuyện'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatRoomScreen(teammateName: gamer.name, teammateAvatar: gamer.avatar)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// % hợp cạ: vòng tròn tiến độ nhỏ
class _MatchBadge extends StatelessWidget {
  final int percent;

  const _MatchBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(value: percent / 100, strokeWidth: 4, backgroundColor: t.cardHigh, color: ThemeService.green),
          Text('$percent%', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.textPrimary)),
        ],
      ),
    );
  }
}
