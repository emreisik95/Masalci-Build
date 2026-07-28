import SwiftUI

struct PaywallView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            NightSkyBackground()
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 72))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(MasalTheme.cream, MasalTheme.apricot)
                        .padding(.top, 24)

                    VStack(spacing: 8) {
                        Text("Sınırsız Masal Geceleri")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(MasalTheme.cream)
                            .multilineTextAlignment(.center)
                        Text("Her gece yeni bir macera, reklam olmadan ve aile dostu içerikle.")
                            .foregroundStyle(MasalTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        benefit("Sınırsız kişiye özel masal", symbol: "wand.and.stars")
                        benefit("Türkçe sesli anlatım", symbol: "waveform")
                        benefit("Yeni çocuk kitabı illüstrasyonları", symbol: "paintpalette.fill")
                        benefit("Satın alımları geri yükleme", symbol: "arrow.clockwise")
                    }
                    .padding(18)
                    .masalCard()

                    subscriptionOptions

                    Button("Satın Alımları Geri Yükle") {
                        Task {
                            if await environment.subscriptionService.restore() {
                                environment.updatePremium(true)
                                dismiss()
                            }
                        }
                    }
                    .foregroundStyle(MasalTheme.cream)
                    .frame(minHeight: 44)

                    Link(
                        "Apple standart kullanım koşulları",
                        destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
                    )
                    .font(.caption)
                    .foregroundStyle(MasalTheme.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button("Kapat", systemImage: "xmark") { dismiss() }
                .labelStyle(.iconOnly)
                .frame(width: 48, height: 48)
                .masalReadableMaterial(in: Circle())
                .padding(16)
        }
        .task { await environment.subscriptionService.loadOfferings() }
    }

    @ViewBuilder
    private var subscriptionOptions: some View {
        let service = environment.subscriptionService
        switch service.state {
        case .loading, .purchasing:
            ProgressView(service.state == .purchasing ? "Satın alma hazırlanıyor…" : "Seçenekler yükleniyor…")
                .tint(MasalTheme.apricot)
                .foregroundStyle(MasalTheme.textSecondary)
                .frame(minHeight: 100)
        case let .unavailable(message), let .failed(message):
            VStack(spacing: 12) {
                Text(message)
                    .foregroundStyle(MasalTheme.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Yeniden Dene") {
                    Task { await service.loadOfferings() }
                }
                .buttonStyle(MasalPrimaryButtonStyle())
            }
        case .ready, .purchased:
            VStack(spacing: 12) {
                ForEach(service.options) { option in
                    Button {
                        Task {
                            if await service.purchase(optionID: option.id) {
                                environment.updatePremium(true)
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(option.title).font(.headline)
                                Text(option.detail)
                                    .font(.caption)
                                    .foregroundStyle(MasalTheme.textSecondary)
                            }
                            Spacer()
                            Text(option.price)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(MasalTheme.cream)
                        }
                        .padding(17)
                        .masalCard()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func benefit(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.headline)
            .foregroundStyle(MasalTheme.textPrimary)
    }
}
