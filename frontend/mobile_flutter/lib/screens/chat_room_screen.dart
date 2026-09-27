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
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'ai',
      'text': '🎉 Chào mừng 2 bạn đã ghép đội thành công với Độ Tương Thích 94%! Hãy cùng chinh phục Valorant nào!',
      'time': '14:20',
    },
    {
      'sender': 'them',
      'text': 'Hi bạn! Hôm nay tính leo rank Valorant hay chơi ARAM tấu hài nè?',
      'time': '14:21',
    },
    {
      'sender': 'me',
      'text': 'Chào Thùy Dung! Mình tính kéo rank Valorant đây, bạn pick Initiator hay Duelist?',
      'time': '14:22',
    },
  ];

  final TextEditingController _textController = TextEditingController();

  void _sendMessage([String? customText]) {
    final text = customText ?? _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'me',
        'text': text,
        'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
    });

    if (customText == null) {
      _textController.clear();
    }
  }

  void _generateAiIcebreaker() {
    final icebreakers = [
      'Hôm nay cậu chơi Valorant hay Tốc Chiến? Cần kéo rank hay tấu hài nhè nhẹ nè? 🎮',
      'Bình thường cậu hay mở nhạc gì lúc tryhard game thế? Cho tớ xin vài bài với 🎶',
      'Chủ nhật của cậu thường là ngủ nướng hay leo rank từ sáng sớm vậy? ☀️',
    ];

    final randomMessage = (icebreakers..shuffle()).first;
    _sendMessage(randomMessage);
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
              backgroundColor: ThemeService.blurple.withOpacity(0.2),
              child: Text(widget.teammateAvatar, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.teammateName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textPrimary)),
                Row(
                  children: const [
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
            color: ThemeService.blurple.withOpacity(0.15),
            child: Row(
              children: [
                const Text('🧊', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nhiệm Vụ Phá Băng AI (+20 EXP)', style: TextStyle(color: ThemeService.blurple, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Hỏi bạn ấy về skin Valorant yêu thích nhất để mở lời trò chuyện!', style: TextStyle(color: theme.textMuted, fontSize: 11)),
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
                      border: Border.all(color: ThemeService.blurple.withOpacity(0.3)),
                    ),
                    child: Text(msg['text'] as String, textAlign: TextAlign.center, style: TextStyle(color: theme.textMuted, fontSize: 12)),
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
                        Text(msg['text'] as String, style: TextStyle(color: isMe ? Colors.white : theme.textPrimary, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(msg['time'] as String, style: TextStyle(color: isMe ? Colors.white70 : theme.textMuted, fontSize: 10)),
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
