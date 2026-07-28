import SwiftUI

struct MiniPlayerView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        if let story = environment.audioPlayer.currentStory {
            HStack(spacing: 12) {
                Image(systemName: "moon.stars.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(MasalTheme.cream, MasalTheme.apricot)
                    .frame(width: 44, height: 44)
                    .background(MasalTheme.night700, in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(story.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(MasalTheme.cream)
                        .lineLimit(1)
                    Text(environment.audioPlayer.state == .playing ? "Şimdi dinleniyor" : "Duraklatıldı")
                        .font(.caption)
                        .foregroundStyle(MasalTheme.textSecondary)
                }

                Spacer()

                Button(
                    environment.audioPlayer.state == .playing ? "Duraklat" : "Oynat",
                    systemImage: environment.audioPlayer.state == .playing ? "pause.fill" : "play.fill"
                ) {
                    if environment.audioPlayer.state == .playing {
                        environment.audioPlayer.pause()
                    } else {
                        environment.audioPlayer.play()
                    }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(MasalTheme.actionGradient, in: Circle())

                Button("Oynatıcıyı kapat", systemImage: "xmark") {
                    environment.audioPlayer.stop()
                }
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
                .foregroundStyle(MasalTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .masalReadableMaterial()
            .overlay(alignment: .top) {
                if environment.audioPlayer.duration > 0 {
                    ProgressView(
                        value: environment.audioPlayer.currentTime,
                        total: environment.audioPlayer.duration
                    )
                    .tint(MasalTheme.apricot)
                    .accessibilityLabel("Masal ilerlemesi")
                    .accessibilityValue(
                        "Yüzde \(Int((environment.audioPlayer.currentTime / environment.audioPlayer.duration) * 100))"
                    )
                }
            }
            .accessibilityElement(children: .contain)
        }
    }
}
