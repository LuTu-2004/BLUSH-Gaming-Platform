import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/rating_model.dart';
import '../services/analytics.dart';
import '../services/auth_service.dart';
import '../services/rating_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'auth_widgets.dart';
import 'ui.dart';

// ============================================================
// ĐÁNH GIÁ APP BLUSH (1-5 sao + góp ý)
//   RateAppTile   : mục "Đánh giá BLUSH" trong tab Hồ sơ
//   RateAppSheet  : bảng chọn sao + góp ý
//   askForRatingOnce: tự hỏi 1 lần sau vài ngày dùng app (gọi từ khung chính)
// ============================================================

/// Tên mức sao, hiện dưới hàng sao
const _starLabels = ['Rất tệ', 'Chưa ổn', 'Bình thường', 'Thích', 'Tuyệt vời'];

/// Tự hỏi đánh giá 1 lần: backend báo nên hỏi (chưa đánh giá + đã dùng đủ lâu) và máy này chưa hỏi lần nào.
/// Hỏi rồi thì nhớ trên máy, dù người dùng bấm "Để sau" hay đã gửi.
Future<void> askForRatingOnce(BuildContext context) async {
  final auth = context.read<AuthService>();
  final user = auth.currentUser;
  if (user == null || user.role != 'User') return;

  final key = 'rating_asked_${user.id}';
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) ?? false) return;
    final mine = await RatingService(auth).getMine();
    if (!mine.shouldAsk || !context.mounted) return;
    await prefs.setBool(key, true);
    if (context.mounted) await RateAppSheet.show(context, isPrompt: true);
  } on ApiException {
    // Không hỏi được lúc này thì để lần mở app sau
  }
}

/// Mục "Đánh giá BLUSH" trong Hồ sơ: hiện số sao đã chấm, bấm để đánh giá / sửa
class RateAppTile extends StatefulWidget {
  const RateAppTile({super.key});

  @override
  State<RateAppTile> createState() => _RateAppTileState();
}

class _RateAppTileState extends State<RateAppTile> {
  MyRating? _mine;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final mine = await RatingService(context.read<AuthService>()).getMine();
      if (mounted) setState(() => _mine = mine);
    } on ApiException {
      // Lỗi mạng: vẫn bấm vào đánh giá được, chỉ không hiện số sao cũ
    }
  }

  Future<void> _open() async {
    final result = await RateAppSheet.show(context, initial: _mine);
    if (result != null && mounted) setState(() => _mine = result);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final stars = _mine?.stars;
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.star_outline_rounded),
        title: Text('Đánh giá BLUSH', style: text.titleSmall),
        subtitle: Text(
          stars == null ? 'Cho BLUSH biết bạn thấy app thế nào' : 'Bạn đã chấm $stars★ · Bấm để sửa',
          style: text.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: _open,
      ),
    );
  }
}

/// Bảng chọn 1-5 sao + góp ý. Trả về đánh giá mới khi gửi thành công, null khi đóng.
class RateAppSheet extends StatefulWidget {
  final MyRating? initial;

  /// true = app tự hỏi (có nút "Để sau"), false = người dùng tự mở từ Hồ sơ
  final bool isPrompt;

  const RateAppSheet({super.key, this.initial, this.isPrompt = false});

  static Future<MyRating?> show(BuildContext context, {MyRating? initial, bool isPrompt = false}) => showModalBottomSheet<MyRating>(
        context: context,
        isScrollControlled: true, // bàn phím mở thì bảng đẩy lên, không che ô nhập
        showDragHandle: true,
        builder: (_) => RateAppSheet(initial: initial, isPrompt: isPrompt),
      );

  @override
  State<RateAppSheet> createState() => _RateAppSheetState();
}

class _RateAppSheetState extends State<RateAppSheet> {
  late int _stars = widget.initial?.stars ?? 0;
  late final _commentController = TextEditingController(text: widget.initial?.comment ?? '');
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final result = await RatingService(context.read<AuthService>()).submit(_stars, _commentController.text);
      Analytics.rateApp(_stars);
      if (!mounted) return;
      Navigator.pop(context, result);
      showSuccessSnack(context, 'Cảm ơn bạn đã đánh giá BLUSH!');
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
    // Chấm thấp -> gợi ý nói rõ chỗ chưa ổn (vẫn không bắt buộc)
    final lowRating = _stars > 0 && _stars <= 3;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bạn thấy BLUSH thế nào?', style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.xs),
            Text('Đánh giá của bạn giúp BLUSH ghép đội tốt hơn mỗi ngày.', style: text.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i sao',
                    iconSize: 40,
                    onPressed: _sending ? null : () => setState(() => _stars = i),
                    icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: i <= _stars ? ThemeService.yellow : t.textMuted),
                  ),
              ],
            ),
            SizedBox(
              height: 20,
              child: Text(_stars == 0 ? 'Chạm để chọn số sao' : _starLabels[_stars - 1], style: text.labelLarge, textAlign: TextAlign.center),
            ),
            const SizedBox(height: AppSpace.lg),
            TextField(
              controller: _commentController,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000, // khớp SubmitRatingRequest ở backend
              decoration: InputDecoration(
                labelText: lowRating ? 'Điều gì khiến bạn chưa hài lòng? (không bắt buộc)' : 'Góp ý thêm (không bắt buộc)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            ElevatedButton(
              onPressed: _stars == 0 || _sending ? null : _send,
              child: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Gửi đánh giá'),
            ),
            if (widget.isPrompt) TextButton(onPressed: _sending ? null : () => Navigator.pop(context), child: const Text('Để sau')),
          ],
        ),
      ),
    );
  }
}
