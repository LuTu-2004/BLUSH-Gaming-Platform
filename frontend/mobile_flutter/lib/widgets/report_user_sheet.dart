import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/onboarding_model.dart';
import '../services/auth_service.dart';
import '../services/moderation_service.dart';
import '../theme/app_theme.dart';
import 'auth_widgets.dart';

/// Bảng báo cáo vi phạm 1 người chơi (POST api/reports): chọn lý do + mô tả thêm.
/// Mức độ nghiêm trọng do backend tự gán theo lý do.
class ReportUserSheet extends StatefulWidget {
  final String userId;
  final String displayName;

  const ReportUserSheet({super.key, required this.userId, required this.displayName});

  static Future<void> show(BuildContext context, {required String userId, required String displayName}) => showModalBottomSheet(
        context: context,
        isScrollControlled: true, // bàn phím mở thì bảng đẩy lên, không che ô nhập
        showDragHandle: true,
        builder: (_) => ReportUserSheet(userId: userId, displayName: displayName),
      );

  @override
  State<ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<ReportUserSheet> {
  late final ModerationService _service = ModerationService(context.read<AuthService>());
  final _detailController = TextEditingController();
  List<OptionItem>? _reasons;
  String? _loadError;
  String? _reason;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final reasons = await _service.getReportReasons();
      if (mounted) setState(() => _reasons = reasons);
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final message = await _service.reportUser(widget.userId, _reason!, _detailController.text);
      if (!mounted) return;
      Navigator.pop(context);
      showSuccessSnack(context, message);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reasons = _reasons;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Báo cáo ${widget.displayName}', style: text.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpace.xs),
            Text('Staff sẽ xem xét. Người bị báo cáo không biết ai đã báo cáo.', style: text.bodySmall),
            const SizedBox(height: AppSpace.md),
            if (_loadError != null)
              TextButton(onPressed: _load, child: Text('$_loadError Chạm để thử lại.'))
            else if (reasons == null)
              const Padding(padding: EdgeInsets.all(AppSpace.lg), child: Center(child: CircularProgressIndicator()))
            else ...[
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(
                  children: [
                    for (final r in reasons) RadioListTile<String>(value: r.code, title: Text(r.label), contentPadding: EdgeInsets.zero, dense: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              TextField(
                controller: _detailController,
                minLines: 2,
                maxLines: 4,
                maxLength: 400,
                decoration: const InputDecoration(labelText: 'Mô tả thêm (không bắt buộc)', alignLabelWithHint: true),
              ),
              const SizedBox(height: AppSpace.sm),
              ElevatedButton(
                onPressed: _reason == null || _sending ? null : _send,
                child: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Gửi báo cáo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
