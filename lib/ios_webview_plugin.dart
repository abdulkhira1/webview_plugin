import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IosWebViewPlugin {
  static const MethodChannel _channel = MethodChannel('webview_mo_flutter');
  static const EventChannel _eventChannel = EventChannel('webview_plugin_events');

  // Method to open the WebView in iOS

  // Stream<String>? _onPageLoadedStream;

  static Stream<String>? _onMessageReceivedStream;

  Stream<String> get onMessageReceived => _onMessageReceivedStream!;

  static Future<void> openWebView(String url, {String? javascriptChannelName}) async {
    try {
      await _channel.invokeMethod(
          'loadUrl', {'initialUrl': url, 'javaScriptChannelName': javascriptChannelName});
    } on PlatformException catch (e) {
      print("Failed to open WebView: '${e.message}'.");
    }
  }

  static Future<void> addJavascriptChannel(String channelName) async {
    try {
      await _channel.invokeMethod('addJavascriptChannel', {'javaScriptChannelName': channelName});
    } on PlatformException catch (e) {
      print("Failed to add JavaScript channel: ${e.message}");
      rethrow;
    }
  }

  /// Reloads the current URL.
  static Future<void> reloadUrl() async {
    try {
      await _channel.invokeMethod('reloadUrl');
    } on PlatformException catch (e) {
      print("Failed to reload URL: ${e.message}");
      rethrow;
    }
  }

  /// Resets the web view's cache.
  static Future<void> resetCache() async {
    try {
      await _channel.invokeMethod('resetCache');
    } on PlatformException catch (e) {
      print("Failed to reset cache: ${e.message}");
      rethrow;
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

  // Stream<String> get onPageLoaded {
  //   _onPageLoadedStream ??=
  //       _eventChannel.receiveBroadcastStream().map<String>((event) => event as String);
  //   return _onPageLoadedStream!;
  // }

  static void getJavaScriptChannelStream(Function(String) callback) {
    _onMessageReceivedStream ??= _eventChannel.receiveBroadcastStream().map<String>((event) {
      callback(event.toString());
      return event.toString();
    });
  }

  static void setWebViewLoadedCallback(Function callback) {
    _eventChannel.receiveBroadcastStream().listen((event) {
      if (event == 'pageLoaded') {
        callback();
      }
    });
  }
}
