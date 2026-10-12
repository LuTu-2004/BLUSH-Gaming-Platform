import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/chat_model.dart';
import '../services/auth_service.dart';
import '../services/block_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ui.dart';

/// Hồ sơ → Người đã chặn: xem và bỏ chặn (GET / DELETE api/blocks)
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late final BlockService _service = BlockService(context.read<AuthService>());
  List<ChatUser>? _users;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final users = await _service.getBlocked();
      if (mounted) setState(() => _users = users);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _unblock(ChatUser user) async {
    try {
      await _service.unblock(user.id);
      if (!mounted) return;
      setState(() => _users = _users!.where((u) => u.id != user.id).toList());
      showSuccessSnack(context, 'Đã bỏ chặn ${user.displayName}.');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final users = _users;

    Widget body;
    if (_error != null) {
      body = Center(
        child: Padding(
          padding: AppSpace.page,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.lg),
              ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    } else if (users == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (users.isEmpty) {
      body = Center(child: Padding(padding: AppSpace.page, child: Text('Bạn chưa chặn ai.', style: text.bodyMedium)));
    } else {
      body = ListView.separated(
        itemCount: users.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: t.border),
        itemBuilder: (_, i) => ListTile(
          leading: AppAvatar(imageUrl: users[i].avatarUrl, fallback: users[i].avatarEmoji, size: 40),
          title: Text(users[i].displayName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: OutlinedButton(onPressed: () => _unblock(users[i]), child: const Text('Bỏ chặn')),
        ),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Người đã chặn')), body: body);
  }
}
