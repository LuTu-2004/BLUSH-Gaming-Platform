import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../screens/vip_screen.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'auth_widgets.dart';

/// Nhãn nhỏ "Tạo bởi AI" + nút báo cáo câu trả lời AI không phù hợp (chính sách Google Play)
class AiFooter extends StatelessWidget {
  final String logId;
  final String usageLabel;

  const AiFooter({super.key, required this.logId, required this.usageLabel});

  Future<void> _report(BuildContext context) async {
    try {
      final message = await AiService(context.read<AuthService>()).report(logId);
      if (context.mounted) showSuccessSnack(context, message);
    } on ApiException catch (e) {
      if (context.mounted) showErrorSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpace.sm,
      children: [
        const Icon(Icons.auto_awesome, size: 14, color: ThemeService.accent),
        Text('Tạo bởi AI · $usageLabel', style: text.bodySmall),
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32), visualDensity: VisualDensity.compact),
          onPressed: () => _report(context),
          child: const Text('Báo cáo nội dung không phù hợp'),
        ),
      ],
    );
  }
}

/// Báo lỗi AI cho người dùng: hết lượt thì mời nâng cấp VIP, lỗi khác thì báo ngắn gọn
void showAiError(BuildContext context, ApiException e) {
  if (e.code != AiService.quotaExceeded) {
    showErrorSnack(context, e.message);
    return;
  }
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hết lượt AI'),
      content: Text(e.message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VipScreen()));
          },
          child: const Text('Xem BLUSH Pass'),
        ),
      ],
    ),
  );
}

/// Thẻ đồng đội -> "AI: vì sao hợp?" (POST api/ai/match/{userId}/explain)
Future<void> showMatchExplanation(BuildContext context, {required String userId, required String displayName}) async {
  final service = AiService(context.read<AuthService>());
  // Hiện bảng ngay với vòng xoay, có kết quả thì thay nội dung
  final future = service.explainMatch(userId);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => FutureBuilder<AiExplanation>(
      future: future,
      builder: (ctx, snap) {
        final text = Theme.of(ctx).textTheme;
        Widget body;
        if (snap.hasError) {
          final error = snap.error;
          body = Text(error is ApiException ? error.message : 'Có lỗi xảy ra, bạn thử lại sau nhé.', style: text.bodyMedium);
          if (error is ApiException && error.code == AiService.quotaExceeded) {
            body = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                body,
                const SizedBox(height: AppSpace.md),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VipScreen()));
                  },
                  child: const Text('Xem BLUSH Pass'),
                ),
              ],
            );
          }
        } else if (!snap.hasData) {
          body = const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator()));
        } else {
          final data = snap.data!;
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(data.explanation, style: text.bodyMedium),
              const SizedBox(height: AppSpace.md),
              AiFooter(logId: data.logId, usageLabel: data.usage.label),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Bạn và $displayName hợp nhau ở đâu?', style: text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpace.md),
                body,
              ],
            ),
          ),
        );
      },
    ),
  );
}
