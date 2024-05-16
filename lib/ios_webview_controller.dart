import 'dart:async';

import 'package:flutter/services.dart';

class WebViewMoFlutterController {
  static const MethodChannel _methodChannel = MethodChannel('webview_mo_flutter');
  static const EventChannel _eventChannel = EventChannel('webview_plugin_events');

  Stream<String>? _onPageLoadedStream;

  /// Loads a URL in the native web view.
  Future<void> loadUrl(String url) async {
    try {
      await _methodChannel.invokeMethod('loadUrl', {'initialUrl': url});
    } on PlatformException catch (e) {
      print("Failed to load URL: ${e.message}");
      throw e;
    }
  }

  /// Executes JavaScript in the native web view.
  Future<dynamic> runJavaScript(String script) async {
    try {
      final result = await _methodChannel.invokeMethod('runJavaScript', {'script': script});
      return result;
    } on PlatformException catch (e) {
      print("Failed to execute JavaScript: ${e.message}");
      throw e;
    }
  }

  /// Stream of page load events.
  Stream<String> get onPageLoaded {
    _onPageLoadedStream ??=
        _eventChannel.receiveBroadcastStream().map<String>((event) => event as String);
    return _onPageLoadedStream!;
  }

  /// Close the web view (if supported by the native code).
  Future<void> closeWebView() async {
    try {
      await _methodChannel.invokeMethod('close');
    } on PlatformException catch (e) {
      print("Failed to close web view: ${e.message}");
      throw e;
    }
  }
}
