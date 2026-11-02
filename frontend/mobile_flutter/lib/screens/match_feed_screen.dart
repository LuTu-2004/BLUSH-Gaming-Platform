import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/match_model.dart';
import '../models/onboarding_model.dart';
import '../services/auth_service.dart';
import '../services/match_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/block_user.dart';
import '../widgets/report_user_sheet.dart';
import '../widgets/ui.dart';
import 'chat_room_screen.dart';
import 'onboarding_screen.dart';

/// Tab Đồng đội: gợi ý người chơi hợp cạ từ backend (GET api/match/suggestions).
/// Điểm hợp + lý do do backend tính (IMatchingService), sau này có thể do AI viết.
class MatchFeedScreen extends StatefulWidget {
  const MatchFeedScreen({super.key});

  @override
  State<MatchFeedScreen> createState() => _MatchFeedScreenState();
}

class _MatchFeedScreenState extends State<MatchFeedScreen> {
  late final MatchService _service = MatchService(context.read<AuthService>());

  bool _blindProfile = true;
  List<GameOption> _myGames = [];
  int? _selectedGameId; // null = tất cả game của mình
  List<MatchSuggestion>? _suggestions;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  /// Lấy danh sách game mình chơi (để làm bộ lọc) rồi lấy gợi ý
  Future<void> _loadAll() async {
    setState(() {
      _error = null;
      _suggestions = null;
    });
    try {
      final results = await Future.wait([_service.getOptions(), _service.getAnswers()]);
      final options = results[0] as OnboardingOptions;
      final answers = results[1] as OnboardingAnswers;
      _myGames = options.games.where((g) => answers.games.containsKey(g.id)).toList();
      if (_selectedGameId != null && !answers.games.containsKey(_selectedGameId)) _selectedGameId = null;
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
      return;
    }
    await _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _error = null;
      _suggestions = null;
    });
    try {
      final list = await _service.getSuggestions(gameId: _selectedGameId);
      if (mounted) setState(() => _suggestions = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _editPreferences() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingScreen(isEditing: true)));
    if (mounted) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Row(
          children: [
            Expanded(child: Text('Gợi ý cho bạn', style: text.headlineSmall)),
            IconButton(tooltip: 'Tải lại', icon: const Icon(Icons.refresh), onPressed: _loadAll),
            IconButton(tooltip: 'Sửa sở thích chơi game', icon: const Icon(Icons.tune), onPressed: _editPreferences),
          ],
        ),
        Text('Xếp theo game, mục đích, khung giờ, khu vực và sở thích của bạn', style: text.bodySmall),
        const SizedBox(height: AppSpace.md),
        // Bật/tắt ẩn ảnh: 1 dòng mảnh để nhường chỗ cho danh sách; giải thích nằm ở tooltip
        AppCard(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.xs, 0),
          child: Row(
            children: [
              Icon(_blindProfile ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text('Ẩn ảnh đại diện (Blind Profile)', style: text.bodyMedium, overflow: TextOverflow.ellipsis)),
              const Tooltip(
                message: 'Kết nối bằng tính cách trước, ảnh hiện sau khi đã trò chuyện',
                triggerMode: TooltipTriggerMode.tap,
                child: Padding(padding: EdgeInsets.all(AppSpace.xs), child: Icon(Icons.info_outline, size: 18)),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(value: _blindProfile, onChanged: (v) => setState(() => _blindProfile = v)),
              ),
            ],
          ),
        ),
        if (_myGames.length > 1) ...[
          const SizedBox(height: AppSpace.md),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (id, name) in [(null, 'Tất cả'), for (final g in _myGames) (g.id, g.name)]) ...[
                  ChoiceChip(
                    label: Text(name),
                    selected: _selectedGameId == id,
                    onSelected: (_) {
                      setState(() => _selectedGameId = id);
                      _loadSuggestions();
                    },
                  ),
                  const SizedBox(width: AppSpace.sm),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        ..._buildResults(),
      ],
    );
  }

  List<Widget> _buildResults() {
    final text = Theme.of(context).textTheme;
    final error = _error;
    final list = _suggestions;

    if (error != null) {
      final needsOnboarding = error.code == 'ONBOARDING_REQUIRED';
      return [
        AppCard(
          child: Column(
            children: [
              Text(error.message, textAlign: TextAlign.center, style: text.bodyMedium),
              const SizedBox(height: AppSpace.md),
              ElevatedButton(
                onPressed: needsOnboarding ? _editPreferences : _loadAll,
                child: Text(needsOnboarding ? 'Làm khảo sát' : 'Thử lại'),
              ),
            ],
          ),
        ),
      ];
    }
    if (list == null) {
      return const [Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator()))];
    }
    if (list.isEmpty) {
      return [
        AppCard(
          child: Text(
            'Chưa có ai phù hợp. Thử thêm game hoặc khung giờ trong "Sở thích chơi game" nhé.',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ),
      ];
    }
    return [
      for (final s in list) ...[
        _GamerCard(
          gamer: s,
          blind: _blindProfile,
          onBlocked: () => setState(() => _suggestions = _suggestions?.where((x) => x.userId != s.userId).toList()),
        ),
        const SizedBox(height: AppSpace.md),
      ],
    ];
  }
}

