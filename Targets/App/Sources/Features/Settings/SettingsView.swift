import AuthenticationServices
import SwiftUI
import UserNotifications

struct SettingsView: View {
    private static let reminderIdentifier = "masalci.gece-masali-hatirlaticisi"

    @Environment(AppEnvironment.self) private var environment
    @AppStorage("masalci.otomatik-oynat") private var autoplay = false
    @AppStorage("masalci.uyku-zamanlayicisi") private var sleepTimer = 0
    @State private var notificationsEnabled = false
    @State private var isParentUnlocked = false
    @State private var showsParentGate = false
    @State private var showsPaywall = false
    @State private var showsPrivacy = false
    @State private var showsDeleteConfirmation = false
    @State private var appleNonce: String?
    @State private var message: String?

    var body: some View {
        ZStack {
            NightSkyBackground()

            List {
                profileSection
                experienceSection
                parentSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .listSectionSpacing(20)
        }
        .navigationTitle("Ayarlar")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showsParentGate) {
            ParentGateView(isUnlocked: $isParentUnlocked)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showsPaywall) {
            PaywallView()
                .environment(environment)
        }
        .sheet(isPresented: $showsPrivacy) {
            PrivacyView()
        }
        .confirmationDialog(
            "Hesabın kalıcı olarak silinsin mi?",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Hesabı Kalıcı Olarak Sil", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Favorilerin, oluşturduğun masallar ve oturum bilgilerin silinir. Bu işlem geri alınamaz.")
        }
        .alert("Masalcı", isPresented: messageBinding) {
            Button("Tamam") { message = nil }
        } message: {
            Text(message ?? "")
        }
        .task { await refreshNotificationState() }
    }

    private var profileSection: some View {
        Section {
            HStack(spacing: 14) {
                Image(systemName: "moon.stars.circle.fill")
                    .font(.system(size: 44))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(MasalTheme.cream, MasalTheme.lavender)
                VStack(alignment: .leading, spacing: 3) {
                    Text(environment.profile?.accountKind == .apple ? "Masalcı Ailesi" : "Misafir Masalcı")
                        .font(.headline)
                    Text(profileDetail)
                        .font(.subheadline)
                        .foregroundStyle(MasalTheme.textSecondary)
                }
            }
            .padding(.vertical, 6)
        }
        .listRowBackground(MasalTheme.night800)
    }

    private var experienceSection: some View {
        Section("Masal deneyimi") {
            Toggle(isOn: $autoplay) {
                Label("Masalı otomatik oynat", systemImage: "play.circle.fill")
            }
            Picker(selection: $sleepTimer) {
                Text("Kapalı").tag(0)
                Text("15 dakika").tag(15)
                Text("30 dakika").tag(30)
                Text("45 dakika").tag(45)
            } label: {
                Label("Uyku zamanlayıcısı", systemImage: "timer")
            }
            Toggle(isOn: notificationBinding) {
                Label("Masal hatırlatıcısı", systemImage: "bell.fill")
            }
        }
        .listRowBackground(MasalTheme.night800)
    }

    @ViewBuilder
    private var parentSection: some View {
        Section("Ebeveyn alanı") {
            if !isParentUnlocked {
                Button {
                    showsParentGate = true
                } label: {
                    Label("Ebeveyn alanını aç", systemImage: "lock.fill")
                }
            } else {
                if environment.profile?.accountKind == .anonymous {
                    SignInWithAppleButton(.continue) { request in
                        do {
                            appleNonce = try AppleSignInHelper.prepare(request)
                        } catch {
                            message = "Apple ile giriş hazırlanamadı. Lütfen yeniden deneyin."
                        }
                    } onCompletion: { result in
                        handleAppleResult(result)
                    }
                    .signInWithAppleButtonStyle(.whiteOutline)
                    .frame(height: 48)
                    .accessibilityLabel("Apple ile devam et")
                }

                Button {
                    showsPaywall = true
                } label: {
                    Label(
                        environment.profile?.premium == true ? "Premium etkin" : "Premium'u keşfet",
                        systemImage: "sparkles"
                    )
                }
                .disabled(environment.profile?.premium == true)

                Button(role: .destructive) {
                    showsDeleteConfirmation = true
                } label: {
                    Label("Hesabı sil", systemImage: "trash.fill")
                }
            }
        }
        .listRowBackground(MasalTheme.night800)
    }

    private var aboutSection: some View {
        Section("Hakkında") {
            Button { showsPrivacy = true } label: {
                Label("Gizlilik ve çocuk güvenliği", systemImage: "hand.raised.fill")
            }
            LabeledContent("Sürüm", value: "2.0")
        }
        .listRowBackground(MasalTheme.night800)
    }

    private var profileDetail: String {
        if environment.profile?.premium == true { return "Premium • Sınırsız masal" }
        return "\(environment.profile?.credits ?? 0) masal kredisi"
    }

    private var messageBinding: Binding<Bool> {
        Binding(get: { message != nil }, set: { if !$0 { message = nil } })
    }

    private var notificationBinding: Binding<Bool> {
        Binding(
            get: { notificationsEnabled },
            set: { enabled in
                notificationsEnabled = enabled
                Task {
                    if enabled {
                        await enableNotifications()
                    } else {
                        disableNotifications()
                    }
                }
            }
        )
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        guard let nonce = appleNonce else { return }
        appleNonce = nil
        switch result {
        case let .success(authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                message = "Apple kimliği okunamadı. Lütfen yeniden deneyin."
                return
            }
            Task {
                do {
                    try await environment.signInWithApple(
                        identityToken: identityToken,
                        rawNonce: nonce
                    )
                    message = "Hesabın Apple ile güvenle bağlandı."
                } catch {
                    message = (error as? LocalizedError)?.errorDescription
                        ?? "Apple ile giriş tamamlanamadı."
                }
            }
        case let .failure(error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                message = "Apple ile giriş tamamlanamadı. Lütfen yeniden deneyin."
            }
        }
    }

    private func enableNotifications() async {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound]
            )
            if !granted {
                notificationsEnabled = false
                message = "Hatırlatıcılar için bildirim izni verilmedi."
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Masal zamanı 🌙"
            content.body = "Birlikte sakin bir gece masalı seçmeye ne dersin?"
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: 20),
                repeats: true
            )
            let request = UNNotificationRequest(
                identifier: Self.reminderIdentifier,
                content: content,
                trigger: trigger
            )
            try await center.add(request)
        } catch {
            notificationsEnabled = false
            message = "Masal hatırlatıcısı şu anda ayarlanamadı."
        }
    }

    private func disableNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.reminderIdentifier])
    }

    private func refreshNotificationState() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let requests = await center.pendingNotificationRequests()
        let permissionGranted: Bool
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            permissionGranted = true
        case .notDetermined, .denied:
            permissionGranted = false
        @unknown default:
            permissionGranted = false
        }
        notificationsEnabled = permissionGranted && requests.contains {
            $0.identifier == Self.reminderIdentifier
        }
    }

    private func deleteAccount() async {
        do {
            try await environment.deleteAccount()
            isParentUnlocked = false
            message = "Hesabın ve kişisel verilerin silindi. Yeni bir misafir oturumu açıldı."
        } catch {
            message = (error as? LocalizedError)?.errorDescription
                ?? "Hesap şu anda silinemedi. Lütfen yeniden deneyin."
        }
    }
}

private struct ParentGateView: View {
    @Binding var isUnlocked: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var answer = ""

    var body: some View {
        ZStack {
            NightSkyBackground()
            VStack(spacing: 18) {
                Image(systemName: "figure.and.child.holdinghands")
                    .font(.system(size: 54))
                    .foregroundStyle(MasalTheme.apricot)
                Text("Ebeveyn Alanı")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(MasalTheme.cream)
                Text("Devam etmek için 7 + 5 işleminin sonucunu yaz.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MasalTheme.textSecondary)
                TextField("Sonuç", text: $answer)
                    .masalNumberPadKeyboard()
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 180)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Ebeveyn doğrulama sonucu")
                Button("Alanı Aç") {
                    guard answer.trimmingCharacters(in: .whitespaces) == "12" else { return }
                    isUnlocked = true
                    dismiss()
                }
                .buttonStyle(MasalPrimaryButtonStyle())
                .disabled(answer.trimmingCharacters(in: .whitespaces) != "12")
            }
            .padding(26)
        }
    }
}

private extension View {
    @ViewBuilder
    func masalNumberPadKeyboard() -> some View {
#if os(iOS)
        keyboardType(.numberPad)
#else
        self
#endif
    }
}
