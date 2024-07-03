package com.custom.webview_plugin

import android.app.AlertDialog
import android.content.Context
import android.os.Build
import android.os.Message
import android.util.Log
import android.view.ViewGroup
import android.webkit.ConsoleMessage
import android.webkit.JavascriptInterface
import android.webkit.JsResult
import android.webkit.PermissionRequest
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


class CustomWebViewFactory(
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
        Log.d("CustomWebViewPlugin", "dispose")
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
                settings.domStorageEnabled = true
                settings.cacheMode = WebSettings.LOAD_DEFAULT
                settings.javaScriptCanOpenWindowsAutomatically = true
                webChromeClient = object : WebChromeClient() {
                    override fun onConsoleMessage(consoleMessage: ConsoleMessage): Boolean {
                        Log.d("CustomWebViewPlugin", "WebViewConsole: ${consoleMessage.message()} at ${consoleMessage.sourceId()}:${consoleMessage.lineNumber()}")
                        return true
                    }

                    override fun onJsAlert(view: WebView?, url: String?, message: String?, result: JsResult?): Boolean {
                        delegate?.onJsAlert(url, message)
                        return true
                    }

                    override fun onPermissionRequest(request: PermissionRequest?) {
                        super.onPermissionRequest(request)
                        request?.grant(request.resources)
                    }

                    override fun onCreateWindow(view: WebView?, isDialog: Boolean, isUserGesture: Boolean, resultMsg: Message?): Boolean {
                        val newWebView = WebView(context)
                        val webSettings = newWebView.settings
                        webSettings.javaScriptEnabled = true
                        webSettings.javaScriptCanOpenWindowsAutomatically = true

                        val dialog = AlertDialog.Builder(context)
                        dialog.setView(newWebView)
                                .setPositiveButton("Close") { dialogInterface, i ->
                                    (newWebView.parent as ViewGroup).removeView(newWebView)
                                    dialogInterface.dismiss()
                                }
                                .show()

                        val transport = resultMsg!!.obj as WebView.WebViewTransport
                        transport.webView = newWebView
                        resultMsg.sendToTarget()
                        return true
                    }
                }
                webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView?, url: String?) {
                        super.onPageFinished(view, url)
                        delegate?.onPageFinished(url ?: "")
                    }

                    override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                        Log.d("CustomWebViewPlugin", "shouldOverrideUrlLoading === ${view?.url}")
                        return false
                    }

                    override fun onReceivedError(
                        view: WebView?,
                        request: WebResourceRequest?,
                        error: WebResourceError?
                    ) {
                        super.onReceivedError(view, request, error)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            if(error?.description.toString() != "net::ERR_NAME_NOT_RESOLVED") {
                                error?.let { delegate?.onReceivedError(it.description.toString()) }
                            }
                        } else {
                            delegate?.onReceivedError("error")
                        }
                        if (isFromChart) {
                            loadDefaultURL()
                        }
                    }


                }

            }
        }
        return webView!!
    }

    fun loadURL(urlString: String, javaScriptChannelName: String?, isChart: Boolean) {
        isFromChart = isChart
        Log.d("CustomWebViewPlugin", "loadURL : $urlString")
        if (urlString.isNotEmpty()) {
            if (javaScriptChannelName != null) {
                addJavascriptChannel(javaScriptChannelName)
            }
            webView?.loadUrl(urlString)
        } else {
            loadDefaultURL()
        }
        if (isWebViewPaused) resumeWebView()
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
        Log.d("CustomWebViewPlugin", "addJavascriptChannel === $name")
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
        Log.d("CustomWebViewPlugin", "destroyWebView")
        webView?.loadUrl("about:blank")
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
    fun onJsAlert(url: String?, message: String?)
}
