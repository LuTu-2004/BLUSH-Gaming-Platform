import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Map<String, dynamic>> _users = [
    {'id': 1, 'name': 'Lưu Phước Nhật Tú', 'email': 'tu@blush.vn', 'role': 'Admin', 'status': 'Hoạt động'},
    {'id': 2, 'name': 'Trần Văn Staff', 'email': 'staff@blush.vn', 'role': 'Staff', 'status': 'Hoạt động'},
    {'id': 3, 'name': 'Gamer Pro 99', 'email': 'gamer@blush.vn', 'role': 'Gamer VIP', 'status': 'Hoạt động'},
  ];

  double _expectedUsers = 5000;
  double _aiTokensPerUser = 20000;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('⚡ ADMIN SYSTEM MANAGEMENT', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.header,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ThemeService.yellow,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Thống Kê Analytics'),
            Tab(icon: Icon(Icons.people), text: 'Quản Lý Người Dùng'),
            Tab(icon: Icon(Icons.calculate), text: 'Chi Phí & ROI AI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Analytics & Key Metrics
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _buildMetricCard('Người Dùng Active (DAU)', '1,240', '+18%', ThemeService.green, theme),
                  const SizedBox(width: 12),
                  _buildMetricCard('Doanh Thu Tháng', '45.2 Tr VNĐ', '+24%', ThemeService.yellow, theme),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricCard('Token AI Đã Dùng', '4.2M Tokens', 'Gemini 1.5', ThemeService.blurple, theme),
                  const SizedBox(width: 12),
                  _buildMetricCard('Tỷ Lệ Ghép Thành Công', '92.4%', 'High Match', ThemeService.fuchsia, theme),
                ],
              ),
              const SizedBox(height: 24),
              Text('📊 Biểu Đồ Tăng Trưởng User & Doanh Thu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textPrimary)),
              const SizedBox(height: 12),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ThemeService.blurple.withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart, size: 64, color: ThemeService.blurple),
                      SizedBox(height: 8),
                      Text('Tăng trưởng người dùng đạt 5,000+ Gamers trong tháng 9', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Tab 2: User Manager
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final u = _users[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ThemeService.blurple.withValues(alpha: 0.2),
                    child: Text('#${u['id']}', style: const TextStyle(fontWeight: FontWeight.bold, color: ThemeService.blurple)),
                  ),
                  title: Text(u['name'] as String, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textPrimary)),
                  subtitle: Text('${u['email']} • Role: ${u['role']}', style: TextStyle(color: theme.textMuted, fontSize: 12)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      setState(() {
                        u['role'] = val;
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'Admin', child: Text('Gán quyền Admin')),
                      const PopupMenuItem(value: 'Staff', child: Text('Gán quyền Staff')),
                      const PopupMenuItem(value: 'Gamer', child: Text('Gán quyền Gamer')),
                    ],
                  ),
                ),
              );
            },
          ),

          // Tab 3: Cost Calculator
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('💰 TÍNH TOÁN CHI PHÍ GEMINI API & DOANH THU PRO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textPrimary)),
              const SizedBox(height: 16),
              Text('Số lượng Gamers dự kiến: ${_expectedUsers.toInt()} users', style: TextStyle(color: theme.textPrimary)),
              Slider(
                value: _expectedUsers,
                min: 500,
                max: 50000,
                divisions: 99,
                activeColor: ThemeService.blurple,
                onChanged: (val) => setState(() => _expectedUsers = val),
              ),
              const SizedBox(height: 16),
              Text('Tokens AI bình quân / user / tháng: ${_aiTokensPerUser.toInt()} tokens', style: TextStyle(color: theme.textPrimary)),
              Slider(
                value: _aiTokensPerUser,
                min: 5000,
                max: 100000,
                divisions: 19,
                activeColor: ThemeService.yellow,
                onChanged: (val) => setState(() => _aiTokensPerUser = val),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ThemeService.green),
                ),
                child: Column(
                  children: [
                    _buildCalcRow('Tổng Token Dự Kiến / Tháng:', '${((_expectedUsers * _aiTokensPerUser) / 1000000).toStringAsFixed(1)}M Tokens', theme),
                    const Divider(),
                    _buildCalcRow('Chi Phí Gemini API (Dự kiến):',
                        '\$${((_expectedUsers * _aiTokensPerUser / 1000000) * 0.15).toStringAsFixed(2)} (~${((_expectedUsers * _aiTokensPerUser / 1000000) * 0.15 * 25000).toInt()} VNĐ)', theme),
                    const Divider(),
                    _buildCalcRow('Doanh Thu Dự Kiến (20% lên VIP 29K):', '${((_expectedUsers * 0.2 * 29000)).toInt()} VNĐ', theme),
                    const Divider(),
                    _buildCalcRow('LỢI NHUẬN RÒNG ESTIMATED:', '${((_expectedUsers * 0.2 * 29000) - ((_expectedUsers * _aiTokensPerUser / 1000000) * 0.15 * 25000)).toInt()} VNĐ', theme, isBold: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String change, Color color, ThemeService theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: theme.textMuted, fontSize: 11)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(change, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, ThemeService theme, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textMuted, fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: isBold ? ThemeService.green : theme.textPrimary, fontWeight: FontWeight.bold, fontSize: isBold ? 14 : 12)),
        ],
      ),
    );
  }
}
