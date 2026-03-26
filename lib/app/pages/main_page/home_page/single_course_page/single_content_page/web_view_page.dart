import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webinar/app/services/user_service/user_service.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/components.dart';
import 'package:webinar/common/data/app_data.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../../common/data/app_language.dart';
import '../../../../../../common/utils/constants.dart';
import '../../../../../../locator.dart';

class WebViewPage extends StatefulWidget {
  static const String pageName = '/web-view';
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;

  // ✅ نخزن هوست الموقع الأساسي عشان نضيف Authorization على موقعنا فقط
  String? _baseHost;

  InAppWebViewSettings settings = InAppWebViewSettings(
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,

    // ✅ مهم جدًا للفيديوهات داخل iframe (Vimeo)
    iframeAllow:
        "camera; microphone; autoplay; encrypted-media; fullscreen; picture-in-picture",
    iframeAllowFullscreen: true,

    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,

    cacheEnabled: true,
    javaScriptEnabled: true,

    useHybridComposition: false,
    sharedCookiesEnabled: true,

    useShouldOverrideUrlLoading: true,
    useOnLoadResource: false,
  );

  CookieManager cookieManager = CookieManager.instance();

  String? url;
  String? title;

  late WebViewController controller;
  bool isShow = false;

  bool isSendTokenInHeader = true;
  LoadRequestMethod method = LoadRequestMethod.post;

  PlatformWebViewControllerCreationParams params =
      const PlatformWebViewControllerCreationParams();
  String token = '';
  String csrfToken = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      url = (ModalRoute.of(context)!.settings.arguments as List)[0];
      title = (ModalRoute.of(context)!.settings.arguments as List)[1] ?? '';

      try {
        isSendTokenInHeader =
            (ModalRoute.of(context)!.settings.arguments as List)[2] ?? true;
      } catch (_) {}

      try {
        method = (ModalRoute.of(context)!.settings.arguments as List)[3] ??
            LoadRequestMethod.post;
      } catch (_) {}

      token = await AppData.getAccessToken();

      // ✅ سجل هوست الصفحة الأساسية (موقعك)
      try {
        if ((url?.startsWith('http') ?? false)) {
          _baseHost = Uri.parse(url!).host;
        }
      } catch (_) {}

      isShow = true;
      setState(() {});

      await [
        Permission.camera,
        Permission.microphone,
      ].request();

