# Simitci - Game Plan v0.1

## One-Line Pitch

Istanbul'da küçük bir simit tezgahıyla başlayıp semt semt büyüdüğün, hızlı servis, stok, fiyat, müşteri davranışı ve günlük rekabet üstüne kurulu mobile-first işletme oyunu.

## Product Goal

Oyuncu her gün kısa süreliğine geri dönmek istemeli:

- Bugünün semti ve müşteri akışı ne?
- Market fiyatları değişti mi?
- Stoklarım yeter mi?
- Zam yaparsam müşteri kaçar mı?
- Günlük leaderboard'da kaçıncı olurum?
- Yeni tezgah parçasını açabilecek miyim?

Oyun PC simülasyonu gibi ağır değil; dikey ekran, tek elle, 2-5 dakikalık session'lar için tasarlanır.

## Core Loop

```text
Sabah Hazırlık
  -> stok al
  -> fiyatları ayarla
  -> semt seç
  -> günlük hedefi gör

Rush Satış
  -> müşteri kuyruğu akar
  -> siparişi hızlı hazırla
  -> kısa diyalog cevabı seç
  -> doğru servis + combo + bahşiş

Gün Sonu
  -> ciro, kar, masraf, memnuniyet, fire
  -> XP, reputation, leaderboard skoru

Market / Upgrade
  -> eksikleri al
  -> tezgahı büyüt
  -> yeni ürün/semt aç
```

## Moment-to-Moment Gameplay

Bir "rush" 60-120 saniye sürer.

Ekranda:

- Aktif müşteri
- Arkada 2-4 kişilik kuyruk
- Müşteri sabır barı
- Sipariş balonu
- Ürün butonları
- Hızlı cevap seçenekleri
- Serve butonu
- Stok göstergeleri
- Combo/streak göstergesi

Akış:

1. Müşteri tezgaha gelir.
2. Sipariş ve bazen kısa replik verir.
3. Oyuncu ürünleri seçer.
4. Gerekirse 2-3 cevap seçeneğinden birini seçer.
5. Serve'a basar.
6. Doğru servis para, XP, memnuniyet ve combo verir.
7. Yanlış/geç servis müşteri kaybettirir.
8. Kuyruk öne kayar, yeni müşteri arkadan gelir.

Oyun durmaz; tempo oyunun ana eğlencesidir.

## Products

### Launch Products

- Sade simit
- Çay
- Peynir
- Çikolata
- Poşet

### Future Products

- Kaşarlı simit
- Zeytin ezmesi
- Ayran
- Kahve
- Poğaça
- Açma
- Premium gevrek
- Seasonal/festival ürünleri

### Product Stats

Her ürün data-driven olmalı:

```text
id
displayName
buyCost
baseSellPrice
prepTime
stockUnit
spoilageRisk
customerDemandTags
comboTags
unlockRequirement
```

## Economy

### Currencies

- Cash: işletme parası
- XP: oyuncu seviyesi
- Reputation: semt itibarı
- Premium currency: kozmetik, kolaylaştırıcı paketler, market refresh

### Income

- Ürün satışı
- Combo bonus
- Bahşiş
- Daily challenge ödülü
- Semt hedefi ödülü

### Costs

- Simit/fırın stoğu
- Çay, peynir, çikolata, poşet
- Günlük kira / tezgah yeri
- Semt izin ücreti
- Ekipman bakımı
- Fire / bozulma

### Pricing

Oyuncu ürün fiyatlarını ayarlayabilir.

Fiyat artışı:

- kar marjını artırır
- bazı semtlerde müşteri sayısını azaltır
- memnuniyeti düşürebilir
- lüks semtlerde daha tolere edilir

Fiyat düşüşü:

- hacmi artırır
- combo şansını artırır
- kar marjını düşürür

### Inflation / Market Events

Basit ve okunabilir olmalı.

Örnek event'ler:

