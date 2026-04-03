import FirebaseCore
import FirebaseMessaging
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()

    // Set delegates
    UNUserNotificationCenter.current().delegate = NotificationManager.shared

    // Request initial permissions (registers for remote notifications if granted)
    NotificationManager.shared.requestPermissions()

    return true
  }

  // Forward APNs token to Firebase so it can map to an FCM token
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }

  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("[ERROR] Failed to register for remote notifications: \(error.localizedDescription)")
  }
}

@main
struct BestBefore_Prototype_IOSApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  @StateObject private var inviteManager = InviteManager.shared

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(inviteManager)
        .fullScreenCover(item: $inviteManager.activeInvite) { invite in
          IncomingInviteView(invite: invite, inviteManager: inviteManager)
        }
        .onOpenURL { url in
          print("[DEBUG] Opened URL: \(url)")
          if url.scheme == "bestbefore" && url.host == "room" {
            let roomId = url.lastPathComponent
            print("[DEBUG] Deep link detected for Room ID: \(roomId)")
            inviteManager.deepLinkedRoomId = roomId
          }
        }
    }
  }
}
