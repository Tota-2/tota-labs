# Simitci - Prototype Spec v0.1

## Objective

Ilk playable prototype'in amaci oyunun en kritik sorusunu cevaplamak:

> 60 saniyelik simit rush akisi elde iyi hissettiriyor mu?

Bu asamada tam ekonomi, tum semtler, IAP veya uzun progression yok. Once temel oyun hissi:

- musteri akisi
- siparis hazirlama
- stok azalmasi
- dogru/yanlis servis
- hiz/combo
- basit gun sonu raporu

## Platform Direction

- iOS + iPadOS
- SwiftUI app shell
- Rush ekrani SwiftUI ile baslayabilir; eger animasyon/fizik agirlasirsa SpriteKit'e tasinir
- Portrait-first iPhone
- iPad'de daha genis layout, ama MVP iPhone portrait'e gore tasarlanir

## Screen Map

### 1. Home / Cart Screen

Oyuncunun gun basina dondugu ana ekran.

Gosterilecekler:

- tezgah seviyesi
- cash
- XP / level
- bugunku semt
- bugunku market olayi
- "Start Rush" butonu
- "Market" butonu
- "Upgrades" butonu

Prototype icin:

- tek semt: Vapur Iskelesi
- tek CTA: Start Rush

### 2. Prep Screen

Rush oncesi hazirlik.

Gosterilecekler:

- stok adetleri
- urun satis fiyatlari
- gunluk kira/yer masrafi
- beklenen musteri profili

Prototype icin minimal:

- simit stok: 20
- cay stok: 12
- peynir stok: 8
- cikolata stok: 6
- poset stok: 10
- Start butonu

### 3. Rush Screen

Ana oynanis ekrani.

Layout:

```text
Top HUD
  timer | cash earned | happiness | combo

Customer Area
  queue avatars
  active customer card
  patience bar
  order bubble
  optional dialogue question

Cart Area
  current tray / selected items
  stock chips

Action Tray
  Simit | Cay | Peynir | Cikolata | Poset
  Clear | Serve
```

Prototype davranisi:

- 60 saniye timer
- aktif musteri siparisi gosterir
- oyuncu urun butonlarina basarak tepsiye ekler
- Serve dogruysa musteri gider, kuyruk kayar
- Serve yanlissa memnuniyet duser
- stok yoksa buton disabled olur

### 4. Day Report Screen

Rush bitince rapor.

Gosterilecekler:

- gross revenue
- costs
- net profit
- served customers
- missed customers
- wrong orders
- happiness
- combo best
- XP earned

Prototype icin:

- revenue
- served
- missed/wrong
- happiness
- score
- Continue butonu

### 5. Market Screen

Gun sonu eksik tamamlama.

Prototype icin henuz interaktif olmayabilir. Bir sonraki slice'ta eklenecek.

### 6. Upgrades Screen

Tezgah buyutme.

Prototype icin henuz interaktif olmayabilir. Bir sonraki slice'ta eklenecek.

## Rush Gameplay Rules

### Timer

- Prototype rush suresi: 60 saniye
- Ilk hedef: 20-30 musteri arasi akisi test etmek

### Customer Queue

- Ekranda 1 aktif musteri + 3 kuyruk musteri
- Aktif musteri tamamlaninca:
  - served veya failed olarak kaydedilir
  - kuyruk one kayar
  - arkaya yeni musteri uretilir

### Patience

Her musteri patience ile gelir.

```text
student: 5s
officeWorker: 4s
tourist: 7s
taxiDriver: 6s
elder: 8s
rushedCustomer: 3s
```

Patience biterse:

- musteri gider
- missedCustomers +1
- happiness -3
- combo reset

### Orders

Order, required item listesi olarak tutulur.

Ornekler:

```text
[simit]
[simit, tea]
[simit, cheese]
[simit, chocolate]
[simit, tea, bag]
```

Siparis dogrulama:

- selectedItems exactly matches requiredItems ise dogru
- fazla/eksik/yanlis item varsa yanlis

### Product Buttons

Butona basinca:

- stok 0 ise secilemez
- item selected tray'e eklenir
- ayni item birden fazla gerekmedikce tekrar basmak engellenir

Clear:

- secili tepsiyi sifirlar

Serve:

- dogrulama yapar
- dogruysa stoklar dusulur
- yanlissa stoklar dusmez, ama zaman ve memnuniyet kaybi olur

Not: Final oyunda yanlis servis bazen stok fire yazabilir. Prototype'da basit kalacak.

### Combos

Combo dogru ve hizli servisle artar.

Prototype:

- arka arkaya dogru servis combo +1
- yanlis/missed combo reset
- combo revenue multiplier:
  - 0-2: x1.0
  - 3-5: x1.1
  - 6+: x1.2

### Dialogue

Prototype'da dialogue nadir ve hafif olacak.

- her 4-5 musteriden biri soru sorar
- cevap secimi zorunlu degil; auto-skip timer olabilir
- cevap etkisi ufak:
  - tip chance
  - patience +/-
  - combo chance

