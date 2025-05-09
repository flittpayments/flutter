import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import './cloudipsp_web_view_confirmation.dart';
import './receipt.dart';

abstract class CloudipspWebView extends Widget {
  factory CloudipspWebView({
    required Key key,
    required CloudipspWebViewConfirmation confirmation,
  }) = CloudipspWebViewImpl;
}

class CloudipspWebViewImpl extends StatefulWidget implements CloudipspWebView {
  final PrivateCloudipspWebViewConfirmation _confirmation;

  CloudipspWebViewImpl({
    required Key key,
    required CloudipspWebViewConfirmation confirmation,
  })  : _confirmation = confirmation as PrivateCloudipspWebViewConfirmation,
        super(key: key);

  @override
  State<CloudipspWebViewImpl> createState() => _CloudipspWebViewImplState();
}

class _CloudipspWebViewImplState extends State<CloudipspWebViewImpl> {
  static const URL_START_PATTERN =
      'http://secure-redirect.cloudipsp.com/submit/#';
  static const ADD_VIEWPORT_METADATA = '''(() => {
    const meta = document.createElement('meta');
    meta.setAttribute('content', 'width=device-width, user-scalable=0,');
    meta.setAttribute('name', 'viewport');
    const elementHead = document.getElementsByTagName('head');
    if (elementHead) {
      elementHead[0].appendChild(meta);
    } else {
      const head = document.createElement('head');
      head.appendChild(meta);
    }
  })();''';

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _navigationDelegate,
        ),
      )
      ..loadHtmlString(
        widget._confirmation.response.body.toString(),
        baseUrl: widget._confirmation.baseUrl,
      );

    if (Platform.isAndroid) {
      widget._confirmation.response.headers.forEach((key, value) async {
        if (key.toLowerCase() == 'set-cookie') {
          await widget._confirmation.native.androidAddCookie(
            widget._confirmation.baseUrl,
            value,
          );
        }
      });
    }

    _controller.runJavaScript(ADD_VIEWPORT_METADATA);
  }

  NavigationDecision _navigationDelegate(NavigationRequest request) {
    final url = request.url;
    final detectsStartPattern = url.startsWith(URL_START_PATTERN);
    var detectsCallbackUrl = false;
    var detectsApiToken = false;

    if (!detectsStartPattern) {
      detectsCallbackUrl = url.startsWith(widget._confirmation.callbackUrl);
      if (!detectsCallbackUrl) {
        detectsApiToken = url.startsWith(
            '${widget._confirmation.apiHost}/api/checkout?token=');
      }
    }

    if (detectsStartPattern || detectsCallbackUrl || detectsApiToken) {
      Receipt? receipt;
      if (detectsStartPattern) {
        final jsonOfConfirmation = url.split(URL_START_PATTERN)[1];
        dynamic response;
        try {
          response = jsonDecode(jsonOfConfirmation);
        } catch (e) {
          response = jsonDecode(Uri.decodeComponent(jsonOfConfirmation));
        }
        receipt =
            Receipt.fromJson(response['params'], response['url']);
      }
      widget._confirmation.completer.complete(receipt);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
