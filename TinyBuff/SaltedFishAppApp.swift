import SwiftUI

@main
struct SaltedFishAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
                .statusBarHidden()
        }
    }
}