/// Huy hiệu VIP (quyền lợi BLUSH Pass)
class _VipCrown extends StatelessWidget {
  const _VipCrown();

  @override
  Widget build(BuildContext context) =>
      const Tooltip(message: 'Thành viên BLUSH Pass', child: Icon(Icons.workspace_premium, size: 18, color: ThemeService.yellow));
}

class _GamerCard extends StatelessWidget {
  final MatchSuggestion gamer;
  final bool blind;

  final VoidCallback onBlocked;

  const _GamerCard({required this.gamer, required this.blind, required this.onBlocked});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final accent = t.isDark ? ThemeService.accentLight : ThemeService.accent;
    final tags = [
      if (gamer.usesMic == true) 'Có mic',
      if (gamer.usesMic == false) 'Không mic',
      ...gamer.hobbies,
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BlindAvatar(gamer: gamer, blind: blind),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            gamer.age != null ? '${gamer.displayName}, ${gamer.age}' : gamer.displayName,
                            style: text.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (gamer.isVip) ...[const SizedBox(width: AppSpace.xs), const _VipCrown()],
                        if (gamer.mbti.isNotEmpty) ...[const SizedBox(width: AppSpace.sm), TagChip(gamer.mbti)],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(gamer.gameLine, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              MatchBadge(percent: gamer.score),
            ],
          ),
          if (gamer.reason.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            // Điểm chung (backend ghép thành các cụm ngắn cách nhau " · ")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.handshake_outlined, size: 16, color: accent),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'Điểm chung: ', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
                          TextSpan(text: gamer.reason),
                        ],
                      ),
                      style: text.bodySmall?.copyWith(color: t.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.sm),
          // Nút nhỏ có viền + mũi tên: nhìn ra là bấm được, không lẫn với tiêu đề
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                minimumSize: const Size(0, 34),
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.5)),
              ),
              onPressed: () => showMatchExplanation(context, userId: gamer.userId, displayName: gamer.displayName),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 16),
                  SizedBox(width: AppSpace.xs),
                  Flexible(child: Text('Hỏi AI vì sao hợp', overflow: TextOverflow.ellipsis)),
                  Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ),
          if (gamer.bio.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text(gamer.bio, style: text.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.xs, children: [for (final tag in tags) TagChip(tag, color: t.textMuted)]),
          ],
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Bắt chuyện'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatRoomScreen(userId: gamer.userId, displayName: gamer.displayName, avatarEmoji: gamer.avatarEmoji)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              PopupMenuButton<String>(
                tooltip: 'Báo cáo hoặc chặn',
                icon: Icon(Icons.more_vert, color: t.textMuted),
                onSelected: (action) async {
                  if (action == 'report') {
                    ReportUserSheet.show(context, userId: gamer.userId, displayName: gamer.displayName);
                  } else if (await confirmAndBlockUser(context, userId: gamer.userId, displayName: gamer.displayName)) {
                    onBlocked();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'report', child: Text('Báo cáo vi phạm')),
                  PopupMenuItem(value: 'block', child: Text('Chặn')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Avatar trong thẻ gợi ý. Blind Profile: ảnh/emoji gốc bị làm mờ hẳn (không nhận ra mặt) + ổ khóa ở giữa.
class _BlindAvatar extends StatelessWidget {
  final MatchSuggestion gamer;
  final bool blind;

  const _BlindAvatar({required this.gamer, required this.blind});

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    final avatar = AppAvatar(imageUrl: gamer.avatarUrl, fallback: gamer.avatarEmoji, size: _size);
    if (!blind) return avatar;
    return Tooltip(
      message: 'Ảnh hiện sau khi đã trò chuyện',
      child: SizedBox(
        width: _size,
        height: _size,
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: avatar),
              ColoredBox(color: Colors.black.withValues(alpha: 0.25)),
              const Icon(Icons.lock_outline, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
