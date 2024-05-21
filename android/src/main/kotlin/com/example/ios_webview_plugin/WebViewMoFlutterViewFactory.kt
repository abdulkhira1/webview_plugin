
package com.example.ios_webview_plugin

import android.content.Context
import android.util.Log
import android.webkit.ConsoleMessage
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class WebViewMoFlutterViewFactory(
    private val messenger: BinaryMessenger,
    private val delegate: WebViewControllerDelegate?,
    private val webViewManager: WebViewManager
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return WebViewMoFlutter(context, viewId, args, messenger, delegate, webViewManager)
    }
}

class WebViewMoFlutter(
    context: Context,
    viewId: Int,
    args: Any?,
    messenger: BinaryMessenger,
    private val delegate: WebViewControllerDelegate?,
    private val webViewManager: WebViewManager
) : PlatformView {

    private val webView: WebView = webViewManager.getOrCreateWebView()

    init {
        if (args is Map<*, *>) {
//            val initialUrl = args["initialUrl"] as? String
//            initialUrl?.let { webViewManager.loadURL(it) }
        }
    }

    override fun getView(): WebView = webView

    override fun dispose() {
        webViewManager.destroyWebView()
    }
}

class WebViewManager private constructor(private val context: Context) {

    var delegate: WebViewControllerDelegate? = null
    private var webView: WebView? = null

    fun getOrCreateWebView(): WebView {
        if (webView == null) {
            Log.d("getOrCreateWebView", "  = = = = = = = = ")
            webView = WebView(context).apply {
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = true
                settings.javaScriptCanOpenWindowsAutomatically = true
                webChromeClient = object : WebChromeClient() {
                    override fun onConsoleMessage(consoleMessage: ConsoleMessage): Boolean {
                        Log.d("WebViewConsole", "${consoleMessage.message()} at ${consoleMessage.sourceId()}:${consoleMessage.lineNumber()}")
                        return true
                    }
                }
                webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView?, url: String?) {
                        super.onPageFinished(view, url)
                        delegate?.pageDidLoad()
                    }

                    override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                        return false
                    }
                }
                addJavascriptInterface(object : Any() {
                    @JavascriptInterface
                    fun onMessageReceived(message: String) {
                        Log.d("onMessageReceived", "Message: $message")
                        delegate?.onMessageReceived(message)
                    }
                }, "ChartAppDelegate")
            }
        }
        return webView!!
    }

    fun loadURL(urlString: String) {
        Log.d("loadURL", "  = = = = = = = = $urlString")
        webView?.loadUrl(urlString)
    }

    fun evaluateJavaScript(script: String, completionHandler: (Any?, Throwable?) -> Unit) {
        webView?.evaluateJavascript(script) { result ->
            completionHandler(result, null)
        }
    }

    fun destroyWebView() {
        webView?.destroy()
        webView = null
    }

    companion object {
        private var INSTANCE: WebViewManager? = null

        fun getInstance(context: Context): WebViewManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: WebViewManager(context.applicationContext).also { INSTANCE = it }
            }
        }
    }
}

interface WebViewControllerDelegate {
    fun pageDidLoad()
    fun onMessageReceived(message:String)
}
