import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String teammateName;
  final String teammateAvatar;

  const ChatRoomScreen({
    super.key,
    this.teammateName = 'Thùy Dung Valorant',
    this.teammateAvatar = '🌸',
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  static const _icebreakers = [
    'Hôm nay cậu chơi Valorant hay Tốc Chiến? Cần kéo rank hay tấu hài nhè nhẹ nè? 🎮',
    'Bình thường cậu hay mở nhạc gì lúc tryhard game thế? Cho tớ xin vài bài với 🎶',
    'Chủ nhật của cậu thường là ngủ nướng hay leo rank từ sáng sớm vậy? ☀️',
  ];

  final List<Map<String, String>> _messages = [
    {
      'sender': 'ai',
      'text': '🎉 Chào mừng 2 bạn đã ghép đội thành công với Độ Tương Thích 94%! Hãy bắt đầu trò chuyện nào!',
      'time': '14:20',
    },
    {
      'sender': 'them',
      'text': 'Hi bạn! Hôm nay tính leo rank hay chơi tấu hài nè?',
      'time': '14:21',
    },
  ];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'me', 'text': text, 'time': _formatTime(DateTime.now())});
    });
    _textController.clear();

    // Đợi frame vẽ xong tin mới rồi mới cuộn xuống cuối
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // AI gợi ý câu mở đầu: điền vào ô nhập để người dùng sửa trước khi gửi
  void _generateAiIcebreaker() {
    final suggestion = (List.of(_icebreakers)..shuffle()).first;
    _textController.text = suggestion;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.header,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: ThemeService.blurple.withValues(alpha: 0.2),
              child: Text(widget.teammateAvatar, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.teammateName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textPrimary)),
                const Row(
                  children: [
                    Icon(Icons.circle, color: ThemeService.green, size: 8),
                    SizedBox(width: 4),
                    Text('Đang Online • 94% Match Score', style: TextStyle(color: ThemeService.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            )
          ],
        ),
      ),
      body: Column(
        children: [
          // Icebreaker mission banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: ThemeService.blurple.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Text('🧊', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nhiệm Vụ Phá Băng AI (+20 EXP)', style: TextStyle(color: ThemeService.blurple, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Hỏi ${widget.teammateName} về skin yêu thích nhất để mở lời trò chuyện!', style: TextStyle(color: theme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _generateAiIcebreaker,
                  icon: const Text('🤖', style: TextStyle(fontSize: 14)),
                  label: const Text('AI Gợi Ý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: ThemeService.blurple),
                ),
              ],
            ),
          ),

          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender'] == 'me';
                final isAi = msg['sender'] == 'ai';

                if (isAi) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ThemeService.blurple.withValues(alpha: 0.3)),
                    ),
                    child: Text(msg['text']!, textAlign: TextAlign.center, style: TextStyle(color: theme.textMuted, fontSize: 12)),
                  );
                }

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: isMe ? ThemeService.blurple : theme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(msg['text']!, style: TextStyle(color: isMe ? Colors.white : theme.textPrimary, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(msg['time']!, style: TextStyle(color: isMe ? Colors.white70 : theme.textMuted, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Message input bar
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn với ${widget.teammateName}...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: theme.bg,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: ThemeService.blurple),
                  onPressed: () => _sendMessage(),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
