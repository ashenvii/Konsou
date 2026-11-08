import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:konsou/sync/google_sign_in.dart';
import 'package:konsou/sync/sync_errors.dart';

import '../support/fake_google.dart';

final _now = DateTime.utc(2026, 11, 8, 12);

void main() {
  late FakeGoogle google;
  late MemoryTokenStore store;
  Uri? opened;

  Future<void> visitCallback(Uri url, String? state) async {
    final back = Uri.parse(url.queryParameters['redirect_uri']!).replace(
      queryParameters: {
        'code': 'code-1',
        'state': state ?? url.queryParameters['state']!,
      },
    );
    final client = HttpClient();
    final request = await client.getUrl(back);
    await (await request.close()).drain<void>();
    client.close();
  }

  /// Plays the browser: Google says yes and sends it back to the loopback
  /// port. Like a real browser, opening it does not wait for that answer.
  Future<void> answerInBrowser(Uri url, {String? state}) async {
    opened = url;
    unawaited(visitCallback(url, state));
  }

  GoogleSignIn buildSignIn({
    Future<void> Function(Uri url)? openBrowser,
    Duration timeout = const Duration(seconds: 5),
  }) => GoogleSignIn(
    clientId: 'client',
    clientSecret: 'secret',
    client: google.client,
    store: store,
    openBrowser: openBrowser ?? answerInBrowser,
    now: () => _now,
    timeout: timeout,
  );

  setUp(() {
    google = FakeGoogle();
    store = MemoryTokenStore();
    opened = null;
  });

  test('signs in through the loopback port and keeps the tokens', () async {
    final email = await buildSignIn().signIn();

    expect(email, 'owner@example.com');
    expect(opened!.queryParameters['scope'], googleScope);
    expect(opened!.queryParameters['code_challenge_method'], 'S256');
    expect(
      opened!.queryParameters['redirect_uri'],
      startsWith('http://127.0.0.1:'),
    );
    expect(store.tokens!.refreshToken, 'refresh-1');
    expect(await buildSignIn().isSignedIn(), isTrue);
  });

  test('an answer with the wrong state is refused', () async {
    await expectLater(
      buildSignIn(
        openBrowser: (url) => answerInBrowser(url, state: 'someone else'),
      ).signIn(),
      throwsA(isA<SignInCancelled>()),
    );
    expect(store.tokens, isNull);
  });

  test('a browser that never answers ends as cancelled', () async {
    await expectLater(
      buildSignIn(
        openBrowser: (_) async {},
        timeout: const Duration(milliseconds: 50),
      ).signIn(),
      throwsA(isA<SignInCancelled>()),
    );
  });

  test('an access token about to end is refreshed', () async {
    store.tokens = GoogleTokens(
      accessToken: 'old',
      refreshToken: 'refresh-1',
      expiresAt: _now.millisecondsSinceEpoch + 30000,
      email: 'owner@example.com',
    );
    expect(await buildSignIn().accessToken(), 'token-refreshed');
    expect(store.tokens!.refreshToken, 'refresh-1');
  });

  test('a revoked sign-in asks for sign-in again', () async {
    google.refreshAnswer = 400;
    store.tokens = GoogleTokens(
      accessToken: 'old',
      refreshToken: 'revoked',
      expiresAt: 0,
      email: 'owner@example.com',
    );
    await expectLater(
      buildSignIn().accessToken(),
      throwsA(isA<SignInNeeded>()),
    );
  });

  test('signing out forgets the tokens', () async {
    await buildSignIn().signIn();
    await buildSignIn().signOut();
    expect(store.tokens, isNull);
  });
}
