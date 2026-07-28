import SwiftUI

@main
struct MasalciApp: App {
    @State private var environment = AppEnvironment.live()
    @AppStorage("masalci.uyku-zamanlayicisi") private var sleepTimer = 0

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .preferredColorScheme(.dark)
                .task {
                    await environment.start()
                }
                .onChange(of: sleepTimer, initial: true) { _, minutes in
                    environment.audioPlayer.setSleepTimer(minutes: minutes)
                }
        }
    }
}
