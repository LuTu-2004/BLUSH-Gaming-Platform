import 'package:flutter/material.dart';
import '../../models/payment_model.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import 'admin_widgets.dart';

/// Trang Chi phí: mô phỏng chi phí vận hành và lợi nhuận theo số người dùng (Chức năng 17)
class AdminCostPage extends StatefulWidget {
  const AdminCostPage({super.key});

  @override
  State<AdminCostPage> createState() => _AdminCostPageState();
}

class _AdminCostPageState extends State<AdminCostPage> {
  // Số liệu theo tài liệu: AI ~52đ/user Free, ~393đ/user VIP mỗi tháng
  static const _aiCostFree = 52;
  static const _aiCostVip = 393;
  static const _vipPrice = 29000;
  static const _hosting = 500000; // Hosting + tên miền ước tính/tháng

  double _users = 5000;
  double _vipRate = 5; // %

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vipUsers = (_users * _vipRate / 100).round();
    final freeUsers = _users.round() - vipUsers;
    final aiCost = freeUsers * _aiCostFree + vipUsers * _aiCostVip;
    final totalCost = aiCost + _hosting;
    final revenue = vipUsers * _vipPrice;
    final profit = revenue - totalCost;
    String vnd(int n) => n < 0 ? '-${formatVnd(-n)}' : formatVnd(n);

    return AdminPage(
      children: [
        SplitRow(
          left: AdminPanel(
            title: 'Giả định',
            subtitle: 'Kéo để thử các kịch bản tăng trưởng',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Số người dùng: ${vnd(_users.round()).replaceAll('đ', '')}', style: text.titleSmall),
                Slider(value: _users, min: 1000, max: 100000, divisions: 99, label: vnd(_users.round()).replaceAll('đ', ''), onChanged: (v) => setState(() => _users = v)),
                Text('Tỷ lệ mua VIP: ${_vipRate.round()}%', style: text.titleSmall),
                Slider(value: _vipRate, min: 1, max: 20, divisions: 19, label: '${_vipRate.round()}%', onChanged: (v) => setState(() => _vipRate = v)),
                Text('AI: ${formatVnd(_aiCostFree)}/người Free, ${formatVnd(_aiCostVip)}/người VIP mỗi tháng · Gói VIP ${formatVnd(_vipPrice)}', style: text.bodySmall),
              ],
            ),
          ),
          right: AdminPanel(
            title: 'Kết quả mỗi tháng',
            child: Column(
              children: [
                _row(text, 'Chi phí AI', vnd(aiCost)),
                _row(text, 'Hosting & tên miền', vnd(_hosting)),
                _row(text, 'Tổng chi phí vận hành', vnd(totalCost), bold: true),
                const Divider(height: AppSpace.xl),
                _row(text, 'Doanh thu VIP ($vipUsers × 29K)', vnd(revenue)),
                _row(text, 'Lợi nhuận ước tính', vnd(profit), bold: true, color: profit >= 0 ? ThemeService.green : ThemeService.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(TextTheme text, String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? text.titleSmall : text.bodyMedium)),
          Text(value, style: (bold ? text.titleSmall : text.bodyMedium)?.copyWith(color: color)),
        ],
      ),
    );
  }
}
