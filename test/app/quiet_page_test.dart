import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:konsou/app/quiet_page.dart';

void main() {
  testWidgets('a pushed quiet page shows at once and back returns', (
    tester,
  ) async {
    Text words(String text) => Text(text, textDirection: TextDirection.ltr);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => QuietPage(child: words('list')),
        ),
        GoRoute(
          path: '/title',
          pageBuilder: (context, state) => QuietPage(child: words('title')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      WidgetsApp.router(color: const Color(0xFF000000), routerConfig: router),
    );
    expect(find.text('list'), findsOneWidget);

    router.push('/title');
    await tester.pump();
    await tester.pump();
    expect(find.text('title'), findsOneWidget);
    expect(find.text('list'), findsNothing);
    expect(router.canPop(), isTrue);

    router.pop();
    await tester.pump();
    await tester.pump();
    expect(find.text('list'), findsOneWidget);
    expect(find.text('title'), findsNothing);
  });
}
