import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../l10n/l10n_context.dart';
import '../services/auth_service.dart';

class SocialSignInResult {
  const SocialSignInResult({this.sessionCookie, this.error});

  final String? sessionCookie;
  final String? error;

  bool get cancelled => sessionCookie == null && error == null;
}

class SocialSignInPage extends StatefulWidget {
  const SocialSignInPage({
    super.key,
    required this.start,
    required this.apiUrl,
  });

  final SocialAuthStart start;
  final String apiUrl;

  static Future<SocialSignInResult?> open(
    BuildContext context, {
    required SocialAuthStart start,
    required String apiUrl,
  }) {
    return Navigator.of(context).push<SocialSignInResult>(
      MaterialPageRoute(
        builder: (_) => SocialSignInPage(start: start, apiUrl: apiUrl),
      ),
    );
  }

  @override
  State<SocialSignInPage> createState() => _SocialSignInPageState();
}

class _SocialSignInPageState extends State<SocialSignInPage> {
  final _cookies = CookieManager.instance();
  bool _done = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _seedStateCookie();
  }

  Future<void> _seedStateCookie() async {
    final name = widget.start.stateCookieName;
    final value = widget.start.stateCookieValue;
    if (name == null || value == null) return;
    final origin = Uri.parse(widget.apiUrl).origin;
    await _cookies.setCookie(
      url: WebUri(origin),
      name: name,
      value: value,
      path: '/',
      isSecure: origin.startsWith('https'),
      isHttpOnly: true,
      sameSite: HTTPCookieSameSitePolicy.LAX,
    );
  }

  Future<void> _complete(Uri uri) async {
    if (_done) return;
    _done = true;
    final error = uri.queryParameters['error'];
    if (error != null) {
      _finish(SocialSignInResult(error: error));
      return;
    }
    final origin = Uri.parse(widget.apiUrl).origin;
    for (var attempt = 0; attempt < 3; attempt++) {
      final cookies = await _cookies.getCookies(url: WebUri(origin));
      for (final cookie in cookies) {
        if (cookie.name == AuthService.sessionCookieName &&
            cookie.value.isNotEmpty) {
          _finish(SocialSignInResult(sessionCookie: cookie.value));
          return;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    _finish(const SocialSignInResult(error: 'missing_session'));
  }

  void _finish(SocialSignInResult result) {
    _cookies.deleteAllCookies();
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('auth:providers.${widget.start.provider}')),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri.uri(widget.start.authorizationUrl),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              sharedCookiesEnabled: false,
            ),
            onLoadStart: (_, _) {
              if (mounted) setState(() => _loading = true);
            },
            onLoadStop: (_, _) {
              if (mounted) setState(() => _loading = false);
            },
            onReceivedError: (_, request, error) {
              if (request.isForMainFrame == true && mounted) {
                setState(() => _loading = false);
              }
            },
            shouldOverrideUrlLoading: (_, action) async {
              final url = action.request.url;
              if (url != null && url.scheme == 'trackgeek') {
                await _complete(url.uriValue);
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 3),
        ],
      ),
    );
  }
}
