import Flutter
import UIKit
import WebKit

public class WebViewMoFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "webview_mo_flutter", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "webview_plugin_events", binaryMessenger: registrar.messenger())
        let instance = WebViewMoFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)

        // Initialize the view factory with the plugin as a delegate
        let factory = WebViewMoFlutterViewFactory(messenger: registrar.messenger(), delegate: instance)
        registrar.register(factory, withId: "web_view_mo_flutter")
    }

    private var eventSink: FlutterEventSink?

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadUrl":
            if let args = call.arguments as? [String: Any],
               let urlString = args["initialUrl"] as? String {
                WebViewManager.shared.loadURL(urlString)
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
        default:
            result(FlutterMethodNotImplemented)
        }
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

extension WebViewMoFlutterPlugin: WebViewControllerDelegate {
    func pageDidLoad() {
        eventSink?("pageLoaded")
    }
}


protocol WebViewControllerDelegate: AnyObject {
    func pageDidLoad()
}

class WebViewManager: NSObject {
    static let shared = WebViewManager()
    var webView: WKWebView!
    weak var delegate: WebViewControllerDelegate?

    override init() {
        super.init()
        // webView = WKWebView()
         let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled") // Enables the inspector
         self.webView = WKWebView(frame: .zero,configuration: configuration)
        webView.navigationDelegate = self
    }

    func getWebView(frame: CGRect) -> WKWebView {
        webView?.frame = frame
        return webView!
    }

    func loadURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        if webView.url != url {
            webView.load(URLRequest(url: url))
        } else {

            // Optionally, notify delegate or log that the URL load was skipped because it's the same as the current one

            print("Load URL skipped as it's the same as the current URL")
        }
    }

    func evaluateJavaScript(_ script: String, completionHandler: @escaping (Any?, Error?) -> Void) {
        webView.evaluateJavaScript(script, completionHandler: completionHandler)
    }
}

extension WebViewManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.pageDidLoad()
    }
}
