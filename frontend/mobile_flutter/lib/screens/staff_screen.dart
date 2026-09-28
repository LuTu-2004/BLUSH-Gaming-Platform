import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ui.dart';

/// Khu kiểm duyệt (Staff): quản lý báo cáo vi phạm + câu hỏi phá băng (Chức năng 13, 14).
/// TODO: nối API khi backend có endpoint Reports / IceBreakerQuestions.
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

// Khớp bảng Reports: Severity High/Medium/Low, ActionTaken Warn/Suspend/Dismiss
class _Report {
  final int id;
  final String reporter;
  final String target;
  final String reason;
  final String severity;
  final String time;
  String? action; // null = đang chờ xử lý

  _Report(this.id, this.reporter, this.target, this.reason, this.severity, this.time);

  bool get isPending => action == null;
}

class _IceBreaker {
  final String question;
  bool active;

  _IceBreaker(this.question, {this.active = true});
}

class _StaffScreenState extends State<StaffScreen> {
  static const _severityLabel = {'High': 'Cao', 'Medium': 'Trung bình', 'Low': 'Thấp'};
  static const _severityColor = {'High': ThemeService.red, 'Medium': Colors.orange, 'Low': ThemeService.green};
  static const _actionLabel = {'Warn': 'Đã cảnh báo', 'Suspend': 'Đã tạm khóa', 'Dismiss': 'Đã bỏ qua'};

  final _reports = [
    _Report(101, 'Nguyễn Văn A', 'ToxicGamer99', 'Chửi thề, xúc phạm đồng đội', 'High', '10 phút trước'),
    _Report(102, 'Trần Thị B', 'AfkMaster', 'Treo máy cố tình phá trận', 'Medium', '1 giờ trước'),
    _Report(103, 'Lê C', 'SpamKing', 'Gửi link quảng cáo trong chat', 'Low', '3 giờ trước'),
  ];

  final _icebreakers = [
    _IceBreaker('Team thua 10 mạng đầu game, bạn sẽ thủ trụ hay all-in lật kèo?'),
    _IceBreaker('Vào sảnh bạn thích bật mic tấu hài hay im lặng tập trung?'),
    _IceBreaker('Nếu được cosplay 1 tướng trong game, bạn chọn ai?', active: false),
  ];

  final _questionController = TextEditingController();
  String _filter = 'Tất cả';

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _resolve(_Report r, String action) {
    setState(() => r.action = action);
    showSuccessSnack(context, 'Báo cáo #${r.id}: ${_actionLabel[action]!.toLowerCase()} ${r.target}');
  }

  void _addQuestion() {
    final q = _questionController.text.trim();
    if (q.isEmpty) {
      showErrorSnack(context, 'Vui lòng nhập nội dung câu hỏi.');
      return;
    }
    setState(() {
      _icebreakers.insert(0, _IceBreaker(q));
      _questionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kiểm duyệt'),
          bottom: const TabBar(tabs: [Tab(text: 'Báo cáo vi phạm'), Tab(text: 'Câu hỏi phá băng')]),
        ),
        body: TabBarView(children: [_buildReports(), _buildIceBreakers()]),
      ),
    );
  }

  Widget _buildReports() {
    final text = Theme.of(context).textTheme;
    final pending = _reports.where((r) => r.isPending).length;
    final shown = switch (_filter) {
      'Đang chờ' => _reports.where((r) => r.isPending),
      'Đã xử lý' => _reports.where((r) => !r.isPending),
      _ => _reports,
    }
        .toList();

    return PageBody(
      children: [
        Row(
          children: [
            Expanded(child: StatTile(icon: Icons.flag_outlined, color: ThemeService.accent, value: '${_reports.length}', label: 'Tổng')),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: StatTile(icon: Icons.hourglass_top, color: Colors.orange, value: '$pending', label: 'Đang chờ')),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: StatTile(icon: Icons.check_circle_outline, color: ThemeService.green, value: '${_reports.length - pending}', label: 'Đã xử lý')),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        Wrap(
          spacing: AppSpace.sm,
          children: [
            for (final f in ['Tất cả', 'Đang chờ', 'Đã xử lý']) ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        if (shown.isEmpty) AppCard(child: Text('Không có báo cáo nào.', style: text.bodySmall, textAlign: TextAlign.center)),
        for (final r in shown) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('#${r.id}', style: text.titleSmall),
                    const SizedBox(width: AppSpace.sm),
                    TagChip('Mức ${_severityLabel[r.severity]!.toLowerCase()}', color: _severityColor[r.severity]),
                    const Spacer(),
                    Text(r.time, style: text.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Text('${r.reporter} báo cáo ${r.target}', style: text.titleSmall),
                const SizedBox(height: 2),
                Text(r.reason, style: text.bodyMedium),
                const SizedBox(height: AppSpace.md),
                if (r.isPending)
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.sm,
                    children: [
                      OutlinedButton(onPressed: () => _resolve(r, 'Warn'), child: const Text('Cảnh báo')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: ThemeService.red),
                        onPressed: () => _resolve(r, 'Suspend'),
                        child: const Text('Tạm khóa 3 ngày'),
                      ),
                      TextButton(onPressed: () => _resolve(r, 'Dismiss'), child: const Text('Bỏ qua')),
                    ],
                  )
                else
                  TagChip(_actionLabel[r.action]!, color: ThemeService.green, icon: Icons.check),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
        ],
      ],
    );
  }

  Widget _buildIceBreakers() {
    final text = Theme.of(context).textTheme;
    final t = context.watch<ThemeService>();
    return PageBody(
      children: [
        const SectionHeader('Thêm câu hỏi mới'),
        TextField(
          controller: _questionController,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Nhập câu hỏi tình huống game...'),
        ),
        const SizedBox(height: AppSpace.sm),
        ElevatedButton(onPressed: _addQuestion, child: const Text('Thêm câu hỏi')),
        const SizedBox(height: AppSpace.xl),
        SectionHeader('Danh sách câu hỏi (${_icebreakers.where((q) => q.active).length} đang bật)'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < _icebreakers.length; i++) ...[
                if (i > 0) Divider(height: 1, color: t.border),
                ListTile(
                  title: Text(_icebreakers[i].question, style: text.bodyMedium),
                  leading: Switch(value: _icebreakers[i].active, onChanged: (v) => setState(() => _icebreakers[i].active = v)),
                  trailing: IconButton(
                    tooltip: 'Xóa',
                    icon: const Icon(Icons.delete_outline, color: ThemeService.red),
                    onPressed: () => setState(() => _icebreakers.removeAt(i)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
