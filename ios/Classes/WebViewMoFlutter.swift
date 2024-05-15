import Flutter
import UIKit
import WebKit

// public class WebViewMoFlutterPlugin: NSObject, FlutterPlugin {
//     private var webView: WKWebView?
    
//     public static func register(with registrar: FlutterPluginRegistrar) {
//         let channel = FlutterMethodChannel(name: "webview_mo_flutter", binaryMessenger: registrar.messenger())
//         let instance = WebViewMoFlutterPlugin()
//         registrar.addMethodCallDelegate(instance, channel: channel)
//     }
    
//     public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//         switch call.method {

//         case "loadUrl":
//         if let args = call.arguments as? [String: Any],
//            let initialUrl = args["initialUrl"] as? String {
//             // let viewController = UIApplication.shared.keyWindow?.rootViewController
//             // let webViewVC = ContentView(homeUrl: URL(string: initialUrl)!)
//             // viewController?.present(UIHostingController(rootView: webViewVC), animated: true, completion: nil)

//             // Use SceneDelegate.swift to load the WebView

//             // let url = URL(string: initialUrl)!
//             // if #available(iOS 14.0, *) {
//             //     let contentView = ContentView(homeUrl: url)
//             //     if let windowScene = scene as? UIWindowScene {W
//             //         let window = UIWindow(windowScene: windowScene)
//             //         window.rootViewController = UIHostingController(rootView: contentView)
//             //         self.window = window
//             //         window.makeKeyAndVisible()
//             //     }
//             // } else {
//             //     // Fallback on earlier versions
//             // }
            
//             WebViewMoFlutterPlugin.presentWebView(url: initialUrl)

//             result(nil)
//         } else {
//             result(FlutterError(code: "INVALID_ARGUMENT",
//                                 message: "Invalid argument for openWebView method",
//                                 details: nil))
//         }
//         // case "loadUrl":
//         //     if let args = call.arguments as? [String: Any],
//         //          let url = args["url"] as String,
//         //          {
//         //         loadUrl(url)
//         //         // result(nil)
//         //     } else {
//         //         result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
//         //     }
//         case "runJavaScript":
//             if let args = call.arguments as? [String: Any],
//                  let script = args["script"] as? String {
//                 runJavaScript(script)
//                 // result(nil)
//             } else {
//                 result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
//             }
//         default:
//             result(FlutterMethodNotImplemented)
//         }


//     }

//     @available(iOS 13.0, *)
//    public static func presentWebView(url: String) {
//         guard let scene = SceneDelegate.currentScene() else { return }

//         let webViewController = WebViewController()
//         webViewController.url = url

//         if let rootViewController = scene.windows.first?.rootViewController {
//             rootViewController.present(webViewController, animated: true)
//         }
//     }


//     private func loadUrl(_ url: String) {
//         let config = WKWebViewConfiguration()
//         // let script = "document.cookie = 'authToken=\(authToken)';"
//         // let scriptInjection = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
//         // config.userContentController.addUserScript(scriptInjection)
        
//         webView = WKWebView(frame: UIScreen.main.bounds)

//         if let webView = webView, let url = URL(string: url) {
//             let request = URLRequest(url: url)
//             webView.load(request)
            
//             // Add the webView to your content view
//             // For example, if you're using SwiftUI:
//             // let contentView = WebViewContainer(webView: webView)
//             // window.rootViewController = UIHostingController(rootView: contentView)
            
//             webView.navigationDelegate = self
//         }
//     }
    
//     private func runJavaScript(_ script: String) {
//         webView?.evaluateJavaScript(script) { (result, error) in
//             // Handle the result or error if needed
//         }
//     }
// }

// @available(iOS 13.0, *)
// class WebViewController: UIViewController, WKNavigationDelegate {
//     var webView: WKWebView!
//     var url: String?

//     override func viewDidLoad() {
//         super.viewDidLoad()

//         webView = WKWebView()
//         webView.navigationDelegate = self
//         view.addSubview(webView)
//         webView.translatesAutoresizingMaskIntoConstraints = false
//         NSLayoutConstraint.activate([
//             webView.topAnchor.constraint(equalTo: view.topAnchor),
//             webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//             webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//             webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//         ])

//         if let urlString = url, let url = URL(string: urlString) {
//             let request = URLRequest(url: url)
//             webView.load(request)
//         }
//     }
// }



// extension WebViewMoFlutterPlugin: WKNavigationDelegate {
//     public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//         print("WebView did finish navigation")
        
//         // authorizeCharts(authToken: )
//         // loadCharts()
//     }
    
//     private func authorizeCharts(String authToken: String) {
        
//         webView?.evaluateJavaScript("ChartApp.v1.authorize('\(authToken)')") { (result, error) in
           
//         }
//         // Run authorization logic for charts
//     }
    
//     private func loadCharts() {
//         // Load charts
//     }
// }


import Flutter
import UIKit
import WebKit

public class WebViewMoFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "webview_mo_flutter", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "webview_plugin_events", binaryMessenger: registrar.messenger())
    let instance = WebViewMoFlutterPlugin()
    eventChannel.setStreamHandler(instance)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    private var webViewController: WebViewController?
  private var eventSink: FlutterEventSink?
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "loadUrl" {
      if let args = call.arguments as? [String: Any],
         let urlString = args["initialUrl"] as? String,
         let url = URL(string: urlString) {
        webViewController = WebViewController()
        webViewController?.url = url
        webViewController?.delegate = self
        UIApplication.shared.keyWindow?.rootViewController?.present(webViewController!, animated: true, completion: nil)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "URL is required", details: nil))
      }
    } else if call.method == "runJavaScript" {
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
      }
      
      else {
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
