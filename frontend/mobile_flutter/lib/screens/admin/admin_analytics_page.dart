import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_client.dart';
import '../../models/admin_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import 'admin_widgets.dart';

/// Mở Google Analytics trên trình duyệt: đúng property nếu biết, không thì trang chủ GA
Future<void> openGoogleAnalytics([String? propertyId]) => launchUrl(
      Uri.parse(propertyId == null
          ? 'https://analytics.google.com/analytics/web/'
          : 'https://analytics.google.com/analytics/web/#/p$propertyId/reports/intelligenthome'),
      mode: LaunchMode.externalApplication,
    );

/// "12.345" - số có dấu chấm ngăn hàng nghìn
String _num(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

/// Trang Google Analytics: người xem landing page theo nguồn, lượt bấm tải APK, người dùng app,
/// hành trình trong app (api/admin/analytics). Chi tiết hơn thì bấm "Mở Google Analytics".
class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  late final AdminService _service = AdminService(context.read<AuthService>());
  int _days = 30;
  AdminAnalytics? _data;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final data = await _service.getAnalytics(days: _days);
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = context.watch<ThemeService>();
    final d = _data;
    final fetched = d?.fetchedAt;

    return AdminPage(
      children: [
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 ngày')),
                ButtonSegment(value: 30, label: Text('30 ngày')),
                ButtonSegment(value: 90, label: Text('90 ngày')),
              ],
              selected: {_days},
              showSelectedIcon: false,
              onSelectionChanged: (v) {
                setState(() => _days = v.first);
                _load();
              },
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Làm mới'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => openGoogleAnalytics(d?.propertyId),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Mở Google Analytics'),
            ),
            if (fetched != null)
              Text(
                'Số liệu lúc ${fetched.hour.toString().padLeft(2, '0')}:${fetched.minute.toString().padLeft(2, '0')} · GA có thể trễ vài giờ',
                style: text.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        if (_error != null)
          AdminPanel(
            title: 'Không tải được số liệu',
            action: TextButton(onPressed: _load, child: const Text('Thử lại')),
            child: Text(_error!, style: text.bodyMedium),
          )
        else if (d == null)
          const Padding(padding: EdgeInsets.all(AppSpace.xxl), child: Center(child: CircularProgressIndicator()))
        else if (!d.available)
          _NotConnected(message: d.message ?? 'Chưa kết nối Google Analytics.')
        else ...[
          ResponsiveGrid(
            minItemWidth: 240,
            children: [
              KpiCard(
                label: 'Đang online',
                value: _num(d.realtimeUsers),
                caption: 'Trong 30 phút qua (web + app)',
                icon: Icons.sensors,
                color: ThemeService.green,
                highlight: true,
              ),
              KpiCard(
                label: 'Người xem landing page',
                value: _num(d.webUsers),
                caption: '${_num(d.webSessions)} phiên · ${_num(d.webPageViews)} lượt xem',
                icon: Icons.language,
                color: ThemeService.cyan,
              ),
              KpiCard(
                label: 'Lượt bấm tải APK',
                value: _num(d.downloadClicks),
                caption: d.webUsers == 0 ? 'Chưa có người xem' : '${(d.downloadClicks * 100 / d.webUsers).round()}% người xem bấm tải',
                icon: Icons.download_outlined,
                color: ThemeService.accent,
              ),
              KpiCard(
                label: 'Người dùng app',
                value: _num(d.appUsers),
                caption: '+${_num(d.appNewUsers)} người mới trong $_days ngày',
                icon: Icons.phone_android,
                color: ThemeService.yellow,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          AdminPanel(
            title: 'Người dùng mỗi ngày',
            subtitle: 'Landing page (web) và app Android',
            child: _DailyUsersChart(daily: d.daily),
          ),
          const SizedBox(height: AppSpace.md),
          SplitRow(
            left: AdminPanel(
              title: 'Nguồn truy cập landing page',
              subtitle: 'Theo utm_source trên link, hoặc trang dẫn tới',
              padding: EdgeInsets.zero,
              child: _SourceTable(sources: d.sources),
            ),
            right: AdminPanel(
              title: 'Hành trình trong app',
              subtitle: 'Số lần mỗi sự kiện trong $_days ngày',
              child: _EventList(events: d.appEvents),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'Nguồn "(direct)" = mở link trực tiếp không kèm utm_source. Khi đăng link lên Facebook / TikTok / Zalo, '
            'thêm ?utm_source=facebook (tiktok, zalo...) để biết chính xác kênh nào mang người dùng về.',
            style: text.bodySmall?.copyWith(color: t.textMuted),
          ),
        ],
      ],
    );
  }
}

/// Chưa cấu hình / GA từ chối: lời nhắn từ backend + các bước kết nối
class _NotConnected extends StatelessWidget {
  final String message;

  const _NotConnected({required this.message});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const steps = [
      'analytics.google.com → Admin → Property access management: thêm email service account Firebase với vai trò Viewer.',
      'Admin → Property details: copy Property ID (dãy số, khác mã G-...).',
      'Điền vào backend/appsettings.json → "GoogleAnalytics": { "PropertyId": "..." } rồi chạy lại backend.',
    ];
    return AdminPanel(
      title: 'Chưa kết nối Google Analytics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: ThemeService.yellow, size: 20),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text(message, style: text.bodyMedium)),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Text('${i + 1}. ${steps[i]}', style: text.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// Cột đôi mỗi ngày: web (xanh) + app (tím). Chạm 1 ngày để xem số.
class _DailyUsersChart extends StatefulWidget {
  final List<AnalyticsDaily> daily;

  const _DailyUsersChart({required this.daily});

  @override
  State<_DailyUsersChart> createState() => _DailyUsersChartState();
}

class _DailyUsersChartState extends State<_DailyUsersChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final daily = widget.daily;
    if (daily.isEmpty) return Text('Chưa có dữ liệu.', style: text.bodySmall, textAlign: TextAlign.center);

    final maxValue = daily.fold<int>(1, (m, d) => [m, d.webUsers, d.appUsers].reduce((a, b) => a > b ? a : b));
    final picked = daily[_selected ?? daily.length - 1];
    String day(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

    Widget legend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(label, style: text.bodySmall),
        ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(_selected == null ? 'Hôm nay' : day(picked.date), style: text.titleSmall),
            const Spacer(),
            Text('Web ${_num(picked.webUsers)} · App ${_num(picked.appUsers)}', style: text.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < daily.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selected = i),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: daily.length > 40 ? 0.5 : 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final (value, color) in [(daily[i].webUsers, ThemeService.cyan), (daily[i].appUsers, ThemeService.accent)])
                            Expanded(
                              child: Container(
                                height: value == 0 ? 2 : 160 * value / maxValue,
                                decoration: BoxDecoration(
                                  color: value == 0 ? t.cardHigh : color.withValues(alpha: _selected == null || _selected == i ? 1 : 0.45),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            Text(day(daily.first.date), style: text.labelSmall),
            const Spacer(),
            legend(ThemeService.cyan, 'Landing page'),
            const SizedBox(width: AppSpace.md),
            legend(ThemeService.accent, 'App'),
            const Spacer(),
            Text(day(daily.last.date), style: text.labelSmall),
          ],
        ),
      ],
    );
  }
}

