package com.example.ios_webview_plugin

import android.content.Context
import android.util.Log
import android.webkit.WebView
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class WebViewMoFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler, WebViewControllerDelegate {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context
    private lateinit var webViewManager: WebViewManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "webview_mo_flutter").apply {
            setMethodCallHandler(this@WebViewMoFlutterPlugin)
        }
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "webview_plugin_events").apply {
            setStreamHandler(this@WebViewMoFlutterPlugin)
        }
        webViewManager = WebViewManager.getInstance(context)
        flutterPluginBinding.platformViewRegistry.registerViewFactory("web_view_mo_flutter", WebViewMoFlutterViewFactory(flutterPluginBinding.binaryMessenger, this, webViewManager))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        webViewManager.destroyWebView()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadUrl" -> {
                val urlString = call.argument<String>("initialUrl")
                if (urlString != null) {
                    webViewManager.loadURL(urlString)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "URL is required", null)
                }
            }
            "runJavaScript" -> {
                val script = call.argument<String>("script")
                if (script != null) {
                    webViewManager.evaluateJavaScript(script) { response, error ->
                        if (error != null) {
                            result.error("JAVASCRIPT_ERROR", error.localizedMessage, null)
                        } else {
                            result.success(response)
                        }
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "JavaScript code is required", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        webViewManager.delegate = this
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        webViewManager.delegate = null
    }

    override fun pageDidLoad() {
        eventSink?.success("pageLoaded")
    }

    override fun onMessageReceived(message: String) {
        eventSink?.success(message)
    }
}
