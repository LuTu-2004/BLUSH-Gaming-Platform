import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../services/auth_service.dart';
import '../services/block_service.dart';
import '../services/theme_service.dart';
import 'auth_widgets.dart';

/// Hỏi xác nhận rồi chặn [userId]. Trả về true nếu đã chặn (màn gọi tự ẩn người đó / đóng phòng chat).
Future<bool> confirmAndBlockUser(BuildContext context, {required String userId, required String displayName}) async {
  final service = BlockService(context.read<AuthService>());
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Chặn $displayName?'),
      content: const Text(
        'Hai bạn sẽ không nhắn tin được cho nhau, cuộc trò chuyện cũ bị ẩn và không được gợi ý ghép đội với nhau. '
        'Người này không nhận được thông báo. Bạn có thể bỏ chặn trong Hồ sơ → Người đã chặn.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: ThemeService.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Chặn'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  try {
    final message = await service.block(userId);
    if (context.mounted) showSuccessSnack(context, message);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) showErrorSnack(context, e.message);
    return false;
  }
}
