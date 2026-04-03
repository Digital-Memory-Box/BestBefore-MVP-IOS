import Combine
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

class NotificationManager: NSObject, ObservableObject {
  static let shared = NotificationManager()

  @Published var fcmToken: String?

  private override init() {
    super.init()
    UNUserNotificationCenter.current().delegate = self
    Messaging.messaging().delegate = self
  }

  func requestPermissions() {
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
      if let error = error {
        print("[ERROR] Notification permission request failed: \(error.localizedDescription)")
      } else {
        print("[DEBUG] Notification permission granted: \(granted)")
        if granted {
          DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
          }
        }
      }
    }
  }

  func scheduleRoomUnlockNotification(for room: RoomObject) {
    guard let unlockDate = room.unlockDate, unlockDate > Date() else { return }

    let content = UNMutableNotificationContent()
    content.title = "Time's Up! 🔓"
    content.body = "Your room \"\(room.name)\" is now unlocked. Check out the memories!"
    
    // Check if custom chime exists in bundle, else use default.
    if let chimeURL = Bundle.main.url(forResource: "chime", withExtension: "mp3") {
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "chime.mp3"))
    } else {
        content.sound = .default
    }

    let components = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute, .second], from: unlockDate)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    let identifier = "unlock_\(room.id)"
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("[ERROR] Failed to schedule notification for \(room.name): \(error.localizedDescription)")
      } else {
        print("[DEBUG] Scheduled unlock notification for \(room.name) at \(unlockDate)")
      }
    }
  }
  
  func cancelUnlockNotification(for roomId: String) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["unlock_\(roomId)"])
  }
}

extension NotificationManager: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let token = fcmToken else { return }
    print("[DEBUG] FCM token received: \(token)")
    self.fcmToken = token
    Task {
      try? await Database.shared.updateFCMToken(token)
    }
  }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
  // Show notification even when app is in foreground
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .list, .sound])
  }

  // Handle tap on notification
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let _ = response.notification.request.content.userInfo
    completionHandler()
  }
}
