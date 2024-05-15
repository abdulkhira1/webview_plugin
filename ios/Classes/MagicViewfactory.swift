

// public class MagicViewFactory: NSObject, FlutterPlatformViewFactory {
//  init(messenger: FlutterBinaryMessenger) {
//    self.messenger = messenger
//  }
//  public func create(withFrame frame: CGRect, 
//                     viewIdentifier viewId: Int64, 
//                     arguments args: Any?) -> FlutterPlatformView {
//    return MagicViewContainer(messenger: messenger, 
//                              frame: frame, viewId: viewId,
//                              args: args)
//  }
//  public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
//    return FlutterStandardMessageCodec.sharedInstance()
//  }
// }