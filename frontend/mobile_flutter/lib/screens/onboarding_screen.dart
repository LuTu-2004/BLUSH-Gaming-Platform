import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/onboarding_model.dart';
import '../services/auth_service.dart';
import '../services/match_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ui.dart';

/// Khảo sát sau đăng ký (4 bước) để ghép đội:
///   1. Game đang chơi + vị trí + mục đích (bắt buộc)
///   2. Khung giờ hay chơi
///   3. Khu vực (bắt buộc) + có dùng mic không
///   4. Sở thích, mô tả đồng đội mong muốn
///
/// [isEditing] = false: màn bắt buộc sau đăng ký (main.dart tự mở khi user.needsOnboarding),
///   lưu xong thì main.dart tự chuyển vào trang chủ.
/// [isEditing] = true: mở từ Hồ sơ để sửa, lưu xong thì quay lại.
class OnboardingScreen extends StatefulWidget {
  final bool isEditing;

  const OnboardingScreen({super.key, this.isEditing = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _stepCount = 4;

  late final MatchService _service = MatchService(context.read<AuthService>());
  final _wishController = TextEditingController();

  OnboardingOptions? _options;
  OnboardingAnswers _answers = OnboardingAnswers();
  String? _loadError;
  int _step = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _wishController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final options = await _service.getOptions();
      // Sửa lại: lấy câu trả lời cũ. Lần đầu: bắt đầu trống.
      final answers = widget.isEditing ? await _service.getAnswers() : OnboardingAnswers();
      if (!mounted) return;
      setState(() {
        _options = options;
        _answers = answers;
        _wishController.text = answers.teammateWish;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  // Bước 1 cần ít nhất 1 game, bước 3 cần khu vực; bước 2 và 4 không bắt buộc
  bool get _canContinue => switch (_step) {
        0 => _answers.games.isNotEmpty,
        2 => _answers.region != null,
        _ => true,
      };

  bool get _isOptionalStep => _step == 1 || _step == 3;

  void _back() => setState(() => _step--);

  Future<void> _next() async {
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      return;
    }
    _answers.teammateWish = _wishController.text;
    setState(() => _saving = true);
    try {
      await _service.saveAnswers(_answers);
      if (!mounted) return;
      if (widget.isEditing) {
        showSuccessSnack(context, 'Đã cập nhật sở thích chơi game.');
        Navigator.pop(context);
      }
      // Lần đầu: AuthService đã báo onboardingCompleted = true -> main.dart tự chuyển vào trang chủ
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;

    return Scaffold(
      appBar: AppBar(
        // Bước > 1: nút quay lại bước trước. Lần đầu ở bước 1: không có nút quay lại (bắt buộc làm).
        automaticallyImplyLeading: false,
        leading: _step > 0
            ? IconButton(tooltip: 'Bước trước', icon: const Icon(Icons.arrow_back), onPressed: _saving ? null : _back)
            : (widget.isEditing ? const BackButton() : null),
        title: Text(widget.isEditing ? 'Sở thích chơi game' : 'Tạo hồ sơ chơi game'),
        actions: [
          if (options != null && _isOptionalStep)
            TextButton(onPressed: _saving ? null : _next, child: Text(_step == _stepCount - 1 ? 'Bỏ qua & hoàn tất' : 'Bỏ qua')),
          if (!widget.isEditing && _step == 0)
            TextButton(onPressed: () => context.read<AuthService>().logout(), child: const Text('Đăng xuất')),
        ],
      ),
      body: options == null ? _buildLoading() : _buildSteps(options),
    );
  }

  Widget _buildLoading() {
    final error = _loadError;
    if (error == null) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: AppSpace.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.lg),
            ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }

  Widget _buildSteps(OnboardingOptions options) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;

    final step = switch (_step) {
      0 => _GamesStep(options: options, answers: _answers, onChanged: () => setState(() {})),
      1 => _PlayTimeStep(options: options, answers: _answers, onChanged: () => setState(() {})),
      2 => _RegionStep(options: options, answers: _answers, onChanged: () => setState(() {})),
      _ => _AboutStep(options: options, answers: _answers, wishController: _wishController, onChanged: () => setState(() {})),
    };

    return Column(
      children: [
        // ── Tiến độ ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Row(
                children: [
                  for (var i = 0; i < _stepCount; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step ? ThemeService.accent : t.cardHigh,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // KeyedSubtree: đổi bước thì cuộn lại từ đầu
        Expanded(child: KeyedSubtree(key: ValueKey(_step), child: step)),

        // ── Nút dưới cùng ───────────────────────────────────────
        Container(
          decoration: BoxDecoration(color: t.header, border: Border(top: BorderSide(color: t.border))),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
              child: Row(
                children: [
                  Text('Bước ${_step + 1}/$_stepCount', style: text.labelMedium),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _canContinue && !_saving ? _next : null,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_step == _stepCount - 1 ? (widget.isEditing ? 'Lưu' : 'Hoàn tất') : 'Tiếp tục'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tiêu đề + mô tả đầu mỗi bước
class _StepHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StepHeader(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.headlineSmall),
          const SizedBox(height: AppSpace.xs),
          Text(subtitle, style: text.bodyMedium?.copyWith(color: text.bodySmall?.color)),
        ],
      ),
    );
  }
}

/// Nhãn nhỏ phía trên 1 nhóm lựa chọn
class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.sm),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      );
}

// ── Bước 1: Game ────────────────────────────────────────────────────
class _GamesStep extends StatelessWidget {
  final OnboardingOptions options;
  final OnboardingAnswers answers;
  final VoidCallback onChanged;

  const _GamesStep({required this.options, required this.answers, required this.onChanged});

  static IconData _iconOf(String? genre) {
    final g = (genre ?? '').toLowerCase();
    if (g.contains('moba')) return Icons.shield_outlined;
    if (g.contains('fps')) return Icons.gps_fixed;
    if (g.contains('battle')) return Icons.paragliding;
    if (g.contains('auto')) return Icons.extension_outlined;
    if (g.contains('survival')) return Icons.local_fire_department_outlined;
    return Icons.sports_esports_outlined;
  }

  void _toggle(GameOption game) {
    if (answers.games.containsKey(game.id)) {
      answers.games.remove(game.id);
    } else {
      answers.games[game.id] = GameChoice();
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final accent = t.isDark ? ThemeService.accentLight : ThemeService.accent;

    return PageBody(
      children: [
        const _StepHeader('Bạn đang chơi game nào?', 'Chọn ít nhất 1 game. BLUSH sẽ tìm đồng đội chơi cùng game và cùng mục đích với bạn.'),
        for (final game in options.games) ...[
          AppCard(
            borderColor: answers.games.containsKey(game.id) ? ThemeService.accent : null,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => _toggle(game),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.md)),
                          child: Icon(_iconOf(game.genre), color: accent, size: 22),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(game.name, style: text.titleSmall),
                              if (game.genre != null) Text(game.genre!, style: text.bodySmall),
                            ],
                          ),
                        ),
                        Icon(
                          answers.games.containsKey(game.id) ? Icons.check_circle : Icons.add_circle_outline,
                          color: answers.games.containsKey(game.id) ? ThemeService.accent : t.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                // Đã chọn game -> hỏi thêm vị trí + mục đích
                if (answers.games[game.id] case final choice?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(height: 1, color: t.border),
                        if (game.positions.isNotEmpty) ...[
                          const _FieldLabel('Vị trí hay chơi (không bắt buộc)'),
                          Wrap(
                            spacing: AppSpace.sm,
                            runSpacing: AppSpace.sm,
                            children: [
                              for (final p in game.positions)
                                ChoiceChip(
                                  label: Text(p),
                                  selected: choice.position == p,
                                  onSelected: (on) {
                                    choice.position = on ? p : null;
                                    onChanged();
                                  },
                                ),
                            ],
                          ),
                        ],
                        const _FieldLabel('Bạn chơi game này để'),
                        Wrap(
                          spacing: AppSpace.sm,
                          runSpacing: AppSpace.sm,
                          children: [
                            for (final purpose in options.purposes)
                              ChoiceChip(
                                label: Text(purpose.label),
                                selected: choice.purpose == purpose.code,
                                onSelected: (_) {
                                  choice.purpose = purpose.code;
                                  onChanged();
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
        ],
      ],
    );
  }
}

// ── Bước 2: Khung giờ ───────────────────────────────────────────────
class _PlayTimeStep extends StatelessWidget {
  final OnboardingOptions options;
  final OnboardingAnswers answers;
  final VoidCallback onChanged;

  const _PlayTimeStep({required this.options, required this.answers, required this.onChanged});

  static IconData _iconOf(String code) => switch (code) {
        'Morning' => Icons.wb_twilight,
        'Afternoon' => Icons.wb_sunny_outlined,
        'Evening' => Icons.nights_stay_outlined,
        'LateNight' => Icons.bedtime_outlined,
        _ => Icons.weekend_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        const _StepHeader('Bạn hay chơi lúc nào?', 'Chọn các khung giờ bạn thường online, để gặp đồng đội rảnh cùng lúc.'),
        for (final slot in options.playTimes) ...[
          AppCard(
            borderColor: answers.playTimes.contains(slot.code) ? ThemeService.accent : null,
            onTap: () {
              answers.playTimes.contains(slot.code) ? answers.playTimes.remove(slot.code) : answers.playTimes.add(slot.code);
              onChanged();
            },
            child: Row(
              children: [
                Icon(_iconOf(slot.code), color: answers.playTimes.contains(slot.code) ? ThemeService.accent : t.textMuted),
                const SizedBox(width: AppSpace.md),
                Expanded(child: Text(slot.label, style: text.titleSmall)),
                Icon(
                  answers.playTimes.contains(slot.code) ? Icons.check_box : Icons.check_box_outline_blank,
                  color: answers.playTimes.contains(slot.code) ? ThemeService.accent : t.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
      ],
    );
  }
}

// ── Bước 3: Khu vực + mic ───────────────────────────────────────────
class _RegionStep extends StatelessWidget {
  final OnboardingOptions options;
  final OnboardingAnswers answers;
  final VoidCallback onChanged;

  const _RegionStep({required this.options, required this.answers, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        const _StepHeader('Bạn ở đâu, chơi thế nào?', 'Cùng khu vực thì ping ổn định hơn và dễ hẹn offline.'),
        Row(
          children: [
            for (var i = 0; i < options.regions.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.md),
              Expanded(
                child: AppCard(
                  borderColor: answers.region == options.regions[i].code ? ThemeService.accent : null,
                  onTap: () {
                    answers.region = options.regions[i].code;
                    onChanged();
                  },
                  child: Column(
                    children: [
                      Icon(Icons.location_on_outlined, color: answers.region == options.regions[i].code ? ThemeService.accent : t.textMuted),
                      const SizedBox(height: AppSpace.sm),
                      Text(options.regions[i].label, style: text.titleSmall, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const _FieldLabel('Khi chơi bạn có bật mic không?'),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final (value, label, icon) in const [
              (true, 'Có, hay bật mic', Icons.mic_none),
              (false, 'Không, chỉ chat', Icons.mic_off_outlined),
              (null, 'Tùy trận', Icons.shuffle),
            ])
              ChoiceChip(
                avatar: Icon(icon, size: 16, color: answers.usesMic == value ? Colors.white : t.textMuted),
                label: Text(label),
                selected: answers.usesMic == value,
                onSelected: (_) {
                  answers.usesMic = value;
                  onChanged();
                },
              ),
          ],
        ),
      ],
    );
  }
}

// ── Bước 4: Sở thích, mô tả đồng đội ────────────────────────────────
class _AboutStep extends StatelessWidget {
  final OnboardingOptions options;
  final OnboardingAnswers answers;
  final TextEditingController wishController;
  final VoidCallback onChanged;

  const _AboutStep({required this.options, required this.answers, required this.wishController, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const _StepHeader('Thêm chút về bạn', 'Không bắt buộc, nhưng điền càng nhiều thì gợi ý đồng đội càng chuẩn.'),
        const _FieldLabel('Sở thích'),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final hobby in options.hobbies)
              FilterChip(
                label: Text(hobby.name),
                selected: answers.hobbyIds.contains(hobby.id),
                onSelected: (on) {
                  on ? answers.hobbyIds.add(hobby.id) : answers.hobbyIds.remove(hobby.id);
                  onChanged();
                },
              ),
          ],
        ),
        const _FieldLabel('Bạn muốn đồng đội như thế nào?'),
        TextField(
          controller: wishController,
          minLines: 2,
          maxLines: 4,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'VD: chill, không toxic, hay chơi khuya, thích bật mic tấu hài',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