- "Un fiyatı arttı": simit alış fiyatı yükselir.
- "Peynir tedarik sıkıntısı": peynir pahalı ve sınırlı olur.
- "Yağmurlu sabah": müşteri sayısı düşer, çay talebi artar.
- "Maç günü": stadyumda yoğunluk ve fiyat toleransı artar.
- "Okul açıldı": öğrenci yoğunluğu artar, fiyat hassasiyeti artar.

## District System

İstanbul haritası progression ekranı olur. Semtler kolaydan zora, ucuzdan lükse açılır.

### Example Districts

1. Mahalle Arası
2. Okul Önü
3. Vapur İskelesi
4. Kadıköy
5. Eminönü
6. Beşiktaş
7. Üsküdar
8. Karaköy
9. Levent
10. Nişantaşı
11. Bebek
12. Festival Alanı

### District Stats

```text
traffic
rent
priceTolerance
patienceAverage
tipChance
preferredProducts
customerMix
reputationRequired
cashUnlockCost
specialEvents
```

### District Examples

Mahalle Arası:

- düşük kira
- fiyat hassas
- müşteri sabrı yüksek
- düşük bahşiş

Vapur İskelesi:

- yüksek sabah trafiği
- çay + simit combo güçlü
- sabır düşük
- rush temposu yüksek

Nişantaşı:

- yüksek kira
- fiyat toleransı yüksek
- kalite beklentisi yüksek
- premium ürünler iyi satar

## Customer System

Müşteri tipleri semte göre karışır.

### Launch Customer Types

- Öğrenci
- Plaza çalışanı
- Turist
- Taksici
- Teyze/amca
- Aceleci müşteri

### Future Customer Types

- Zabıta
- Sporcu
- Çocuk
- Influencer
- Festival müşterisi
- Sadık müşteri

### Customer Stats

```text
type
patience
budget
priceSensitivity
tipChance
dialogueChance
preferredProducts
comboPreference
reputationImpact
```

## Dialogue System

Diyaloglar kısa kalmalı. Ama oyuna karakter ve karar etkisi verir.

Her diyalogda genelde 2-3 cevap olur:

- Dürüst cevap: güven/reputation artırır.
- Satış cevabı: combo/kar ihtimalini artırır.
- Riskli cevap: yüksek ödül veya müşteri kaybı riski.

Örnek:

```text
Müşteri: Abi sıcak mı bunlar?

1. Fırından yeni çıktı.      -> güven +, tip chance +
2. Sıcak sayılır abi.        -> nötr, hızlı
3. Çayla efsane olur.        -> combo chance +
```

Dialogue data-driven olmalı:

```text
speakerType
districtTags
trigger
line
responses[]
effects[]
```

## Market / Supply

Gün sonunda oyuncu market/fırın ekranına girer.

Satın alınabilecekler:

- günlük simit stoğu
- çay
- peynir
- çikolata
- poşet
- özel kampanya ürünü
- ekipman bakım kiti

Market her gün değişebilir:

- fiyatlar
- stok limitleri
- indirimler
- rare ürünler
- premium teklifler

## Cart / Stand Progression

Tezgah büyütme oyunun ana uzun vadeli motivasyonlarından biri.

### Upgrade Path

1. Küçük seyyar tabla
2. Büyük simit sepeti
3. Çay termosu
4. Sıcak tutucu bölme
5. Peynir/çikolata sürme alanı
6. Hızlı paketleme rafı
7. Işıklı tabela
8. POS / QR ödeme
9. Mini vitrin
10. Büyük simit arabası
11. Premium food cart

Her upgrade oynanışı etkilemeli:

- stok kapasitesi
- servis hızı
- yeni ürün slotu
- müşteri çekme
- fiyat toleransı
- fire azaltma

## Competition

### Daily Rush

Her gün herkes aynı seed ile aynı semt/senaryoyu oynar.

Kurallar:

- aynı başlangıç stoğu
- aynı müşteri akışı
- aynı market event'i
- 3 ranked attempt

Skor:

```text
profit
+ speedBonus
+ happinessBonus
+ comboBonus
+ reputationBonus
- wastePenalty
- wrongOrderPenalty
```

### Weekly League

- Bronze
- Silver
- Gold
- Diamond
- Master Cart

Oyuncu günlük skorlarıyla haftalık ligde yükselir.

