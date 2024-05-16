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
        self.webView = WKWebView(frame: frame)
        self.delegate = delegate
        super.init()
        if let argsDict = args as? [String: Any], let urlString = argsDict["initialUrl"] as? String {
            self.url = URL(string: urlString)
            loadUrl()
        }
    }

    func view() -> UIView {
        return webView
    }

    private func loadUrl() {
        if let url = self.url {
            let request = URLRequest(url: url)
            webView.load(request)
            webView.navigationDelegate = self
        }
    }

    // Method to evaluate JavaScript
    func evaluateJavaScript(_ script: String, completionHandler: @escaping (Any?, Error?) -> Void) {
        webView.evaluateJavaScript(script, completionHandler: completionHandler)
    }
}

extension WebViewMoFlutter: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.pageDidLoad()
    }
}
