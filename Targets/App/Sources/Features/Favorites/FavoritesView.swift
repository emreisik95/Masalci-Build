import SwiftUI

struct FavoritesView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: FavoritesModel?

    var body: some View {
        ZStack {
            NightSkyBackground()

            if let model {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        content(model)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 30)
                }
                .refreshable { await model.load() }
                .task { await model.load() }
            } else {
                ProgressView()
                    .tint(MasalTheme.apricot)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if model == nil {
                model = FavoritesModel(apiClient: environment.apiClient)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Favoriler", systemImage: "heart.fill")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(MasalTheme.cream)
            Text("Tekrar tekrar dinlemek istediğin masallar")
                .foregroundStyle(MasalTheme.textSecondary)
        }
    }

    @ViewBuilder
    private func content(_ model: FavoritesModel) -> some View {
        if model.isLoading && model.stories.isEmpty {
            ProgressView("Favoriler yükleniyor…")
                .tint(MasalTheme.apricot)
                .foregroundStyle(MasalTheme.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 300)
        } else if let error = model.errorMessage, model.stories.isEmpty {
            ContentUnavailableView {
                Label("Favorilere ulaşılamadı", systemImage: "heart.slash.fill")
            } description: {
                Text(error)
            } actions: {
                Button("Yeniden Dene") { Task { await model.load() } }
                    .buttonStyle(MasalPrimaryButtonStyle())
            }
            .foregroundStyle(MasalTheme.textPrimary)
        } else if model.stories.isEmpty {
            ContentUnavailableView(
                "Henüz favorin yok",
                systemImage: "heart.circle.fill",
                description: Text("Sevdiğin bir masaldaki kalbe dokun; burada hep yanında olsun.")
            )
            .foregroundStyle(MasalTheme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 300)
        } else {
            StoryGrid(stories: model.stories, apiBaseURL: environment.apiBaseURL)
        }
    }
}
