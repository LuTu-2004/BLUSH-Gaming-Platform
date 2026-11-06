import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../models/admin_model.dart';
import '../../models/payment_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';
import 'admin_widgets.dart';

/// "4,5" - điểm trung bình kiểu Việt Nam (dấu phẩy thập phân)
String formatAverage(double? average) => average == null ? '—' : average.toStringAsFixed(1).replaceAll('.', ',');

/// Trang Lịch sử đánh giá: điểm trung bình, phân bố 1-5 sao, ai đánh giá mấy sao + góp ý (api/admin/ratings).
class AdminRatingsPage extends StatefulWidget {
  const AdminRatingsPage({super.key});

  @override
  State<AdminRatingsPage> createState() => _AdminRatingsPageState();
}

class _AdminRatingsPageState extends State<AdminRatingsPage> {
  late final AdminService _service = AdminService(context.read<AuthService>());
  final _searchController = TextEditingController();
  int? _stars; // null = mọi mức sao
  final List<AdminRating> _items = [];
  AdminRatingPage? _lastPage; // giữ số liệu tổng
  int _page = 0;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    _items.clear();
    _page = 0;
    await _loadMore();
  }

  Future<void> _loadMore() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _service.getRatings(stars: _stars, search: _searchController.text, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _lastPage = page;
        _page = page.page;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter(int? stars) {
    setState(() => _stars = stars);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final stats = _lastPage?.stats;
    final total = _lastPage?.total ?? 0;

    return AdminPage(
      children: [
        // ── Tổng quan: điểm trung bình + phân bố (bấm 1 mức sao để lọc) ──
        AdminPanel(
          title: 'Điểm đánh giá',
          subtitle: 'Mỗi người 1 đánh giá, sửa lại thì tính theo lần mới nhất',
          child: stats == null
              ? const Padding(padding: EdgeInsets.all(AppSpace.lg), child: Center(child: CircularProgressIndicator()))
              : RatingSummary(stats: stats, selected: _stars, onSelect: (s) => _filter(s == _stars ? null : s)),
        ),
        const SizedBox(height: AppSpace.md),

        // ── Bộ lọc ────────────────────────────────────────────
        AdminPanel(
          title: 'Bộ lọc',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _reload(),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên hoặc email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(tooltip: 'Tìm', icon: const Icon(Icons.arrow_forward), onPressed: _reload),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  ChoiceChip(label: const Text('Mọi mức sao'), selected: _stars == null, onSelected: (_) => _filter(null)),
                  for (var s = 5; s >= 1; s--)
                    ChoiceChip(
                      label: Text(stats == null ? '$s★' : '$s★ (${stats.countOf(s)})'),
                      selected: _stars == s,
                      onSelected: (_) => _filter(s),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),

        // ── Danh sách ─────────────────────────────────────────
        AdminPanel(
          title: '$total đánh giá${_stars == null ? '' : ' $_stars sao'}',
          action: IconButton(tooltip: 'Tải lại', icon: const Icon(Icons.refresh), onPressed: _loading ? null : _reload),
          padding: EdgeInsets.zero,
          child: _error != null
              ? Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Column(children: [Text(_error!, textAlign: TextAlign.center), TextButton(onPressed: _loadMore, child: const Text('Thử lại'))]),
                )
              : _items.isEmpty && _loading
                  ? const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator()))
                  : _items.isEmpty
                      ? Padding(padding: const EdgeInsets.all(AppSpace.xl), child: Text('Chưa có đánh giá phù hợp.', textAlign: TextAlign.center, style: text.bodySmall))
                      : Column(
                          children: [
                            for (var i = 0; i < _items.length; i++) ...[
                              if (i > 0) Divider(height: 1, color: t.border),
                              _RatingTile(rating: _items[i]),
                            ],
                          ],
                        ),
        ),
        if (_items.length < total) ...[
          const SizedBox(height: AppSpace.md),
          Center(
            child: OutlinedButton(
              onPressed: _loading ? null : _loadMore,
              child: Text(_loading ? 'Đang tải...' : 'Tải thêm (${total - _items.length})'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Hàng sao: [value] có thể lẻ (4,5 -> 4 sao đầy + nửa sao)
class StarRow extends StatelessWidget {
  final double value;
  final double size;

  const StarRow({super.key, required this.value, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final muted = context.watch<ThemeService>().textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            value >= i ? Icons.star_rounded : (value >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
            size: size,
            color: value >= i - 0.5 ? ThemeService.yellow : muted,
          ),
      ],
    );
  }
}

/// Điểm trung bình lớn bên trái + thanh phân bố 5 → 1 sao bên phải.
/// Có [onSelect]: bấm 1 thanh để lọc theo mức sao đó ([selected] được tô đậm).
class RatingSummary extends StatelessWidget {
  final AdminRatingStats stats;
  final int? selected;
  final ValueChanged<int>? onSelect;

  const RatingSummary({super.key, required this.stats, this.selected, this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final maxCount = stats.byStars.fold<int>(0, (a, b) => a > b ? a : b);

    final average = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(formatAverage(stats.average), style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpace.xs),
        StarRow(value: stats.average ?? 0, size: 20),
        const SizedBox(height: AppSpace.xs),
        // Chữ to nhưng giữ đúng chiều cao dòng cũ (~17px) và luôn 1 dòng:
        // khung này nằm trong SplitRow cao bằng khung bên cạnh, cao thêm là tràn
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('${stats.count} lượt đánh giá', maxLines: 1, style: text.bodyMedium?.copyWith(fontSize: 15, height: 1.1, fontWeight: FontWeight.w600)),
        ),
      ],
    );

    Widget bar(int stars) {
      final count = stats.countOf(stars);
      final active = selected == null || selected == stars;
      return InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onSelect == null ? null : () => onSelect!(stars),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: AppSpace.xs),
          child: Row(
            children: [
              SizedBox(width: 28, child: Text('$stars★', style: text.labelMedium)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: maxCount == 0 ? 0 : count / maxCount,
                    minHeight: 8,
                    backgroundColor: t.cardHigh,
                    color: ThemeService.yellow.withValues(alpha: active ? 1 : 0.35),
                  ),
                ),
              ),
              SizedBox(width: 36, child: Text('$count', style: text.labelMedium, textAlign: TextAlign.right)),
            ],
          ),
        ),
      );
    }

    final bars = Column(mainAxisSize: MainAxisSize.min, children: [for (var s = 5; s >= 1; s--) bar(s)]);

    // Không dùng LayoutBuilder: Tổng quan đặt khung này trong SplitRow (IntrinsicHeight)
    return Row(
      children: [
        SizedBox(width: 120, child: average),
        const SizedBox(width: AppSpace.md),
        Expanded(child: bars),
      ],
    );
  }
}

class _RatingTile extends StatelessWidget {
  final AdminRating rating;

  const _RatingTile({required this.rating});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final r = rating;
    final date = r.updatedAt == null ? '' : formatDateTime(r.updatedAt!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(imageUrl: r.avatarUrl, fallback: r.displayName.isNotEmpty ? r.displayName[0].toUpperCase() : '?', size: 40),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(r.displayName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: AppSpace.sm),
                    Text(r.isEdited ? '$date · đã sửa' : date, style: text.bodySmall),
                  ],
                ),
                Text(r.email, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpace.xs),
                StarRow(value: r.stars.toDouble()),
                if (r.comment != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(r.comment!, style: text.bodyMedium),
                ] else
                  Text('Không để lại góp ý', style: text.bodySmall?.copyWith(color: t.textMuted, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
