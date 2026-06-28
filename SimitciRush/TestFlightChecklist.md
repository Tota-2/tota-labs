# Simitci TestFlight Checklist

## Release Ayarları

- Display Name: Simitçi
- Bundle ID: com.totalabs.simitcirush
- Version: 1.0
- Build: 1
- Category: Games
- iPhone/iPad portrait destekli
- App icon seti mevcut
- PrivacyInfo.xcprivacy mevcut
- iCloud KVS entitlement mevcut
- Game Center entitlement mevcut

## App Store Connect

- Game Center leaderboards:
  - com.totalabs.simitcirush.reputation
  - com.totalabs.simitcirush.cash
  - com.totalabs.simitcirush.bestday
  - com.totalabs.simitcirush.days
- Achievements:
  - com.totalabs.simitcirush.achievement.debtfree7
  - com.totalabs.simitcirush.achievement.simit100
  - com.totalabs.simitcirush.achievement.combo5
  - com.totalabs.simitcirush.achievement.istanbulsimitcisi
- App Privacy formu UserDefaults, iCloud KVS, Game Center kullanımına göre doldurulacak.

## Gerçek Cihaz Smoke Test

1. Yeni oyun başlat.
2. İlk öğretici akışını geç.
3. Marketten simit, çay, poşet al.
4. `+5` tedarik butonlarına hızlı bas; donma olmamalı.
5. Hazırlık ekranında fiyat ve stokları kontrol et.
6. Ana servisi başlat.
7. Doğru servis, yanlış servis, stok yok ve soru cevabı akışlarını dene.
8. Servis raporunu aç.
9. Gün kapanışına geç.
10. Yeni güne hazırlan.
11. Özel Dükkân desteklerinden birini kullan.
12. Game Center oturumunu ve sıralama açılışını kontrol et.
13. Bildirim izni isteğini ve ayarlardaki hatırlatma kontrolünü dene.
14. Uygulamayı kapatıp aç; iCloud/local kayıt geri gelmeli.

## Kabul Kriteri

- Debug ve Release generic iOS build başarılı.
- Yeni oyun ve gün döngüsü takılmadan tamamlanıyor.
- Market tedarik spam donma yaratmıyor.
- Game Center oturumu otomatik tetikleniyor.
- Bildirim izni verilirse hatırlatma ayarı bozulmuyor.
- Oyun dışı dosyalar commit'e girmiyor.
