
package com.example.ios_webview_plugin

import android.content.Context
import android.util.Log
import android.webkit.ConsoleMessage
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
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
//        if (args is Map<*, *>) {
//            val initialUrl = args["initialUrl"] as? String
//            initialUrl?.let { webViewManager.loadURL(it, null, null) }
//        }
    }

    override fun getView(): WebView = webView

    override fun dispose() {
        Log.d("WebViewMoFlutterPlugin", "dispose")
        webViewManager.destroyWebView()
    }
}

class WebViewManager private constructor(private val context: Context) {

    var delegate: WebViewControllerDelegate? = null
    var webView: WebView? = null
        private set
    private val configuredJavaScriptChannels: MutableSet<String> = mutableSetOf()
    private val defaultURLString = "https://tradingview.com/"
    private var isWebViewPaused: Boolean = false
    private var isFromChart: Boolean = true

    fun getOrCreateWebView(): WebView {
        if (webView == null) {
            configuredJavaScriptChannels.clear()
            webView = WebView(context).apply {
                settings.javaScriptEnabled = true
                settings.cacheMode = WebSettings.LOAD_DEFAULT
                settings.javaScriptCanOpenWindowsAutomatically = true
                webChromeClient = object : WebChromeClient() {
                    override fun onConsoleMessage(consoleMessage: ConsoleMessage): Boolean {
                        Log.d("WebViewMoFlutterPlugin", "WebViewConsole: ${consoleMessage.message()} at ${consoleMessage.sourceId()}:${consoleMessage.lineNumber()}")
                        return true
                    }
                }
                webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView?, url: String?) {
                        super.onPageFinished(view, url)
                        url?.let { delegate?.onPageFinished(it) }
                    }

                    override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                        if (request?.url.toString().contains("mailto:") || request?.url.toString().contains("tel:")) {
                            delegate?.onNavigationRequest(request?.url.toString())
                            return true
                        }
                        return false
                    }

                    override fun onReceivedError(
                        view: WebView?,
                        request: WebResourceRequest?,
                        error: WebResourceError?
                    ) {
                        super.onReceivedError(view, request, error)
                        delegate?.onReceivedError("error")
                        if(isFromChart) {
                            loadDefaultURL()
                        }
                    }


                }

            }
        }
        return webView!!
    }

    fun loadURL(urlString: String, javaScriptChannelName: String?, plugin: WebViewMoFlutterPlugin?) {
        if (isWebViewPaused) resumeWebView()
        if (urlString.isNotEmpty()) {
            if (javaScriptChannelName != null && javaScriptChannelName.isNotEmpty()) {
                addJavascriptChannel(javaScriptChannelName)
            } else {
                isFromChart = false
            }
            webView?.loadUrl(urlString)
        } else {
            loadDefaultURL()
        }
    }

    fun evaluateJavaScript(script: String, completionHandler: (Any?, Throwable?) -> Unit) {
        if (isWebViewPaused) resumeWebView()
        webView?.evaluateJavascript(script) { result ->
            completionHandler(result, null)
        }
    }

    fun resetWebViewCache() {
        webView?.clearCache(true)
    }

    fun addJavascriptChannel(name: String): Boolean {
        if (configuredJavaScriptChannels.contains(name)) return false
        webView?.addJavascriptInterface(object : Any() {
            @JavascriptInterface
            fun postMessage(message: String) {
                delegate?.onJavascriptChannelMessageReceived(name, message)
            }
        }, name)
        configuredJavaScriptChannels.add(name)
        return true
    }



    private fun loadDefaultURL() {
        webView?.loadUrl(defaultURLString)
    }

    fun destroyWebView() {
        isWebViewPaused = true
        Log.d("WebViewMoFlutterPlugin", "destroyWebView")
        webView?.onPause()
        webView?.pauseTimers()
//        webView?.destroy()
//        webView = null
    }

    fun resumeWebView() {
        isWebViewPaused = false
        webView?.onResume()
        webView?.resumeTimers()
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
    fun onMessageReceived(message: String)
    fun onJavascriptChannelMessageReceived(channelName: String, message: String)
    fun onNavigationRequest(url: String)
    fun onPageFinished(url: String)
    fun onReceivedError(message: String)
}
