// Khớp backend/Dtos/PaymentDtos.cs

/// "49000" -> "49.000đ"
String formatVnd(num amount) {
  final digits = amount.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  buffer.write('đ');
  return buffer.toString();
}

/// Backend trả giờ UTC nhưng không kèm "Z" -> tự thêm để Dart không hiểu nhầm là giờ máy
DateTime? parseServerDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final hasZone = value.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(value);
  return DateTime.tryParse(hasZone ? value : '${value}Z')?.toLocal();
}

/// "04/11/2026 14:05"
String formatDateTime(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "04/11/2026"
String formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class VipPackage {
  final String code; // 'month_basic' | 'month_pro' | 'quarter_pro'
  final String name;
  final int price;
  final int durationDays;
  final int aiTokenLimit;
  final String? description;
  final String? badge;

  const VipPackage({
    required this.code,
    required this.name,
    required this.price,
    required this.durationDays,
    this.aiTokenLimit = 0,
    this.description,
    this.badge,
  });

  int get months => (durationDays / 30).round().clamp(1, 120);

  /// "/ tháng" hoặc "/ 3 tháng"
  String get periodLabel => months == 1 ? '/ tháng' : '/ $months tháng';

  /// Giá quy ra 1 tháng (gói nhiều tháng)
  int get monthlyPrice => (price / months).round();

  factory VipPackage.fromJson(Map<String, dynamic> json) => VipPackage(
        code: json['code'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).round(),
        durationDays: json['durationDays'] as int? ?? 30,
        aiTokenLimit: json['aiTokenLimit'] as int? ?? 0,
        description: json['description'] as String?,
        badge: json['badge'] as String?,
      );
}

class PaymentMethodOption {
  final String code; // 'MoMo' | 'VNPay' | 'ZaloPay' | 'VietQR'
  final String name;
  final String description;
  final bool isAvailable;

  const PaymentMethodOption({required this.code, required this.name, this.description = '', this.isAvailable = true});

  factory PaymentMethodOption.fromJson(Map<String, dynamic> json) => PaymentMethodOption(
        code: json['code'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        isAvailable: json['isAvailable'] as bool? ?? false,
      );
}

class BankTransfer {
  final String bankName;
  final String accountNo;
  final String accountName;
  final String content;

  const BankTransfer({required this.bankName, required this.accountNo, required this.accountName, required this.content});

  factory BankTransfer.fromJson(Map<String, dynamic> json) => BankTransfer(
        bankName: json['bankName'] as String? ?? '',
        accountNo: json['accountNo'] as String? ?? '',
        accountName: json['accountName'] as String? ?? '',
        content: json['content'] as String? ?? '',
      );
}

/// Kết quả POST api/payment/checkout
class CheckoutResult {
  final int orderCode;
  final int amount;
  final String packageCode;
  final String packageName;
  final String method;
  final String status;
  final DateTime? expiresAt;

  /// true = chế độ giả lập: app tự hiện trang thanh toán giả, không mở [paymentUrl]
  final bool isMock;
  final String? paymentUrl;
  final String? qrImageUrl;
  final BankTransfer? bankTransfer;

  const CheckoutResult({
    required this.orderCode,
    required this.amount,
    required this.packageCode,
    required this.packageName,
    required this.method,
    this.status = 'Pending',
    this.expiresAt,
    this.isMock = true,
    this.paymentUrl,
    this.qrImageUrl,
    this.bankTransfer,
  });

  factory CheckoutResult.fromJson(Map<String, dynamic> json) => CheckoutResult(
        orderCode: json['orderCode'] as int,
        amount: (json['amount'] as num).round(),
        packageCode: json['packageCode'] as String? ?? '',
        packageName: json['packageName'] as String? ?? '',
        method: json['method'] as String,
        status: json['status'] as String? ?? 'Pending',
        expiresAt: parseServerDate(json['expiresAt']),
        isMock: json['isMock'] as bool? ?? true,
        paymentUrl: json['paymentUrl'] as String?,
        qrImageUrl: json['qrImageUrl'] as String?,
        bankTransfer: json['bankTransfer'] == null ? null : BankTransfer.fromJson(json['bankTransfer'] as Map<String, dynamic>),
      );
}

/// Nhãn tiếng Việt của trạng thái giao dịch
String transactionStatusLabel(String status) => switch (status) {
      PaymentTransaction.pending => 'Đang chờ',
      PaymentTransaction.paid => 'Thành công',
      PaymentTransaction.failed => 'Thất bại',
      PaymentTransaction.cancelled => 'Đã hủy',
      _ => status,
    };

/// 1 giao dịch (lịch sử thanh toán / trạng thái đang chờ)
class PaymentTransaction {
  static const pending = 'Pending';
  static const paid = 'Paid';
  static const failed = 'Failed';
  static const cancelled = 'Cancelled';

  final int orderCode;
  final int amount;
  final String packageCode;
  final String packageName;
  final String method;
  final String status;
  final String? failureReason;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? expiresAt;

  const PaymentTransaction({
    required this.orderCode,
    required this.amount,
    required this.packageCode,
    required this.packageName,
    required this.method,
    required this.status,
    this.failureReason,
    this.createdAt,
    this.paidAt,
    this.expiresAt,
  });

  bool get isPending => status == pending;
  bool get isPaid => status == paid;

  String get statusLabel => transactionStatusLabel(status);

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) => PaymentTransaction(
        orderCode: json['orderCode'] as int,
        amount: (json['amount'] as num).round(),
        packageCode: json['packageCode'] as String? ?? '',
        packageName: json['packageName'] as String? ?? '',
        method: json['method'] as String? ?? '',
        status: json['status'] as String? ?? pending,
        failureReason: json['failureReason'] as String?,
        createdAt: parseServerDate(json['createdAt']),
        paidAt: parseServerDate(json['paidAt']),
        expiresAt: parseServerDate(json['expiresAt']),
      );
}
