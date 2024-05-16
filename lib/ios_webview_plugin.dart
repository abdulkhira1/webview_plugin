import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IosWebViewPlugin {
  static const MethodChannel _channel = MethodChannel('webview_mo_flutter');
  static const EventChannel _eventChannel = EventChannel('webview_plugin_events');

  // Method to open the WebView in iOS

  static Future<void> openWebView(String url) async {
    try {
      await _channel.invokeMethod('loadUrl', {'initialUrl': url});
    } on PlatformException catch (e) {
      print("Failed to open WebView: '${e.message}'.");
    }
  }

  // Method to authenticate the webviewSession in iOS

  static Future<void> runJavaScript(String script) async {
    try {
      await _channel.invokeMethod('runJavaScript', {'script': script});
    } on PlatformException catch (e) {
      print("Failed to run JavaScript: '${e.message}'.");
    }
  }

  static void setWebViewLoadedCallback(Function callback) {
    _eventChannel.receiveBroadcastStream().listen((event) {
      if (event == 'pageLoaded') {
        callback();
      }
    });
  }
}
