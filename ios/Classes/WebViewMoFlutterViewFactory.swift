import Flutter
import UIKit
import WebKit

class WebViewMoFlutterViewFactory: NSObject, FlutterPlatformViewFactory {
   
    
    private var messenger: FlutterBinaryMessenger
    var delegate: WebViewControllerDelegate?

    init(messenger: FlutterBinaryMessenger, delegate: WebViewControllerDelegate?) {
        self.messenger = messenger
        self.delegate = delegate
        super.init()
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return WebViewMoFlutter(frame: frame, viewIdentifier: viewId, args: args, messenger: messenger, delegate: delegate)
    }
}

class WebViewMoFlutter: NSObject, FlutterPlatformView {
    private var webView: WKWebView
    private var url: URL?
    private var delegate: WebViewControllerDelegate?

    init(frame: CGRect, viewIdentifier: Int64, args: Any?, messenger: FlutterBinaryMessenger, delegate: WebViewControllerDelegate?) {
        self.webView = WebViewManager.shared.getWebView(frame: frame)
        self.delegate = delegate
        super.init()
        if let argsDict = args as? [String: Any], let _ = argsDict["initialUrl"] as? String {

            // self.url = URL(string: urlString)
            // loadUrl()
        }
        self.webView.navigationDelegate = self
    }

    func view() -> UIView {
        return webView
    }

    // private func loadUrl() {
    //     // Check if Url is same as loaded in the webview
    //     // If it is same, then don't load the url again
    //     if let url = url, webView.url != url {
    //         print("Loading URL: 2 \(url)")
    //         webView.load(URLRequest(url: url))
    //     } else {
    //         // Optionally, notify delegate or log that the URL load was skipped because it's the same as the current one
    //         print("Load URL skipped as it's the same as the current URL")
    //     }
    // }

    // // Method to evaluate JavaScript
    // func evaluateJavaScript(_ script: String, completionHandler: @escaping (Any?, Error?) -> Void) {
    //     webView.evaluateJavaScript(script, completionHandler: completionHandler)
    // }
}

extension WebViewMoFlutter: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.pageDidLoad()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // handleLoadingError()
        delegate?.onPageLoadError()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // handleLoadingError()
        delegate?.onPageLoadError()
    }
    
}
