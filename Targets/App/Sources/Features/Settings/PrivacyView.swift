import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                NightSkyBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        privacySection(
                            title: "Çocuk güvenliği",
                            text: "Masalcı, çocukların kişisel bilgilerini masal fikrine yazmamasını ister. İsim, okul, adres ve telefon bilgisi paylaşılmamalıdır."
                        )
                        privacySection(
                            title: "Masal üretimi",
                            text: "Yazılan fikir, yaşa uygun Türkçe masal, görsel ve ses hazırlamak için güvenli sunucuya gönderilir. İçerik güvenlik kontrolünden geçer."
                        )
                        privacySection(
                            title: "Hesap ve silme",
                            text: "Misafir oturumu cihazda güvenli biçimde saklanır. Ebeveyn alanından hesap silindiğinde favoriler, oluşturulan masallar ve oturum bilgileri kaldırılır."
                        )
                        privacySection(
                            title: "Satın alma",
                            text: "Premium satın alımları Apple tarafından işlenir. Satın alma geçmişi geri yüklenebilir; ödeme bilgileri Masalcı sunucusunda tutulmaz."
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Gizlilik")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Bitti") { dismiss() }
                }
            }
        }
    }

    private func privacySection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(MasalTheme.cream)
            Text(text)
                .foregroundStyle(MasalTheme.textSecondary)
                .lineSpacing(5)
        }
        .padding(18)
        .masalCard()
    }
}
