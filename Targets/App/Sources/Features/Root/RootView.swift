import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        ZStack {
            NightSkyBackground()

            switch environment.launchState {
            case .starting:
                launchView
            case .ready:
                tabs
            case let .failed(message):
                launchError(message)
            }
        }
    }

    private var tabs: some View {
        TabView {
            NavigationStack {
                HomeView(apiClient: environment.apiClient, apiBaseURL: environment.apiBaseURL)
            }
            .tabItem { Label("Ana Sayfa", systemImage: "house.fill") }
            .accessibilityIdentifier("sekme.ana-sayfa")

            NavigationStack {
                CreateStoryView()
            }
            .tabItem { Label("Oluştur", systemImage: "wand.and.stars") }
            .accessibilityIdentifier("sekme.olustur")

            NavigationStack {
                FavoritesView()
            }
            .tabItem { Label("Favoriler", systemImage: "heart.fill") }
            .accessibilityIdentifier("sekme.favoriler")

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Ayarlar", systemImage: "gearshape.fill") }
            .accessibilityIdentifier("sekme.ayarlar")
        }
        .tint(MasalTheme.apricot)
        .toolbarBackground(MasalTheme.night800, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if environment.audioPlayer.currentStory != nil {
                MiniPlayerView()
                    .environment(environment)
            }
        }
    }

    private var launchView: some View {
        VStack(spacing: 18) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 76, weight: .semibold, design: .rounded))
                .symbolRenderingMode(.palette)
                .foregroundStyle(MasalTheme.cream, MasalTheme.apricot)
            Text("Masalcı")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(MasalTheme.cream)
            ProgressView("Masal dünyası hazırlanıyor…")
                .tint(MasalTheme.apricot)
                .foregroundStyle(MasalTheme.textSecondary)
        }
    }

    private func launchError(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Bağlantı kurulamadı", systemImage: "cloud.moon.rain.fill")
        } description: {
            Text(message)
        } actions: {
            Button("Yeniden Dene") {
                Task { await environment.start() }
            }
            .buttonStyle(MasalPrimaryButtonStyle())
        }
        .foregroundStyle(MasalTheme.textPrimary)
        .padding(24)
    }
}
