import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ios_webview_plugin_platform_interface.dart';

/// An implementation of [IosWebviewPluginPlatform] that uses method channels.
class MethodChannelIosWebviewPlugin extends IosWebviewPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ios_webview_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
