import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../models/chat_model.dart';
import '../models/feed_model.dart';
import '../services/auth_service.dart';
import '../services/feed_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'auth_widgets.dart';
import 'block_user.dart';
import 'report_user_sheet.dart';
import 'ui.dart';

/// 1 bài đăng: thả tim, bình luận, menu (gỡ bài của mình / báo cáo, chặn người khác).
/// [onChanged] = bài thay đổi (tim, số bình luận); [onRemoved] = bài đã gỡ; [onAuthorBlocked] = vừa chặn người đăng (ẩn mọi bài của họ).
class PostCard extends StatefulWidget {
  final Post post;
  final bool showZone;
  final ValueChanged<Post> onChanged;
  final VoidCallback onRemoved;
  final VoidCallback onAuthorBlocked;

  const PostCard({super.key, required this.post, this.showZone = false, required this.onChanged, required this.onRemoved, required this.onAuthorBlocked});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late final FeedService _service = FeedService(context.read<AuthService>());
  bool _liking = false;

  Post get _post => widget.post;

  Future<void> _toggleLike() async {
    if (_liking) return;
    final like = !_post.likedByMe;
    // Đổi ngay trên màn hình cho mượt, lỗi thì trả lại như cũ
    widget.onChanged(_post.copyWith(likedByMe: like, likeCount: _post.likeCount + (like ? 1 : -1)));
    setState(() => _liking = true);
    try {
      final count = await _service.setLike(_post.id, like);
      widget.onChanged(_post.copyWith(likedByMe: like, likeCount: count));
    } on ApiException catch (e) {
      widget.onChanged(_post.copyWith(likedByMe: !like, likeCount: _post.likeCount + (like ? -1 : 1)));
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _onMenu(String action) async {
    final author = _post.author;
    switch (action) {
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Gỡ bài viết?'),
            content: const Text('Bài viết sẽ không hiện với ai nữa.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gỡ')),
            ],
          ),
        );
        if (ok != true || !mounted) return;
        try {
          await _service.deletePost(_post.id);
          widget.onRemoved();
          if (mounted) showSuccessSnack(context, 'Đã gỡ bài viết.');
        } on ApiException catch (e) {
          if (mounted) showErrorSnack(context, e.message);
        }
      case 'report':
        ReportUserSheet.show(context, userId: author.id, displayName: author.displayName);
      case 'block':
        if (await confirmAndBlockUser(context, userId: author.id, displayName: author.displayName)) {
          widget.onAuthorBlocked();
        }
    }
  }

  void _openComments() => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        // widget.post đọc lúc gọi (không phải lúc mở bảng) để không ghi đè số tim vừa đổi
        builder: (_) => _CommentsSheet(post: _post, onCountChanged: (n) => widget.onChanged(widget.post.copyWith(commentCount: n))),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeService>();
    final text = Theme.of(context).textTheme;
    final myId = context.read<AuthService>().currentUser?.id;
    final mine = _post.author.id == myId;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(imageUrl: _post.author.avatarUrl, fallback: _post.author.avatarEmoji, size: 40),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(_post.author.displayName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (_post.author.isVip) ...[
                          const SizedBox(width: AppSpace.xs),
                          const Tooltip(message: 'Thành viên BLUSH Pass', child: Icon(Icons.workspace_premium, size: 16, color: ThemeService.yellow)),
                        ],
                      ],
                    ),
                    Text(
                      [if (widget.showZone) _post.zoneName, formatChatTime(_post.createdAt)].join(' · '),
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Tùy chọn bài viết',
                icon: Icon(Icons.more_vert, color: t.textMuted),
                onSelected: _onMenu,
                itemBuilder: (_) => [
                  if (_post.canDelete) const PopupMenuItem(value: 'delete', child: Text('Gỡ bài viết')),
                  if (!mine) ...[
                    const PopupMenuItem(value: 'report', child: Text('Báo cáo vi phạm')),
                    const PopupMenuItem(value: 'block', child: Text('Chặn người đăng')),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          if (_post.isHeld) ...[
            const TagChip('AI tạm ẩn · chờ Staff duyệt', color: Colors.orange, icon: Icons.visibility_off_outlined),
            const SizedBox(height: AppSpace.sm),
          ],
          Text(_post.content, style: text.bodyMedium),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              TextButton.icon(
                onPressed: _toggleLike,
                style: TextButton.styleFrom(foregroundColor: _post.likedByMe ? ThemeService.red : t.textMuted),
                icon: Icon(_post.likedByMe ? Icons.favorite : Icons.favorite_border, size: 20),
                label: Text('${_post.likeCount}'),
              ),
              TextButton.icon(
                onPressed: _openComments,
                style: TextButton.styleFrom(foregroundColor: t.textMuted),
                icon: const Icon(Icons.mode_comment_outlined, size: 20),
                label: Text('${_post.commentCount}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bình luận của 1 bài. Thêm / xóa bình luận thì báo số mới qua [onCountChanged].
class _CommentsSheet extends StatefulWidget {
  final Post post;
  final ValueChanged<int> onCountChanged;

  const _CommentsSheet({required this.post, required this.onCountChanged});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  late final FeedService _service = FeedService(context.read<AuthService>());
  final _input = TextEditingController();
  List<Comment>? _comments;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final comments = await _service.getComments(widget.post.id);
      if (mounted) setState(() => _comments = comments);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _send() async {
    if (_input.text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final comment = await _service.addComment(widget.post.id, _input.text);
      if (!mounted) return;
      if (comment.isHeld) showErrorSnack(context, heldByAiMessage);
      _input.clear();
      setState(() => _comments = [...?_comments, comment]);
      widget.onCountChanged(_comments!.length);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(Comment c) async {
    try {
      await _service.deleteComment(c.id);
      if (!mounted) return;
      setState(() => _comments = _comments!.where((x) => x.id != c.id).toList());
      widget.onCountChanged(_comments!.length);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final comments = _comments;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          children: [
            Text('Bình luận', style: text.titleMedium),
            const SizedBox(height: AppSpace.sm),
            Expanded(
              child: _error != null
                  ? Center(child: Text(_error!))
                  : comments == null
                      ? const Center(child: CircularProgressIndicator())
                      : comments.isEmpty
                          ? Center(child: Text('Chưa có bình luận. Mở đầu đi!', style: text.bodySmall))
                          : ListView(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                              children: [
                                for (final c in comments)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: AppAvatar(imageUrl: c.author.avatarUrl, fallback: c.author.avatarEmoji, size: 32),
                                    title: Text(c.author.displayName, style: text.labelLarge),
                                    subtitle: c.isHeld
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(c.content, style: text.bodyMedium),
                                              const SizedBox(height: AppSpace.xs),
                                              const TagChip('AI tạm ẩn · chờ Staff duyệt', color: Colors.orange, icon: Icons.visibility_off_outlined),
                                            ],
                                          )
                                        : Text(c.content, style: text.bodyMedium),
                                    trailing: c.canDelete
                                        ? IconButton(tooltip: 'Xóa bình luận', icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _delete(c))
                                        : null,
                                  ),
                              ],
                            ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.sm, AppSpace.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        maxLength: 500,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(hintText: 'Viết bình luận...', counterText: ''),
                      ),
                    ),
                    IconButton(tooltip: 'Gửi bình luận', onPressed: _sending ? null : _send, icon: const Icon(Icons.send_rounded)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
