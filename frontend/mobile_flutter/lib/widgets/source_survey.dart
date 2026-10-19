import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../services/auth_service.dart';
import '../services/match_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'auth_widgets.dart';

// ============================================================
// "BẠN BIẾT BLUSH QUA ĐÂU?" - hỏi 1 lần sau khảo sát (người cũ: lần mở app kế tiếp)
// Admin xem tỉ lệ từng kênh ở box "Nguồn người dùng" trong Tổng quan.
// ============================================================

/// Mã PHẢI khớp backend/Services/AcquisitionSources.cs
const acquisitionSources = [
  ('google', 'Google', Icons.search),
  ('facebook', 'Facebook', Icons.facebook),
  ('tiktok', 'TikTok', Icons.tiktok),
  ('youtube', 'YouTube', Icons.smart_display_outlined),
  ('friend', 'Bạn bè giới thiệu', Icons.group_outlined),
  ('other', 'Khác', Icons.more_horiz),
];

/// Hỏi 1 lần nếu gamer chưa trả lời và máy này chưa hỏi. Trả về true nếu đã hiện bảng hỏi
/// (để khung chính không hỏi thêm đánh giá ngay sau đó).
Future<bool> askForSourceOnce(BuildContext context) async {
  final auth = context.read<AuthService>();
  final user = auth.currentUser;
  if (user == null || user.role != 'User') return false;

  final key = 'source_asked_${user.id}';
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) ?? false) return false;
    if (await MatchService(auth).getSource() != null || !context.mounted) return false;
    await prefs.setBool(key, true);
    if (context.mounted) await SourceSurveySheet.show(context);
    return true;
  } on ApiException {
    return false; // không hỏi được lúc này thì để lần mở app sau
  }
}

/// Bảng chọn 1 nguồn. Bấm "Bỏ qua" hoặc vuốt xuống thì không lưu gì.
class SourceSurveySheet extends StatefulWidget {
  const SourceSurveySheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const SourceSurveySheet(),
      );

  @override
  State<SourceSurveySheet> createState() => _SourceSurveySheetState();
}

class _SourceSurveySheetState extends State<SourceSurveySheet> {
  String? _selected;
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await MatchService(context.read<AuthService>()).saveSource(_selected!);
      if (!mounted) return;
      Navigator.pop(context);
      showSuccessSnack(context, 'Cảm ơn bạn đã chia sẻ!');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final accent = t.isDark ? ThemeService.accentLight : ThemeService.accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bạn biết BLUSH qua đâu?', style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.xs),
            Text('Giúp BLUSH biết nên giới thiệu app ở đâu để có thêm đồng đội cho bạn.', style: text.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.lg),
            // 2 cột, ô cao bằng nhau
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpace.sm,
              crossAxisSpacing: AppSpace.sm,
              childAspectRatio: 3,
              children: [
                for (final (code, label, icon) in acquisitionSources)
                  _SourceOption(
                    label: label,
                    icon: icon,
                    selected: _selected == code,
                    onTap: _sending ? null : () => setState(() => _selected = code),
                    accent: accent,
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            ElevatedButton(
              onPressed: _selected == null || _sending ? null : _send,
              child: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Gửi'),
            ),
            TextButton(onPressed: _sending ? null : () => Navigator.pop(context), child: const Text('Bỏ qua')),
          ],
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color accent;

  const _SourceOption({required this.label, required this.icon, required this.selected, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    return Material(
      color: selected ? ThemeService.accent.withValues(alpha: t.isDark ? 0.28 : 0.12) : t.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: selected ? accent : t.border, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? accent : t.textMuted),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text(label, style: text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}
