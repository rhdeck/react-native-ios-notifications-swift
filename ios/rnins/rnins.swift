import Foundation
import UserNotifications
import ReactNativeAdvancedRegistry
@available(iOS 10.0, *)
@objc
class RNNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, RNSStartable {
    static var instance = RNNotificationDelegate();
    
    @objc public static func runOnStart(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = RNNotificationDelegate.instance
        let _ = RNSMainRegistry.addEvent(type: "app.didBecomeActive", key: "RNINS.core") { _ in
            let _ = RNSMainRegistry.setData(key: "app.didBecomeActive", value: "true")
            return true
        }
        let _ = RNSMainRegistry.addEvent(type: "app.didReceiveResponse", key:"RNINS.core") { data in
            guard let n = data as? [String: Any?] else { return false}
            if let r = n["response"] as? UNNotificationResponse {
               let actionIdentifier = r.actionIdentifier
               let notification = r.notification
                let request = notification.request
                let date = notification.date.timeIntervalSince1970
                let content = request.content
                let title=content.title
                let subtitle = content.subtitle
                let userInfo = content.userInfo
                let value = [
                   "actionIdentifier": actionIdentifier,
                   "notification":[
                       "date": date,
                       "content": [
                           "title": title,
                           "subtitle": subtitle,
                           "userInfo": userInfo
                       ]
                   ]
                ] as [String : Any]
                if let _ = RNSMainRegistry.getData(key: "app.didBecomeActive") {
                    let _ = RNSMainRegistry.triggerEventNoSync(type:"notificationAction", data:value)
                } else {
                    let _ = RNSMainRegistry.setData(key:"startingNotificationAction", value:value
                    )
                }
            }
            return true
        }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        let _ = RNSMainRegistry.triggerEvent(type: "app.didOpenSettingsForNotification", data: notification as Any)
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        RNSMainRegistry.setData(key: "notification.payload", value: response.notification.request.content.userInfo)
        let _ = RNSMainRegistry.triggerEvent(type: "app.didReceiveResponse", data: ["response": response, "completionHandler": completionHandler])
        
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if(  !RNSMainRegistry.triggerEvent(type: "app.willPresentNotification", data: ["notification": notification, "completionHandler": completionHandler])) {
            completionHandler(.alert)
        }
    }
}
//Note that for objective-c (and therefore RN) to see the class you need to give the @objc hint
//Also, any method exposed to objective-c runtime will also require the hint.
@objc(rnins)
class rnins: NSObject {
    override init() {
        //Force connection with IOSPush
        let _ = RNSMainRegistry.addEvent(type: "app.didRegisterForRemoteNotifications", key: "RNINS") { data in
            guard let token = data as? Data else { return false }
            RNCPushNotificationIOS.didRegisterForRemoteNotifications(withDeviceToken: token);
            return true
        }
        let _ = RNSMainRegistry.addEvent(type: "app.didRegisterUserNotificationSettings", key: "RNINS") {data in
            guard let ns = data as? UIUserNotificationSettings else { return false}
            RNCPushNotificationIOS.didRegister(ns)
            return true
        }
        let _ = RNSMainRegistry.addEvent(type: "app.didReceiveRemoteNotification", key: "RNINS") { data in
            guard let n = data as? [String: Any?] else { return false }
            RNCPushNotificationIOS.didReceiveRemoteNotification(n as [AnyHashable : Any])
            return true
        }
        let _ = RNSMainRegistry.addEvent(type: "app.didFailToRegisterForRemoteNotifications", key: "RNINS") { data in
            guard let e = data as? Error else { return false }
            RNCPushNotificationIOS.didFailToRegisterForRemoteNotificationsWithError(e)
            return true
        }
        let _ = RNSMainRegistry.addEvent(type: "app.didReceiveLocalNotification", key: "RNINS") { data in
            guard let n = data as? UILocalNotification else { return false }
            RNCPushNotificationIOS.didReceive(n)
            return true
        }
        let _ = RNSMainRegistry.addEvent(type: "app.didReceiveResponse", key: "RNINS") { data in
            guard let n = data as? [String: Any?] else { return false}
            if #available(iOS 10.0, *) {
                RNCPushNotificationIOS.didReceive(n["response"] as? UNNotificationResponse)
                //Let's save it to local just in case
            } else {
                // Fallback on earlier versions
            }
            return true
        }
    }
    @objc func noop() {
        //No-op function
    }
    @objc static func requiresMainQueueSetup() -> Bool {
        return true;
    }
}
