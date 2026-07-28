import MasalciCore
import SwiftUI

struct HomeView: View {
    @State private var model: HomeModel
    private let apiBaseURL: URL

    init(apiClient: APIClient, apiBaseURL: URL) {
        _model = State(initialValue: HomeModel(apiClient: apiClient))
        self.apiBaseURL = apiBaseURL
    }

    var body: some View {
        ZStack {
            NightSkyBackground()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    header

                    if let featured = model.featuredStory {
                        FeaturedStoryView(story: featured, apiBaseURL: apiBaseURL)
                    }

                    categorySection

                    if model.isLoading && model.stories.isEmpty {
                        loadingGrid
                    } else if let message = model.errorMessage, model.stories.isEmpty {
                        errorState(message)
                    } else if model.stories.isEmpty {
                        emptyState
                    } else {
                        StoryGrid(stories: model.stories, apiBaseURL: apiBaseURL)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .refreshable { await model.load() }
        }
        .navigationBarHidden(true)
        .task(id: model.selectedCategory) {
            await model.load()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("İyi geceler")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MasalTheme.apricot)
                Text("Bir masal seçelim")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(MasalTheme.cream)
            }
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .symbolRenderingMode(.palette)
                .foregroundStyle(MasalTheme.cream, MasalTheme.lavender)
                .frame(width: 48, height: 48)
                .background(MasalTheme.night800, in: Circle())
                .accessibilityHidden(true)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Masal kategorisi")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(MasalTheme.cream)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    categoryButton(title: "Tümü", category: nil)
                    ForEach(model.categories, id: \.self) { category in
                        categoryButton(title: category, category: category)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func categoryButton(title: String, category: String?) -> some View {
        let isSelected = model.selectedCategory == category
        return Button {
            model.selectedCategory = category
        } label: {
            Label(title, systemImage: isSelected ? "sparkles" : "circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : MasalTheme.textSecondary)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(
                    isSelected ? AnyShapeStyle(MasalTheme.actionGradient) : AnyShapeStyle(MasalTheme.night800),
                    in: Capsule()
                )
                .overlay {
                    Capsule().stroke(MasalTheme.cream.opacity(isSelected ? 0.28 : 0.10))
                }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var loadingGrid: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(MasalTheme.apricot)
            Text("Masallar yükleniyor…")
                .foregroundStyle(MasalTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private func errorState(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Masallara ulaşılamadı", systemImage: "cloud.moon.fill")
        } description: {
            Text(message)
        } actions: {
            Button("Yeniden Dene") { Task { await model.load() } }
                .buttonStyle(MasalPrimaryButtonStyle())
        }
        .foregroundStyle(MasalTheme.textPrimary)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Henüz masal yok",
            systemImage: "books.vertical.fill",
            description: Text("Yeni masallar hazırlanırken biraz sonra yeniden bakabilirsin.")
        )
        .foregroundStyle(MasalTheme.textPrimary)
    }
}
