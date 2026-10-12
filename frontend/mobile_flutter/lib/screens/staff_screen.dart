import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/moderation_model.dart';
import '../models/onboarding_model.dart';
import '../models/payment_model.dart';
import '../services/auth_service.dart';
import '../services/moderation_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ui.dart';

/// Khu kiểm duyệt (Staff/Admin): báo cáo vi phạm + câu hỏi phá băng (api/staff, Chức năng 13, 14).
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kiểm duyệt'),
          bottom: const TabBar(tabs: [Tab(text: 'Báo cáo vi phạm'), Tab(text: 'Câu hỏi phá băng')]),
        ),
        body: const TabBarView(children: [_ReportsTab(), _IceBreakersTab()]),
      ),
    );
  }
}

// ── Báo cáo vi phạm ─────────────────────────────────────────────────
class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  static const _filters = [(null, 'Tất cả'), ('Pending', 'Đang chờ'), ('Resolved', 'Đã xử lý')];
  static const _severityLabel = {'High': 'Cao', 'Medium': 'Trung bình', 'Low': 'Thấp'};
  static const _severityColor = {'High': ThemeService.red, 'Medium': Colors.orange, 'Low': ThemeService.green};
  static const _actionLabel = {'Warn': 'Đã cảnh báo', 'Suspend': 'Đã tạm khóa 3 ngày', 'Dismiss': 'Đã bỏ qua'};

  late final ModerationService _service = ModerationService(context.read<AuthService>());
  String? _status = 'Pending'; // mở ra là thấy việc cần làm trước
  final List<ModerationReport> _items = [];
  ReportPage? _lastPage;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    _items.clear();
    _lastPage = null;
    await _loadMore();
  }

  Future<void> _loadMore() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _service.getReports(status: _status, page: (_lastPage?.page ?? 0) + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _lastPage = page;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolve(ModerationReport r, String action) async {
    if (action == 'Suspend') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tạm khóa 3 ngày?'),
          content: Text('${r.reportedUserName} bị đăng xuất ngay và không đăng nhập được trong 3 ngày.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạm khóa')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    try {
      await _service.resolveReport(r.id, action);
      if (!mounted) return;
      showSuccessSnack(context, 'Báo cáo #${r.id}: ${_actionLabel[action]!.toLowerCase()}.');
      _reload(); // cập nhật số liệu + báo cáo rời khỏi bộ lọc "Đang chờ"
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
      _reload(); // VD: Staff khác vừa xử lý -> tải lại cho đúng
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final stats = _lastPage;
    final total = stats?.total ?? 0;

    return RefreshIndicator(
      onRefresh: _reload,
      child: PageBody(
        children: [
          Row(
            children: [
              Expanded(child: StatTile(icon: Icons.flag_outlined, color: ThemeService.accent, value: stats == null ? '-' : '${stats.totalReports}', label: 'Tổng')),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: StatTile(icon: Icons.hourglass_top, color: Colors.orange, value: stats == null ? '-' : '${stats.pendingReports}', label: 'Đang chờ')),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: StatTile(icon: Icons.check_circle_outline, color: ThemeService.green, value: stats == null ? '-' : '${stats.resolvedReports}', label: 'Đã xử lý')),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            children: [
              for (final (value, label) in _filters)
                ChoiceChip(
                  label: Text(label),
                  selected: _status == value,
                  onSelected: (_) {
                    setState(() => _status = value);
                    _reload();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          if (_error != null)
            AppCard(onTap: _loadMore, child: Text('$_error Chạm để thử lại.', style: text.bodySmall, textAlign: TextAlign.center))
          else if (_items.isEmpty && _loading)
            const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator()))
          else if (_items.isEmpty)
            AppCard(child: Text('Không có báo cáo nào.', style: text.bodySmall, textAlign: TextAlign.center)),
          for (final r in _items) ...[
            _ReportCard(
              report: r,
              severityLabel: _severityLabel[r.severity] ?? r.severity,
              severityColor: _severityColor[r.severity],
              actionLabel: _actionLabel[r.actionTaken],
              onAction: (a) => _resolve(r, a),
            ),
            const SizedBox(height: AppSpace.md),
          ],
          if (_items.length < total)
            Center(
              child: OutlinedButton(
                onPressed: _loading ? null : _loadMore,
                child: Text(_loading ? 'Đang tải...' : 'Tải thêm (${total - _items.length})'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ModerationReport report;
  final String severityLabel;
  final Color? severityColor;
  final String? actionLabel;
  final ValueChanged<String> onAction;

  const _ReportCard({required this.report, required this.severityLabel, this.severityColor, this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = report;
    final createdAt = r.createdAt;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#${r.id}', style: text.titleSmall),
              const SizedBox(width: AppSpace.sm),
              TagChip('Mức ${severityLabel.toLowerCase()}', color: severityColor),
              const Spacer(),
              if (createdAt != null) Text(formatDateTime(createdAt), style: text.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text('${r.reporterName} báo cáo ${r.reportedUserName}', style: text.titleSmall),
          if (r.reportedUserEmail.isNotEmpty) Text(r.reportedUserEmail, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpace.xs),
          Text(r.reason, style: text.bodyMedium),
          const SizedBox(height: AppSpace.md),
          if (r.isPending)
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                OutlinedButton(onPressed: () => onAction('Warn'), child: const Text('Cảnh báo')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: ThemeService.red),
                  onPressed: () => onAction('Suspend'),
                  child: const Text('Tạm khóa 3 ngày'),
                ),
                TextButton(onPressed: () => onAction('Dismiss'), child: const Text('Bỏ qua')),
              ],
            )
          else
            Wrap(
              spacing: AppSpace.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TagChip(actionLabel ?? 'Đã xử lý', color: ThemeService.green, icon: Icons.check),
                if (r.resolvedByName != null) Text('bởi ${r.resolvedByName}', style: text.bodySmall),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Câu hỏi phá băng ────────────────────────────────────────────────
class _IceBreakersTab extends StatefulWidget {
  const _IceBreakersTab();

  @override
  State<_IceBreakersTab> createState() => _IceBreakersTabState();
}

class _IceBreakersTabState extends State<_IceBreakersTab> {
  late final ModerationService _service = ModerationService(context.read<AuthService>());
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  List<OptionItem> _categories = [];
  List<IceBreaker>? _questions;
  String? _category;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final categories = _categories.isEmpty ? await _service.getIceBreakerCategories() : _categories;
      final questions = await _service.getIceBreakers();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _category ??= categories.isEmpty ? null : categories.first.code;
        _questions = questions;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  String _categoryLabel(String code) => _categories.where((c) => c.code == code).map((c) => c.label).firstOrNull ?? code;

  Future<void> _add() async {
    if (_questionController.text.trim().isEmpty || _optionAController.text.trim().isEmpty || _optionBController.text.trim().isEmpty) {
      showErrorSnack(context, 'Vui lòng nhập câu hỏi và cả 2 lựa chọn.');
      return;
    }
    setState(() => _saving = true);
    try {
      final created = await _service.createIceBreaker(
        category: _category!,
        question: _questionController.text,
        optionA: _optionAController.text,
        optionB: _optionBController.text,
      );
      if (!mounted) return;
      setState(() {
        _questions = [created, ...?_questions];
        _questionController.clear();
        _optionAController.clear();
        _optionBController.clear();
      });
      showSuccessSnack(context, 'Đã thêm câu hỏi.');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setActive(IceBreaker q, bool active) async {
    try {
      final updated = await _service.setIceBreakerActive(q.id, active);
      if (mounted) setState(() => _questions = [for (final i in _questions!) i.id == q.id ? updated : i]);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    }
  }

  Future<void> _delete(IceBreaker q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa câu hỏi?'),
        content: Text(q.question),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _service.deleteIceBreaker(q.id);
      if (mounted) setState(() => _questions = _questions!.where((i) => i.id != q.id).toList());
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message); // VD: câu đã dùng trong phòng chat -> chỉ tắt được
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = context.watch<ThemeService>();
    final questions = _questions;

    return RefreshIndicator(
      onRefresh: _load,
      child: PageBody(
        children: [
          const SectionHeader('Thêm câu hỏi mới'),
          if (_categories.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Loại câu hỏi'),
              items: [for (final c in _categories) DropdownMenuItem(value: c.code, child: Text(c.label))],
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: AppSpace.md),
          ],
          TextField(
            controller: _questionController,
            minLines: 1,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Câu hỏi', hintText: 'VD: Team thua 10 mạng đầu game, bạn sẽ?'),
          ),
          const SizedBox(height: AppSpace.sm),
          TextField(controller: _optionAController, maxLength: 255, decoration: const InputDecoration(labelText: 'Lựa chọn A', hintText: 'VD: Thủ trụ chờ late game')),
          const SizedBox(height: AppSpace.sm),
          TextField(controller: _optionBController, maxLength: 255, decoration: const InputDecoration(labelText: 'Lựa chọn B', hintText: 'VD: All-in lật kèo')),
          const SizedBox(height: AppSpace.sm),
          ElevatedButton(
            onPressed: _saving || _category == null ? null : _add,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Thêm câu hỏi'),
          ),
          const SizedBox(height: AppSpace.xl),
          if (_error != null)
            AppCard(onTap: _load, child: Text('$_error Chạm để thử lại.', style: text.bodySmall, textAlign: TextAlign.center))
          else if (questions == null)
            const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator()))
          else ...[
            SectionHeader('Danh sách câu hỏi (${questions.where((q) => q.isActive).length} đang bật)'),
            if (questions.isEmpty)
              AppCard(child: Text('Chưa có câu hỏi nào.', style: text.bodySmall, textAlign: TextAlign.center))
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < questions.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: t.border),
                      ListTile(
                        leading: Switch(value: questions[i].isActive, onChanged: (v) => _setActive(questions[i], v)),
                        title: Text(questions[i].question, style: text.bodyMedium),
                        subtitle: Text(
                          '${_categoryLabel(questions[i].category)} · ${questions[i].optionAIcon} ${questions[i].optionA} / ${questions[i].optionBIcon} ${questions[i].optionB}',
                          style: text.bodySmall,
                        ),
                        trailing: IconButton(
                          tooltip: 'Xóa',
                          icon: const Icon(Icons.delete_outline, color: ThemeService.red),
                          onPressed: () => _delete(questions[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
