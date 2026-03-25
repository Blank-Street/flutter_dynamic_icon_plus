import Flutter
import UIKit

public class FlutterDynamicIconPlusPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_dynamic_icon_plus", binaryMessenger: registrar.messenger())
        let instance = FlutterDynamicIconPlusPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case MethodNames.supportsAlternateIcons:
            if #available(iOS 10.3, *){
                result(UIApplication.shared.supportsAlternateIcons)
            }
            else {
                result(FlutterError(code: "Unavailable", message: "Method supportsAlternateIcons unsupported on iOS version < 10.3", details: nil))
            }
        case MethodNames.getAlternateIconName:
            if #available(iOS 10.3, *){
                result(UIApplication.shared.alternateIconName)
            }
            else {
                result(FlutterError(code: "Unavailable", message: "Method getAlternateIconName unsupported on iOS version < 10.3", details: nil))
            }
        case MethodNames.setAlternateIconName:
            if #available(iOS 10.3, *){
                do {
                    let args = call.arguments as! [String: Any]
                    var iconName = args[Arguments.iconName]
                    let isSilent = args[Arguments.isSilent]
                    
                    if (iconName == nil) {
                        iconName = nil
                    }
                    
                    if let isSilent = isSilent as? Bool, isSilent {
                        self.setIconWithoutAlert(iconName as? String, result: result)
                    } else {
                        self.setIconWithAlert(iconName as? String, result: result)
                    }

                    result(nil)
                } catch {
                    let errorReason = (error as NSError).localizedDescription.isEmpty
                        ? "Unknown Error setAlternateIconName"
                        : (error as NSError).localizedDescription
                    print("\(errorReason)")
                    result(
                        FlutterError(
                            code: "Failed to set icon: \(errorReason)",
                            message: errorReason,
                            details: nil))
                }
            }
            else {
                result(FlutterError(code: "Unavailable", message: "Method setAlternateIconName unsupported on iOS version < 10.3", details: nil))
            }
        case MethodNames.getApplicationIconBadgeNumber:
            if #available(iOS 10.3, *){
                result(NSNumber(value: UIApplication.shared.applicationIconBadgeNumber))
            }
            else {
                result(FlutterError(code: "Unavailable", message: "Method getApplicationIconBadgeNumber unsupported on iOS version < 10.3", details: nil))
            }
        case MethodNames.setApplicationIconBadgeNumber:
            let args = call.arguments as! [String: Any]
            if #available(iOS 10.3, *){
                if #available(iOS 10.0, *) {
                    UNUserNotificationCenter.current().requestAuthorization(options: .badge) { granted, error in
                        if granted {
                            do {
                                let batchIconNumber = (args[Arguments.batchIconNumber] as? NSNumber)?.intValue ?? 0
                                UIApplication.shared.applicationIconBadgeNumber = batchIconNumber
                                result(nil)
                            } catch {
                                let errorReason = (error as NSError).localizedDescription.isEmpty
                                    ? "Unknown Error setApplicationIconBadgNumber"
                                    : (error as NSError).localizedDescription
                                print("\(errorReason)")
                                result(
                                    FlutterError(
                                        code: "Failed to set batch icon number",
                                        message: errorReason,
                                        details: nil))
                            }
                        }
                        else {
                            do {
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
                                    (granted, error) in
                                    let batchIconNumber = (args[Arguments.batchIconNumber] as? NSNumber)?.intValue ?? 0
                                    UIApplication.shared.applicationIconBadgeNumber = batchIconNumber
                                    result(nil)
                                }
                            } catch {
                                let errorReason = (error as NSError).localizedDescription.isEmpty
                                    ? "Unknown Error setApplicationIconBadgeNumber"
                                    : (error as NSError).localizedDescription
                                print("\(errorReason)")
                                result(
                                    FlutterError(
                                        code: "Failed to set icon",
                                        message: errorReason,
                                        details: nil))
                            }
                        }
                    }
                }
                else {
                    result(
                        FlutterError(
                            code: "Failed to set batch icon number",
                            message: "Permission denied by the user",
                            details: nil))
                }
            }
            else {
                do {
                    let notificationSettings = UIUserNotificationSettings(types: .badge, categories: nil)
                    
                    UIApplication.shared.registerUserNotificationSettings(notificationSettings)
                    let batchIconNumber = (args[Arguments.batchIconNumber] as? NSNumber)?.intValue ?? 0
                    UIApplication.shared.applicationIconBadgeNumber = batchIconNumber
                    result(nil)
                } catch {
                    let errorReason = (error as NSError).localizedDescription.isEmpty
                        ? "Unknown Error setApplicationIconBadgeNumber"
                        : (error as NSError).localizedDescription
                    print(errorReason)
                    result(
                        FlutterError(
                            code: "Failed to set batch icon number",
                            message: errorReason,
                            details: nil))
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func setIconWithoutAlert(_ appIcon: String?, result: @escaping FlutterResult) {
        print("setIconWithoutAlert: \(appIcon)")
        if UIApplication.shared.responds(to: #selector(getter: UIApplication.supportsAlternateIcons)) && UIApplication.shared.supportsAlternateIcons {
            typealias setAlternateIconName = @convention(c) (NSObject, Selector, NSString?, @escaping (NSError) -> ()) -> ()
            let selectorString = "_setAlternateIconName:completionHandler:"
            let selector = NSSelectorFromString(selectorString)
            let imp = UIApplication.shared.method(for: selector)
            let method = unsafeBitCast(imp, to: setAlternateIconName.self)
            method(UIApplication.shared, selector, appIcon as NSString?, { _ in })
        } else {
            result(nil)
        }
    }
    
    private func setIconWithAlert(_ appIcon: String?, result: @escaping FlutterResult) {
        UIApplication.shared.setAlternateIconName(appIcon) { error in
            if let error {
                result(
                    FlutterError(
                        code: "Failed to set icon \(error.localizedDescription)",
                        message: error.localizedDescription,
                        details: nil))
            } else {
                result(nil)
            }
        }
    }
}
