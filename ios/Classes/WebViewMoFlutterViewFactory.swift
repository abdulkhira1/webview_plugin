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
    private var isChart: Bool = true

    init(frame: CGRect, viewIdentifier: Int64, args: Any?, messenger: FlutterBinaryMessenger, delegate: WebViewControllerDelegate?) {
        self.webView = WebViewManager.shared.getWebView(frame: frame)
        self.delegate = delegate
        super.init()

         // Initialize isChart from args
        if let argsDict = args as? [String: Any], let isChart = argsDict["isChart"] as? Bool {
            self.isChart = isChart
        } else {
            self.isChart = true
        }
        print("Received arg isChart: \(isChart)")

        if let argsDict = args as? [String: Any], let _ = argsDict["initialUrl"] as? String {

            // self.url = URL(string: urlString)
            // loadUrl()
        }
        self.webView.navigationDelegate = self
    }

    func view() -> UIView {
        return webView
    }

   
}

extension WebViewMoFlutter: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Received pageDidLoad2 isChart: \(isChart)")
       if isChart {
            delegate?.pageDidLoad(url: webView.url?.absoluteString ?? "")
        } else {
            delegate?.onPageFinished(url: webView.url?.absoluteString ?? "")
        }
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