Prototype icin sadece 3 dialogue:

```text
Abi sicak mi?
  - Firindan yeni cikti.        trust +, tip +
  - Sicak sayilir abi.          no effect
  - Cayla daha iyi gider.       combo bonus if tea included

Peynir taze mi?
  - Sabah geldi.                trust +
  - Denemek ister misin?        upsell cheese
  - Bitmeden al derim.          risk, impatience +

Ogrenci indirimi var mi?
  - Bugun senden az alalim.     revenue -, happiness +
  - Cay eklersen indirim yaparim. combo chance +
  - Maalesef yok.               happiness -
```

## Data Model Draft

### ProductID

```swift
enum ProductID: String, Codable, CaseIterable {
    case simit
    case tea
    case cheese
    case chocolate
    case bag
}
```

### ProductDefinition

```swift
struct ProductDefinition: Identifiable, Codable {
    let id: ProductID
    let name: String
    let iconName: String
    let buyCost: Int
    let sellPrice: Int
    let prepWeight: Double
}
```

### StockState

```swift
struct StockState: Codable {
    var quantities: [ProductID: Int]
}
```

### CustomerType

```swift
enum CustomerType: String, Codable, CaseIterable {
    case student
    case officeWorker
    case tourist
    case taxiDriver
    case elder
    case rushed
}
```

### Customer

```swift
struct Customer: Identifiable, Codable {
    let id: UUID
    let type: CustomerType
    let order: [ProductID]
    let patienceSeconds: Double
    let baseTipChance: Double
    let dialogue: DialoguePrompt?
}
```

### DialoguePrompt

```swift
struct DialoguePrompt: Identifiable, Codable {
    let id: String
    let line: String
    let responses: [DialogueResponse]
}

struct DialogueResponse: Identifiable, Codable {
    let id: String
    let text: String
    let effect: DialogueEffect
}
```

### RushState

```swift
struct RushState {
    var timeRemaining: Double
    var activeCustomer: Customer
    var queue: [Customer]
    var selectedItems: [ProductID]
    var stock: StockState
    var earnedCash: Int
    var servedCount: Int
    var missedCount: Int
    var wrongCount: Int
    var happiness: Int
    var combo: Int
    var bestCombo: Int
}
```

## First Prototype Constants

### Starting Stock

```text
simit: 20
tea: 12
cheese: 8
chocolate: 6
bag: 10
```

### Sell Prices

```text
simit: 20
tea: 12
cheese: 10
chocolate: 14
bag: 2
```

### Order Weights

```text
[simit]                  35%
[simit, tea]             25%
[simit, cheese]          15%
[simit, chocolate]       10%
[simit, tea, bag]        10%
[simit, cheese, tea]      5%
```

### Customer Mix - Vapur Iskelesi

```text
officeWorker: 30%
taxiDriver: 20%
student: 15%
tourist: 15%
elder: 10%
rushed: 10%
```

## UI Component List

Reusable components:

- `TopHUDView`
- `CustomerQueueView`
- `CustomerCardView`
- `PatienceBarView`
- `OrderBubbleView`
- `DialogueChoiceView`
- `StockChipView`
- `ProductButton`
- `SelectedTrayView`
- `ServeButton`
- `DayReportCard`
- `PrimaryButton`
- `CurrencyBadge`

## Visual Prototype Direction

Do not rely on final AI art.

Use:

- vector/cutout customer avatars
- simple rounded UI cards
- warm amber/cream palette
- teal accent for active states
- tactile product buttons
- subtle shadows
- simple cart illustration
- minimal animated background

Prototype can start with SF Symbols / simple shape icons:

- simit: custom ring shape
- tea: cup icon
- cheese: wedge shape
- chocolate: bar shape
- bag: bag icon

## Technical Milestones

### Milestone 1 - Static Rush UI

- Build Rush screen layout
- Show one active customer
- Show queue
- Show product buttons
- Show top HUD

### Milestone 2 - Customer Flow

- Generate customers
- Serve correct/incorrect orders
- Queue advances
- Timer runs
- Patience decreases

### Milestone 3 - Scoring

- Cash earned
- Happiness
- Combo
- Missed/wrong tracking
- Day report

### Milestone 4 - Prep + Report Loop

- Start from Prep screen
- Play Rush
- End on Report
- Restart day

### Milestone 5 - Economy Slice

- Add market buying
- Add price setting
- Add day costs

## What Not To Build Yet

- Full Istanbul map
- StoreKit / IAP
- Game Center
- Complex inflation
- Deep branching dialogue
- Many districts
- Many products
- Final art
- Server/backend

## Success Criteria

Prototype is worth continuing if:

- serving customers feels fast and readable
- player understands wrong vs right instantly
- queue pressure creates tension
- 60-second run makes player want retry
- stock running out creates meaningful panic
- day report makes player want upgrade/economy layer

If the rush loop is not fun, economy/progression will not save the game.
