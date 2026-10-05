import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/payment_model.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/payment_widgets.dart';
import '../widgets/ui.dart';
import 'payment_flow_screens.dart';

/// Lịch sử thanh toán của mình (GET api/payment/transactions)
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late final PaymentService _service = PaymentService(context.read<AuthService>());
  List<PaymentTransaction>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await _service.getHistory();
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final items = _items;

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử thanh toán')),
      body: PageBody(
        children: [
          if (_error != null)
            AppCard(onTap: _load, child: Text('$_error Chạm để thử lại.', textAlign: TextAlign.center, style: text.bodySmall))
          else if (items == null)
            const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator()))
          else if (items.isEmpty)
            AppCard(child: Text('Bạn chưa có giao dịch nào.', textAlign: TextAlign.center, style: text.bodySmall))
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) Divider(height: 1, indent: 72, color: t.border),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs),
                      leading: PaymentMethodBadge(method: items[i].method),
                      title: Text(items[i].packageName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        [
                          paymentMethodName(items[i].method),
                          if (items[i].createdAt != null) formatDateTime(items[i].createdAt!),
                        ].join(' · '),
                        style: text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatVnd(items[i].amount), style: text.titleSmall),
                          const SizedBox(height: 2),
                          TransactionStatusChip(items[i].status),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
