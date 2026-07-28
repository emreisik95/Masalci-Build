import MasalciCore
import SwiftUI

struct StoryDetailView: View {
    let story: Story
    let apiBaseURL: URL
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @AppStorage("masalci.otomatik-oynat") private var autoplay = false
    @State private var model: StoryDetailModel?

    var body: some View {
        ZStack(alignment: .bottom) {
            NightSkyBackground()

            if let model {
                storyContent(model)
                playerBar(model)
            } else {
                ProgressView()
                    .tint(MasalTheme.apricot)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if model == nil {
                model = StoryDetailModel(story: story, apiClient: environment.apiClient)
            }
        }
    }

    private func storyContent(_ model: StoryDetailModel) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    StoryArtwork(
                        title: model.story.title,
                        categories: model.story.categories,
                        imageURL: model.story.imageURL,
                        baseURL: apiBaseURL
                    )
                    .frame(height: 390)
                    .clipped()

                    LinearGradient(
                        colors: [.clear, MasalTheme.night900],
                        startPoint: .center,
                        endPoint: .bottom
                    )

                    HStack {
                        roundButton(label: "Geri dön", symbol: "chevron.left") { dismiss() }
                        Spacer()
                        roundButton(
                            label: model.isFavorite ? "Favorilerden çıkar" : "Favorilere ekle",
                            symbol: model.isFavorite ? "heart.fill" : "heart",
                            foreground: model.isFavorite ? MasalTheme.apricot : .white
                        ) {
                            Task { await model.toggleFavorite() }
                        }
                        .disabled(model.isUpdatingFavorite)
                    }
                    .padding(18)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text(model.story.title)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(MasalTheme.cream)

                    HStack(spacing: 14) {
                        Label(model.story.categories.first ?? "Masal", systemImage: "moon.fill")
                        Label("\(model.likesCount)", systemImage: "heart.fill")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MasalTheme.apricot)

                    Text(model.story.summary)
                        .font(.title3)
                        .foregroundStyle(MasalTheme.textSecondary)

                    Divider().overlay(MasalTheme.cream.opacity(0.16))

                    if model.isLoading, model.story.content == nil {
                        ProgressView("Masalın tamamı açılıyor…")
                            .tint(MasalTheme.apricot)
                    } else {
                        Text(
                            model.story.content
                                ?? "Bu masalın tamamı hazırlanıyor. Çok yakında burada olacak."
                        )
                        .font(.body)
                        .foregroundStyle(MasalTheme.textPrimary)
                        .lineSpacing(8)
                        .textSelection(.enabled)
                    }

                    if let error = model.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(MasalTheme.cream)
                    }
                }
                .padding(22)
                .padding(.bottom, 126)
            }
        }
        .task {
            await model.load()
            guard autoplay,
                  model.story.audioURL != nil,
                  environment.audioPlayer.currentStory?.id != model.story.id else {
                return
            }
            environment.audioPlayer.toggle(story: model.story, baseURL: apiBaseURL)
        }
    }

    private func playerBar(_ model: StoryDetailModel) -> some View {
        let audio = environment.audioPlayer
        let isCurrent = audio.currentStory?.id == model.story.id
        let isPlaying = isCurrent && audio.state == .playing
        return VStack(spacing: 9) {
            if isCurrent, audio.duration > 0 {
                ProgressView(value: audio.currentTime, total: audio.duration)
                    .tint(MasalTheme.apricot)
                    .accessibilityLabel("Masal ilerlemesi")
                    .accessibilityValue("Yüzde \(Int((audio.currentTime / audio.duration) * 100))")
            }
            HStack(spacing: 30) {
                Button("15 saniye geri", systemImage: "gobackward.15") {
                    audio.seek(by: -15)
                }
                .labelStyle(.iconOnly)
                .frame(width: 48, height: 48)

                Button(isPlaying ? "Duraklat" : "Masalı oynat", systemImage: isPlaying ? "pause.fill" : "play.fill") {
                    audio.toggle(story: model.story, baseURL: apiBaseURL)
                }
                .labelStyle(.iconOnly)
                .font(.title)
                .frame(width: 66, height: 66)
                .background(MasalTheme.actionGradient, in: Circle())
                .disabled(model.story.audioURL == nil)
                .opacity(model.story.audioURL == nil ? 0.5 : 1)

                Button("15 saniye ileri", systemImage: "goforward.15") {
                    audio.seek(by: 15)
                }
                .labelStyle(.iconOnly)
                .frame(width: 48, height: 48)
            }
            .font(.title2)
            .foregroundStyle(.white)

            if model.story.audioURL == nil {
                Text("Ses kaydı henüz hazır değil")
                    .font(.caption)
                    .foregroundStyle(MasalTheme.textSecondary)
            } else if case let .failed(message) = audio.state, isCurrent {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(MasalTheme.cream)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .masalReadableMaterial()
    }

    private func roundButton(
        label: String,
        symbol: String,
        foreground: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .foregroundStyle(foreground)
                .frame(width: 48, height: 48)
                .masalReadableMaterial(in: Circle())
        }
        .accessibilityLabel(label)
    }
}