/// Bảng nguồn: tên | phiên | người | bấm tải APK
class _SourceTable extends StatelessWidget {
  final List<AnalyticsSource> sources;

  const _SourceTable({required this.sources});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    if (sources.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Text('Chưa có lượt truy cập landing page.', style: text.bodySmall, textAlign: TextAlign.center),
      );
    }

    Widget row(List<String> cells, {bool header = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(cells[0], style: header ? text.labelMedium : text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
              for (final c in cells.skip(1))
                Expanded(flex: 2, child: Text(c, style: header ? text.labelMedium : text.bodyMedium, textAlign: TextAlign.right)),
            ],
          ),
        );

    return Column(
      children: [
        Container(color: t.cardHigh.withValues(alpha: 0.5), child: row(['Nguồn', 'Phiên', 'Người', 'Bấm tải'], header: true)),
        for (final s in sources) ...[
          Divider(height: 1, color: t.border),
          row([s.source, _num(s.sessions), _num(s.users), _num(s.downloads)]),
        ],
      ],
    );
  }
}

/// Mỗi sự kiện 1 thanh, dài theo số lần so với sự kiện nhiều nhất
class _EventList extends StatelessWidget {
  final List<AnalyticsEvent> events;

  const _EventList({required this.events});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final maxCount = events.fold<int>(0, (m, e) => e.count > m ? e.count : m);

    return Column(
      children: [
        for (final e in events)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 170, child: Text(e.label, style: text.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: maxCount == 0 ? 0 : e.count / maxCount,
                      minHeight: 8,
                      backgroundColor: t.cardHigh,
                      color: ThemeService.accent,
                    ),
                  ),
                ),
                SizedBox(width: 56, child: Text(_num(e.count), style: text.labelMedium, textAlign: TextAlign.right)),
              ],
            ),
          ),
      ],
    );
  }
}