      setState(() {});
    });
  }

  bool _isSameSite(String? host) {
    if (host == null || host.isEmpty) return false;
    if (_baseHost == null || _baseHost!.isEmpty) return false;

    // نفس الهوست أو subdomain من نفس الموقع
    return host == _baseHost || host.endsWith(_baseHost!);
  }

  bool _isVimeo(String? host) {
    if (host == null) return false;
    final h = host.toLowerCase();
    return h.contains('vimeo.com') || h.contains('vimeocdn.com');
  }

  load() async {
    if (isSendTokenInHeader) {
      if (csrfToken.isEmpty) {
        csrfToken = await UserService.csrfToken();
      }
    }

    var header = {
      if (isSendTokenInHeader) ...{
        "Authorization": "Bearer $token",
        'X-CSRF-TOKEN': csrfToken,
      },

      // ✅ نخلي Accept يقبل HTML (ده مهم لصفحات الفيديو/الويب)
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,application/json;q=0.8,*/*;q=0.7',

      "Content-Type": "application/json",
      'x-api-key': Constants.apiKey,
      'x-locale': locator<AppLanguage>().currentLanguage.toLowerCase(),

      // سيبه زي ما عندك (مش هنعتمد عليه لإصلاح iOS، بس مش هيضر)
      'User-Agent':
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    };

    if (!(url?.startsWith('http') ?? false)) {
      await webViewController?.loadData(
        data: url ?? '',
        baseUrl: null,
        historyUrl: null,
      );
    } else {
      await webViewController?.loadUrl(
        urlRequest: URLRequest(
          method: method == LoadRequestMethod.post ? "POST" : "GET",
          url: WebUri(url ?? ''),
          headers: header,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return directionality(
      child: OrientationBuilder(
        builder: (context, orientation) {
          return Scaffold(
            appBar: appbar(title: title ?? ''),
            body: isShow
                ? InAppWebView(
                    onJsBeforeUnload: (nAppWebViewController,
                        jsBeforeUnloadRequest) async {
                      return JsBeforeUnloadResponse();
                    },
                    key: webViewKey,
                    initialSettings: settings,
                    onReceivedHttpError: (inAppWebViewController,
                        webResourceRequest, webResourceResponse) {},
                    onWebViewCreated: (controller) async {
                      webViewController = controller;
                      load();
                    },
                    onPermissionRequest: (controller, request) async {
                      return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.GRANT,
                      );
                    },
                    onLoadResource: (inAppWebViewController, loadedResource) {},
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      final req = navigationAction.request;
                      final host = req.url?.uriValue?.host;

                      // ✅ Deep link بتاعكم
                      if (req.url?.uriValue != null) {
                        if (req.url!.uriValue
                            .toString()
                            .startsWith(Constants.scheme)) {
                          backRoute(arguments: true);
                          return NavigationActionPolicy.CANCEL;
                        }
                      }

                      // ✅ لو لينك Vimeo: سيبه من غير أي Headers/Authorization
                      if (_isVimeo(host)) {
                        return NavigationActionPolicy.ALLOW;
                      }

                      // ✅ أضف Authorization/headers لموقعك فقط
                      if (_isSameSite(host)) {
                        if (isSendTokenInHeader) {
                          req.headers ??= {};
                          if (!(req.headers?.containsKey('Authorization') ??
                              false)) {
                            req.headers?.addAll({
                              "Authorization": "Bearer $token",
                              'X-CSRF-TOKEN': csrfToken,
                              'x-api-key': Constants.apiKey,
                              'x-locale': locator<AppLanguage>()
                                  .currentLanguage
                                  .toLowerCase(),
                              'Accept':
                                  'text/html,application/xhtml+xml,application/xml;q=0.9,application/json;q=0.8,*/*;q=0.7',
                            });

                            await controller.loadUrl(urlRequest: req);

                            // ✅ مهم: بما إننا عملنا loadUrl بنفسنا، نلغي التحميل الأصلي
                            return NavigationActionPolicy.CANCEL;
                          }
                        }

                        if (req.headers == null ||
                            (req.headers?.isEmpty ?? true)) {
                          req.headers = {
                            if (isSendTokenInHeader) ...{
                              "Authorization": "Bearer $token",
                              'X-CSRF-TOKEN': csrfToken,
                            },
                            'x-api-key': Constants.apiKey,
                            'x-locale': locator<AppLanguage>()
                                .currentLanguage
                                .toLowerCase(),
                            'Accept':
                                'text/html,application/xhtml+xml,application/xml;q=0.9,application/json;q=0.8,*/*;q=0.7',
                          };

                          await controller.loadUrl(urlRequest: req);
                          return NavigationActionPolicy.CANCEL;
                        }
                      }

                      return NavigationActionPolicy.ALLOW;
                    },
                    onLoadStop: (controller, url) async {
                      // ✅ يساعد لو عندك <video> مباشر في صفحتك (مش iframe)
                      await controller.evaluateJavascript(source: """
                        try {
                          document.querySelectorAll('video').forEach(v => {
                            v.setAttribute('playsinline','');
                            v.setAttribute('webkit-playsinline','');
                          });
                        } catch(e) {}
                      """);
                    },
                    onLoadStart: (controller, url_) {
                      if (url_?.uriValue != null) {
                        if (url_?.uriValue
                                .toString()
                                .startsWith(Constants.scheme) ??
                            false) {
                          backRoute(arguments: true);
                        }
                      }
                    },
                    onReceivedError: (controller, request, error) {},
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        setState(() {});
                      }
                    },
                    onUpdateVisitedHistory: (controller, uri, isReload) {},
                    onConsoleMessage: (controller, consoleMessage) {},
                    onNavigationResponse: (cntr, n) async {
                      return NavigationResponseAction.ALLOW;
                    },
                  )
                : loading(),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    webViewController?.dispose();
    super.dispose();
  }
}