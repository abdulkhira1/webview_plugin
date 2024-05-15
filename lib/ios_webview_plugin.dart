import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Class to handle the iOS WebView Plugin
// This class will be used to call the native code
// to open the WebView in iOS

// typedef WebViewCreatedCallback = void Function(IosWebViewPlugin controller);

// class WebView extends StatefulWidget {
//   const WebView({
//     super.key,
//     this.onWebViewCreated,
//   });

//   final WebViewCreatedCallback? onWebViewCreated;

//   @override
//   State<StatefulWidget> createState() => WebViewState();
// }

// class WebViewState extends State<WebView> {
//   @override
//   Widget build(BuildContext context) {
//     if (defaultTargetPlatform == TargetPlatform.android) {
//       return AndroidView(
//         viewType: 'webview',
//         onPlatformViewCreated: _onPlatformViewCreated,
//       );
//     } else if (defaultTargetPlatform == TargetPlatform.iOS) {
//       return UiKitView(
//         viewType: 'webview',
//         onPlatformViewCreated: _onPlatformViewCreated,
//       );
//     }
//     return Text('$defaultTargetPlatform is not yet supported by the map view plugin');
//   }

//   void _onPlatformViewCreated(int id) {
//     if (widget.onWebViewCreated == null) {
//       return;
//     }
//     widget.onWebViewCreated!(IosWebViewPlugin());
//   }
// }

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
