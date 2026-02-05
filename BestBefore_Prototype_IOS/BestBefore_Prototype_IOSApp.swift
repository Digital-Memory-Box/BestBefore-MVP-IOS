import FirebaseCore
import SwiftUI

@main
struct BestBefore_Prototype_IOSApp: App {
  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
