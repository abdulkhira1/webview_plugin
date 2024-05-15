import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ios_webview_plugin_method_channel.dart';

abstract class IosWebviewPluginPlatform extends PlatformInterface {
  /// Constructs a IosWebviewPluginPlatform.
  IosWebviewPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static IosWebviewPluginPlatform _instance = MethodChannelIosWebviewPlugin();

  /// The default instance of [IosWebviewPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelIosWebviewPlugin].
  static IosWebviewPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IosWebviewPluginPlatform] when
  /// they register themselves.
  static set instance(IosWebviewPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
