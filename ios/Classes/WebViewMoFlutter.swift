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

    private var webViewController: WebViewController?
  private var eventSink: FlutterEventSink?
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "loadUrl":
        if let args = call.arguments as? [String: Any],
           let urlString = args["initialUrl"] as? String,
           let url = URL(string: urlString) {
            webViewController = WebViewController()
            webViewController?.url = url
            webViewController?.delegate = self
            if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
                rootVC.present(webViewController!, animated: true, completion: nil)
            }
            result(nil)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "URL is required", details: nil))
        }
    case "runJavaScript":
        if let script = (call.arguments as? [String: Any])?["script"] as? String {
            webViewController?.webView.evaluateJavaScript(script) { (response, error) in
                if let error = error {
                    result(FlutterError(code: "JAVASCRIPT_ERROR", message: error.localizedDescription, details: nil))
                } else {
                    result(response)
                }
            }
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
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
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

class WebViewController: UIViewController, WKNavigationDelegate {
  var webView: WKWebView!
  var url: URL!
  weak var delegate: WebViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    webView = WKWebView()
    webView.navigationDelegate = self
    view = webView
    webView.load(URLRequest(url: url))
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
   let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
   navigationItem.rightBarButtonItem = closeButton
  }

 @objc func close() {
   dismiss(animated: true, completion: nil)
 }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    delegate?.pageDidLoad()
  }
}