### Fairness

Daily ranked mode'da satın alınan gameplay avantajları kapatılmalı veya eşitlenmeli. Kozmetik ve normal progression satılabilir; rekabet bozulmamalı.

## Monetization

### Safe Monetization

- Starter pack
- Cosmetic cart skins
- Outfit/apron skins
- Premium signs
- Seasonal decorations
- No ads
- Season pass
- Premium district/event pack
- Market refresh token

### Risky Monetization

- Direkt para sıkışınca "öde yoksa kaybet" hissi
- Leaderboard avantajı
- Çok agresif stok paketi

Bunlar dikkatli kullanılmalı.

### Emergency Pack

Oyuncu batmak üzereyse "acil destek" paketi sunulabilir:

- simit stoğu
- çay
- peynir/çikolata
- küçük cash

Ama bu sürekli dayatılmamalı.

## Visual Direction

Artist olmadan yapılabilir direction:

- portrait mobile
- stylized vector/cutout
- sıcak İstanbul sabahı
- sade background
- modüler müşteri avatarları
- ürün ikonları net
- tezgah upgrade'leri görsel olarak belirgin
- premium ama çocukça olmayan UI

Müşteriler parça bazlı üretilebilir:

- kafa şekli
- saç
- gözlük
- kıyafet rengi
- aksesuar
- yüz ifadesi

Bu, az asset ile çok müşteri varyasyonu sağlar.

## Technical Direction

Native iOS/iPadOS.

- SwiftUI: menüler, market, harita, upgrade, rapor, store
- SpriteKit veya SwiftUI animation: rush satış ekranı
- StoreKit 2: IAP
- Game Center: leaderboard
- Codable save system
- Remote config ileride daily events için düşünülebilir

Başta server şart değil. Daily seed local tarih + config ile çalışabilir. Global leaderboard için Game Center yeter.

## MVP Scope

MVP fazla büyümemeli.

### MVP Content

- 3 semt
- 5 ürün
- 6 müşteri tipi
- 60 saniyelik rush
- kuyruk sistemi
- ürün seçme + serve
- 2-3 cevaplı mini dialogue
- gün sonu raporu
- market
- fiyat ayarlama
- basit fiyat dalgalanması
- 5 tezgah upgrade'i
- local daily score

### MVP Districts

1. Mahalle Arası
2. Okul Önü
3. Vapur İskelesi

### MVP Products

1. Simit
2. Çay
3. Peynir
4. Çikolata
5. Poşet

## Roadmap

### Phase 0 - Design Lock

- game name options
- visual direction
- economy formulas
- first customer types
- first district stats
- first UI screen map

### Phase 1 - Playable Prototype

- rush screen
- active customer + queue
- product buttons
- serve validation
- simple scoring
- 3 customer types

### Phase 2 - Economy Slice

- day start preparation
- stock buying
- product pricing
- day-end report
- basic rent/cost/profit

### Phase 3 - Progression Slice

- district map
- reputation
- XP
- first cart upgrades
- unlock rules

### Phase 4 - Competitive Slice

- daily rush seed
- local leaderboard
- Game Center leaderboard
- weekly league mock

### Phase 5 - Monetization-Ready

- StoreKit 2
- starter pack
- cosmetic cart skin
- no ads / supporter pack
- entitlement system

### Phase 6 - TestFlight

- polished onboarding
- first-time user flow
- analytics/crash
- App Store screenshots
- privacy labels

## Main Risks

1. Economy too complex for mobile.
2. First session not fun fast enough.
3. Visuals look cheap.
4. Pay-to-win perception.
5. Turkish cultural theme feels too niche globally.

## Risk Controls

- Keep rush gameplay simple.
- Introduce economy gradually.
- Daily ranked uses equalized rules.
- Use global-friendly name and Turkish flavor inside.
- Build one excellent vertical slice before expanding.

## Current Best Name Options

- Simitci Rush
- Street Cart Rush
- Golden Ring Rush
- Istanbul Cart
- Cart & Tea
- Simit Tycoon

Working title for now: **Simitci Rush**.
