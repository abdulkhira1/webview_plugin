

// public class MagicPlatformView: NSObject, FlutterPlatformView {
//   let viewId: Int64
//   let magicView: MagicView
//   let messenger: FlutterBinaryMessenger
//   let channel: FlutterMethodChannel
//   init(messenger: FlutterBinaryMessenger, 
//        frame: CGRect, 
//        viewId: Int64, 
//        args: Any?) {
//    self.messenger = messenger
//    self.viewId = viewId
//    self.magicView = MagicView()
    
//    let channel = FlutterMethodChannel(name: "MagicView/\(Id)", 
//                                       binaryMessenger: messenger)
//    channel.setMethodCallHandler({ (call: FlutterMethodCall, result: FlutterResult) -> Void in
//      switch call.method {
//      case "receiveFromFlutter":
//       guard let args = call.arguments as? [String: Any],
//         let text = args["text"] as? String, else {
//         result(FlutterError(code: "-1", message: "Error"))
//         return
//       }
//        self.magicView.receiveFromFlutter(text)
//        result("receiveFromFlutter success")
//      default:
//          result(FlutterMethodNotImplemented)
//      }
//    })
//   }
//   public func sendFromNative(_ text: String) {
//     channel.invokeMethod("sendFromNative", arguments: text)
//   }
//   public func view() -> UIView {
//    return magicView
//   }
// }