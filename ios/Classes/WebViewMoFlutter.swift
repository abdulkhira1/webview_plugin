import Flutter
import UIKit
import WebKit
public class WebViewMoFlutterPlugin: NSObject, FlutterPlugin, WKScriptMessageHandler, WebViewControllerDelegate {
    private var webView: WKWebView?
    private var channel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "webview_mo_flutter", binaryMessenger: registrar.messenger())
         let eventChannel = FlutterEventChannel(name: "webview_plugin_events", binaryMessenger: registrar.messenger())
        let instance = WebViewMoFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)


        // Initialize the view factory
        let factory = WebViewMoFlutterViewFactory(messenger: registrar.messenger(), delegate: instance)
        registrar.register(factory, withId: "web_view_mo_flutter")
    }
 private var eventSink: FlutterEventSink?
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
       case "loadUrl":
            if let args = call.arguments as? [String: Any],
               let urlString = args["initialUrl"] as? String {
                let javaScriptChannelName = args["javaScriptChannelName"] as? String
                WebViewManager.shared.loadURL(urlString, withJavaScriptChannel: javaScriptChannelName, plugin: self)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "URL is required", details: nil))
            }
        case "runJavaScript":
            if let script = (call.arguments as? [String: Any])?["script"] as? String {
                WebViewManager.shared.evaluateJavaScript(script, completionHandler: { (response, error) in
                    if let error = error {
                        result(FlutterError(code: "JAVASCRIPT_ERROR", message: error.localizedDescription, details: nil))
                    } else {
                        result(response)
                    }
                })
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "JavaScript code is required", details: nil))
            }
        case "reloadUrl":
            WebViewManager.shared.webView?.reload()
            result(nil)
        case "resetCache":
            WebViewManager.shared.resetWebViewCache()
            result(nil)
        case "addJavascriptChannel":
            if let args = call.arguments as? [String: Any], let channelName = args["channelName"] as? String {
                WebViewManager.shared.addJavascriptChannel(name: channelName)
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("Received message: \(message.name) with body: \(message.body)")
        if let messageBody = message.body as? String {
            eventSink?(messageBody)
            print("Received message from JavaScript: \(messageBody)")
        }
    }
    
    func pageDidLoad() {
        eventSink?("pageLoaded")
    }
}

extension WebViewMoFlutterPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        WebViewManager.shared.delegate = self  // Assuming WebViewManager now includes a delegate
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        WebViewManager.shared.delegate = nil
        return nil
    }

}


protocol WebViewControllerDelegate: AnyObject {
    func pageDidLoad()
}

class WebViewManager: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    static let shared = WebViewManager()
    var webView: WKWebView!
    weak var delegate: WebViewControllerDelegate?

    override init() {
        super.init()
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
    }

     func loadURL(_ urlString: String, withJavaScriptChannel javaScriptChannelName: String?, plugin: WKScriptMessageHandler) {
        if let channelName = javaScriptChannelName {
            webView.configuration.userContentController.add(plugin, name: channelName)
        }

        guard let url = URL(string: urlString) else { return }
        if webView.url != url {
            print("Loading URL: 1 \(urlString)")
            webView.load(URLRequest(url: url))
        }
    }

     func getWebView(frame: CGRect) -> WKWebView {
        webView?.frame = frame
        return webView!
    }

    func evaluateJavaScript(_ script: String, completionHandler: @escaping (Any?, Error?) -> Void) {
        webView.evaluateJavaScript(script, completionHandler: completionHandler)
    }

    func resetWebViewCache() {
        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: date, completionHandler: {})
    }

    func addJavascriptChannel(name: String) {
        // Make sure to add the script message handler for the specified channel name
        webView.configuration.userContentController.add(self, name: name)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.pageDidLoad()
    }



    // Implement WKScriptMessageHandler method
    @objc public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let messageBody = message.body as? String {
            delegate?.pageDidLoad()
            print("Received message from JavaScript: \(messageBody)")
        }
    }
}
