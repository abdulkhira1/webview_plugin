import 'package:flutter_test/flutter_test.dart';
import 'package:ios_webview_plugin/ios_webview_plugin.dart';
import 'package:ios_webview_plugin/ios_webview_plugin_platform_interface.dart';
import 'package:ios_webview_plugin/ios_webview_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIosWebviewPluginPlatform
    with MockPlatformInterfaceMixin
    implements IosWebviewPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final IosWebviewPluginPlatform initialPlatform = IosWebviewPluginPlatform.instance;

  test('$MethodChannelIosWebviewPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIosWebviewPlugin>());
  });

  test('getPlatformVersion', () async {
    IosWebviewPlugin iosWebviewPlugin = IosWebviewPlugin();
    MockIosWebviewPluginPlatform fakePlatform = MockIosWebviewPluginPlatform();
    IosWebviewPluginPlatform.instance = fakePlatform;

    expect(await iosWebviewPlugin.getPlatformVersion(), '42');
  });
}
