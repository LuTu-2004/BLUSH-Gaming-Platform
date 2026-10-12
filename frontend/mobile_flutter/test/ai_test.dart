import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:blush_mobile_app/screens/chat_room_screen.dart';
import 'package:blush_mobile_app/screens/match_feed_screen.dart';
import 'package:blush_mobile_app/screens/vip_screen.dart';
import 'package:blush_mobile_app/services/auth_service.dart';
import 'package:blush_mobile_app/services/quest_service.dart';
import 'package:blush_mobile_app/services/theme_service.dart';

import 'test_helpers.dart';

const _usage = {'tier': 'Free', 'usedToday': 1, 'dailyLimit': 3, 'tokensUsedThisMonth': 549, 'monthlyTokenLimit': 20000};

/// [aiMode]: 'ok' | 'quota' (429 hết lượt) | 'busy' (503 AI đang bận)
Future<AuthService> _gamer(List<http.Request> requests, {String aiMode = 'ok'}) async {
  final backend = fakeBackend();
  final auth = createAuth((req) async {
    requests.add(req);
    final path = req.url.path;
    if (path.startsWith('/api/ai/')) {
      if (path.endsWith('/report')) return jsonResponse({'message': 'Cảm ơn bạn đã báo cáo.'});
      if (aiMode == 'quota') {
        return jsonResponse({'message': 'Bạn đã dùng hết 3 lượt AI miễn phí hôm nay. Nâng cấp BLUSH Pass để có thêm lượt.', 'code': 'AI_QUOTA_EXCEEDED'}, 429);
      }
      if (aiMode == 'busy') return jsonResponse({'message': 'AI đang bận, bạn thử lại sau nhé.', 'code': 'AI_UNAVAILABLE'}, 503);
      if (path.endsWith('/suggest')) {
        return jsonResponse({'logId': 'log-1', 'suggestions': ['Tối nay leo rank không bạn?', 'Bạn main tướng gì?', 'Cùng TP.HCM nè!'], 'usage': _usage});
      }
      return jsonResponse({'logId': 'log-2', 'explanation': 'Hai bạn cùng chơi Liên Quân buổi tối và đều hay bật mic.', 'usage': _usage});
    }
    return backend(req);
  });
  await auth.login('gamer@blush.vn', '123456');
  return auth;
}

Widget _wrap(AuthService auth, Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => QuestService()),
      ],
      child: MaterialApp(home: home),
    );

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

const _room = ChatRoomScreen(userId: 'u-toxic', displayName: 'ToxicGamer99');

void main() {
  setUpAll(loadRobotoFromSdk);

  testWidgets('chat: bấm Gợi ý từ AI, chọn 1 câu thì điền vào ô nhập; báo cáo được câu trả lời', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests), _room));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Gợi ý từ AI'));
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/api/ai/chat/room-1/suggest');
    expect(find.text('Tạo bởi AI · Còn 2 lượt AI hôm nay'), findsOneWidget);

    await tester.tap(find.text('Báo cáo nội dung không phù hợp'));
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/api/ai/logs/log-1/report');

    await tester.tap(find.text('Bạn main tướng gì?'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Bạn main tướng gì?');
  });

  testWidgets('chat: hết lượt AI thì mời xem BLUSH Pass', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(_wrap(await _gamer([], aiMode: 'quota'), _room));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Gợi ý từ AI'));
    await tester.pumpAndSettle();
    expect(find.text('Hết lượt AI'), findsOneWidget);
    await tester.tap(find.text('Xem BLUSH Pass'));
    await tester.pumpAndSettle();
    expect(find.byType(VipScreen), findsOneWidget);
  });

  testWidgets('chat: AI đang bận thì vẫn có câu gợi ý có sẵn', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(_wrap(await _gamer([], aiMode: 'busy'), _room));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Gợi ý từ AI'));
    await tester.pumpAndSettle();
    expect(find.textContaining('không bị trừ lượt'), findsOneWidget);
    expect(find.text('Hôm nay cậu tính leo rank hay chơi giải trí nhẹ nhàng?'), findsOneWidget);
  });

  testWidgets('Đồng đội: "AI: vì sao hợp?" hiện lời giải thích của AI', (tester) async {
    _phoneSize(tester);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(await _gamer(requests), const Scaffold(body: MatchFeedScreen())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI: vì sao hợp?').first);
    await tester.pumpAndSettle();

    expect(requests.last.url.path, '/api/ai/match/a0000000-0000-0000-0000-000000000003/explain');
    expect(find.text('Hai bạn cùng chơi Liên Quân buổi tối và đều hay bật mic.'), findsOneWidget);
    expect(find.text('Báo cáo nội dung không phù hợp'), findsOneWidget);
  });
}
