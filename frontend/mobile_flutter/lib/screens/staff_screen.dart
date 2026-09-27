import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _reports = [
    {'id': 101, 'reporter': 'Nguyễn Văn A', 'target': 'ToxicGamer99', 'reason': 'Chửi thề & xúc phạm teammate', 'status': 'Chờ xử lý', 'time': '10 phút trước'},
    {'id': 102, 'reporter': 'Trần Thị B', 'target': 'AfkMaster', 'reason': 'Treo máy cố tình phá trận', 'status': 'Đã cảnh cáo', 'time': '1 giờ trước'},
  ];

  final List<String> _icebreakers = [
    'Con game đầu tiên đưa bạn tới con đường game thủ là gì?',
    'Điều gì khiến bạn overthink nhất khi chơi game leo rank?',
    'Nếu được cosplay 1 tướng trong game, bạn chọn ai?',
  ];

  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('🛡️ STAFF MODERATION PORTAL', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.header,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ThemeService.blurple,
          tabs: const [
            Tab(icon: Icon(Icons.report), text: 'Quản Lý Báo Cáo'),
            Tab(icon: Icon(Icons.psychology), text: 'Câu Hỏi Phá Băng AI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Report Manager
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _reports.length,
            itemBuilder: (context, index) {
              final rep = _reports[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ThemeService.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Báo cáo #${rep['id']}', style: const TextStyle(color: ThemeService.red, fontWeight: FontWeight.bold)),
                        Text(rep['time'] as String, style: TextStyle(color: theme.textMuted, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Người báo cáo: ${rep['reporter']} ➔ Đối tượng: ${rep['target']}', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Lý do: ${rep['reason']}', style: TextStyle(color: theme.textMuted, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: ThemeService.red, foregroundColor: Colors.white),
                          icon: const Icon(Icons.block, size: 14),
                          label: const Text('Khóa TK 3 Ngày'),
                          onPressed: () {
                            setState(() {
                              rep['status'] = 'Đã khóa TK';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          child: const Text('Bỏ Qua'),
                          onPressed: () {
                            setState(() {
                              _reports.removeAt(index);
                            });
                          },
                        )
                      ],
                    )
                  ],
                ),
              );
            },
          ),

          // Tab 2: Icebreaker Editor
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('➕ Thêm câu hỏi phá băng mới:', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      decoration: const InputDecoration(hintText: 'Nhập nội dung câu hỏi phá băng...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: ThemeService.blurple),
                    onPressed: () {
                      if (_questionController.text.isNotEmpty) {
                        setState(() {
                          _icebreakers.add(_questionController.text);
                          _questionController.clear();
                        });
                      }
                    },
                    child: const Text('THÊM'),
                  )
                ],
              ),
              const SizedBox(height: 24),
              Text('📋 Danh sách câu hỏi hiện tại:', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textPrimary)),
              const SizedBox(height: 12),
              ..._icebreakers.map((q) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(q, style: TextStyle(color: theme.textPrimary))),
                        IconButton(
                          icon: const Icon(Icons.delete, color: ThemeService.red, size: 20),
                          onPressed: () {
                            setState(() {
                              _icebreakers.remove(q);
                            });
                          },
                        )
                      ],
                    ),
                  ))
            ],
          ),
        ],
      ),
    );
  }
}
