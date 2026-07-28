import MasalciCore
import SwiftUI

struct CreateStoryView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model: CreateStoryModel?

    var body: some View {
        ZStack {
            NightSkyBackground()

            if let model {
                content(model)
            } else {
                ProgressView("Masal atölyesi hazırlanıyor…")
                    .tint(MasalTheme.apricot)
                    .foregroundStyle(MasalTheme.textSecondary)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if model == nil {
                model = CreateStoryModel(
                    apiClient: environment.apiClient,
                    creditsChanged: environment.updateCredits
                )
            }
        }
    }

    @ViewBuilder
    private func content(_ model: CreateStoryModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                promptSection(model)
                durationSection(model)

                if model.isLoadingElements {
                    ProgressView("Masal arkadaşları geliyor…")
                        .tint(MasalTheme.apricot)
                        .foregroundStyle(MasalTheme.textSecondary)
                } else {
                    elementSection(
                        title: "Kahramanlar",
                        subtitle: "En fazla 3 arkadaş seç",
                        elements: model.characters,
                        selected: model.selectedCharacterIDs,
                        action: model.toggleCharacter
                    )
                    elementSection(
                        title: "Masalın geçtiği yer",
                        subtitle: "En fazla 2 yer seç",
                        elements: model.places,
                        selected: model.selectedPlaceIDs,
                        action: model.togglePlace
                    )
                    voiceSection(model)
                }

                if let error = model.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MasalTheme.cream)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(MasalTheme.berry.opacity(0.28), in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityIdentifier("olustur.hata")
                }

                Button {
                    Task { await model.createStory() }
                } label: {
                    Label(
                        model.isSubmitting ? "Masal hazırlanıyor…" : "Büyülü bir masal oluştur",
                        systemImage: model.isSubmitting ? "sparkles" : "wand.and.stars"
                    )
                }
                .buttonStyle(MasalPrimaryButtonStyle())
                .disabled(!model.canSubmit)
                .opacity(model.canSubmit ? 1 : 0.5)
                .accessibilityIdentifier("olustur.baslat")
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .task { await model.loadElements() }
        .overlay {
            if model.isSubmitting, let generation = model.generation {
                generationOverlay(generation)
            }
        }
        .sheet(
            item: Binding(
                get: { model.completedStory },
                set: { model.completedStory = $0 }
            )
        ) { story in
            NavigationStack {
                StoryDetailView(story: story, apiBaseURL: environment.apiBaseURL)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Bitti") { model.resetAfterCompletion() }
                        }
                    }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Masal Oluştur")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(MasalTheme.cream)
                Text("Hayalini yaz, Masalcı canlandırsın")
                    .foregroundStyle(MasalTheme.textSecondary)
            }
            Spacer()
            Label(
                environment.profile?.premium == true
                    ? "Sınırsız"
                    : "\(environment.profile?.credits ?? 0)",
                systemImage: "sparkles"
            )
            .font(.headline.weight(.bold))
            .foregroundStyle(MasalTheme.cream)
            .padding(.horizontal, 13)
            .frame(minHeight: 44)
            .background(MasalTheme.night800, in: Capsule())
            .accessibilityLabel(
                environment.profile?.premium == true
                    ? "Sınırsız masal hakkı"
                    : "\(environment.profile?.credits ?? 0) masal kredisi"
            )
        }
    }

    private func promptSection(_ model: CreateStoryModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Nasıl bir masal olsun?", systemImage: "moon.stars.fill")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(MasalTheme.cream)

            TextEditor(
                text: Binding(
                    get: { model.prompt },
                    set: { model.prompt = $0 }
                )
            )
                .font(.body)
                .foregroundStyle(MasalTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 132)
                .padding(12)
                .background(MasalTheme.night800, in: RoundedRectangle(cornerRadius: 20))
                .overlay(alignment: .topLeading) {
                    if model.prompt.isEmpty {
                        Text("Örneğin: Ay ışığında kaybolan minik bir tavşan, dostlarıyla evine dönsün…")
                            .foregroundStyle(MasalTheme.textSecondary)
                            .padding(18)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityLabel("Masal fikri")

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(MasalTheme.mint)
                Text("Güvenliğin için ad, okul, adres veya telefon gibi kişisel bilgileri yazma.")
                    .font(.caption)
                    .foregroundStyle(MasalTheme.textSecondary)
            }
        }
    }

    private func durationSection(_ model: CreateStoryModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Masal süresi", systemImage: "hourglass")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(MasalTheme.cream)
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(StoryDuration.allCases, id: \.self) { duration in
                        let selected = model.duration == duration
                        Button(duration.title) { model.duration = duration }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(selected ? .white : MasalTheme.textSecondary)
                            .padding(.horizontal, 18)
                            .frame(minHeight: 44)
                            .background(
                                selected ? AnyShapeStyle(MasalTheme.actionGradient) : AnyShapeStyle(MasalTheme.night800),
                                in: Capsule()
                            )
                            .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func elementSection(
        title: String,
        subtitle: String,
        elements: [StoryElement],
        selected: Set<String>,
        action: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(MasalTheme.cream)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(MasalTheme.textSecondary)
            }
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(elements) { element in
                        StoryElementCard(
                            element: element,
                            symbol: symbol(for: element),
                            isSelected: selected.contains(element.id),
                            action: action
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func voiceSection(_ model: CreateStoryModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Anlatıcı")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(MasalTheme.cream)

            if model.voices.isEmpty {
                Label("Sıcak varsayılan anlatıcı", systemImage: "waveform.circle.fill")
                    .foregroundStyle(MasalTheme.textPrimary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .masalCard()
            } else {
                ForEach(model.voices) { voice in
                    Button { model.selectedVoiceID = voice.id } label: {
                        HStack {
                            Image(systemName: "waveform.circle.fill")
                                .font(.title2)
                                .foregroundStyle(MasalTheme.apricot)
                            VStack(alignment: .leading) {
                                Text(voice.name).font(.headline)
                                Text(voice.description ?? "Sıcak Türkçe anlatım")
                                    .font(.caption)
                                    .foregroundStyle(MasalTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: model.selectedVoiceID == voice.id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(MasalTheme.apricot)
                        }
                        .foregroundStyle(MasalTheme.textPrimary)
                        .padding(14)
                        .masalCard()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func generationOverlay(_ generation: GenerationStatus) -> some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(MasalTheme.night700, lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: max(0.03, generation.progress))
                        .stroke(MasalTheme.actionGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(MasalTheme.cream)
                }
                .frame(width: 112, height: 112)
                .accessibilityLabel("Masal hazırlanıyor")
                .accessibilityValue("Yüzde \(Int(generation.progress * 100))")

                Text(generation.statusMessage)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(MasalTheme.cream)
                    .multilineTextAlignment(.center)
                Text("Uygulamayı açık tutmana gerek yok; masalın güvenle hazırlanıyor.")
                    .font(.subheadline)
                    .foregroundStyle(MasalTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(28)
            .frame(maxWidth: 330)
            .masalCard()
        }
    }

    private func symbol(for element: StoryElement) -> String {
        switch element.kind {
        case .character: "hare.fill"
        case .place: "mountain.2.fill"
        case .voice: "waveform.circle.fill"
        }
    }
}

private struct StoryElementCard: View {
    let element: StoryElement
    let symbol: String
    let isSelected: Bool
    let action: (String) -> Void

    var body: some View {
        Button { action(element.id) } label: {
            VStack(spacing: 9) {
                Image(systemName: symbol)
                    .font(.system(size: 34))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(MasalTheme.cream, MasalTheme.apricot)
                    .frame(width: 74, height: 66)
                    .background(MasalTheme.night700, in: RoundedRectangle(cornerRadius: 18))
                Text(element.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MasalTheme.textPrimary)
                    .lineLimit(2)
            }
            .frame(width: 104)
            .frame(minHeight: 118)
            .padding(8)
            .background(MasalTheme.night800, in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        isSelected ? MasalTheme.apricot : MasalTheme.cream.opacity(0.10),
                        lineWidth: isSelected ? 3 : 1
                    )
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white, MasalTheme.berry)
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(element.name)
        .accessibilityValue(isSelected ? "Seçildi" : "Seçilmedi")
    }
}
