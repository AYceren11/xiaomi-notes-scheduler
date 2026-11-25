# Xiaomi Notes & Gelişmiş Zamanlayıcı (Xiaomi Notes & Scheduler)

**BLM4587 iOS ile Mobil Uygulama Geliştirme I (Flutter) — Dönem Projesi**  
**Geliştirici / Proje Lideri:** Ayşe Ceren Şenel (23290973)  
**GitHub Deposu:** [AYceren11/xiaomi-notes-scheduler](https://github.com/AYceren11/xiaomi-notes-scheduler)

---

## 📌 Proje Genel Bakışı
Bu proje, Xiaomi ekosisteminin resmi **Xiaomi Notes (MIUI / HyperOS Notes)** uygulamasını tüm temel özellikleriyle (hızlı kenar çubuğu, zengin metin düzenleyici, zihin haritası, sesli not, çizim motoru ve biyometrik gizli kasa) Flutter altyapısında klonlayan; bu yapıyı **Yıllık, Aylık, Haftalık ve 24 Saatlik Dikey Zaman Matrisi (Scheduler)** ajanda sistemiyle birleştiren tam kapsamlı bir mobil üretkenlik platformudur.

Proje, ders kurallarına ve teknik isterlere tam uyumlu iki ana katmandan oluşur:
1. **`/api`**: ASP.NET Core Web API (.NET 9 / 8 uyumlu), Entity Framework Core ORM, PostgreSQL veritabanı + EF Core Migrations, JWT Authentication, Rol Bazlı Yetkilendirme (`Admin` & `User`), sunucu tarafı doğrulama (DataAnnotations) ve Swagger/OpenAPI.
2. **`/mobile`**: Flutter (Dart) ile **MVVM + Provider** mimarisinde geliştirilmiş, Xiaomi MIUI tasarımına sahip, `Dio` ile Web API'ye bağlanan, harici API'leri (**Nager.Date Public Holiday API** & **Open-Meteo Weather API**) entegre eden Android mobil uygulaması.

---

## 🏗️ Klasör Yapısı

```text
xiaomi-notes-scheduler/
├── api/                                # ASP.NET Core Web API (Backend)
│   ├── Controllers/                    # Auth, Notes, Tasks, Schedules, Categories, Users, Admin
│   ├── Data/                           # AppDbContext, DbInitializer, DesignTimeDbContextFactory
│   ├── DTOs/                           # DataAnnotations doğrulamalı Request / Response DTO'ları
│   ├── Migrations/                     # EF Core PostgreSQL Migrations (InitialCreate)
│   ├── Models/                         # User, Category, Note, TaskItem, Schedule, AuditLog
│   ├── Services/                       # AuditService (Denetim günlüğü)
│   ├── appsettings.json                # Gizli bilgi içermeyen şablon yapılandırma
│   └── Program.cs                      # DI, JWT, Swagger, CORS, StaticFiles ve Health Check
├── mobile/                             # Flutter Mobil Uygulaması (Frontend)
│   ├── lib/
│   │   ├── models/                     # UserItem, CategoryItem, Note, TaskItem, ScheduleItem, ExternalData
│   │   ├── screens/                    # Login, Main, Notes, NoteEditor (Quill), Drawing, MindMap,
│   │   │                               # Tasks, Scheduler, Vault (Biometric), Admin, Settings
│   │   ├── services/                   # ApiService (Dio), StorageService (SecureStorage),
│   │   │                               # ExternalApiService, NotificationService, BiometricService
│   │   ├── viewmodels/                 # AuthVM, NotesVM, TasksVM, SchedulerVM, AdminVM (Provider MVVM)
│   │   ├── theme/                      # Xiaomi MIUI renk ve tipografi teması (#FF6900)
│   │   ├── widgets/                    # MiuiSearchBar, MiuiFolderChips, NoteCard, QuickNotesSidebar
│   │   └── main.dart                   # MultiProvider, TR yerelleştirme ve başlangıç yönlendirmesi
│   └── pubspec.yaml                    # Bağımlılıklar
└── README.md                           # Kurulum ve çalıştırma kılavuzu
```

---

## 🗄️ Veritabanı Tabloları (6 İlişkisel Tablo)

| Tablo Adı | Önemli Sütunlar | İlişkiler |
| :--- | :--- | :--- |
| **Users** | `Id`, `FullName`, `Email`, `PasswordHash`, `Role`, `CreatedAt`, `IsActive` | `Categories` (1:N), `Notes` (1:N), `Tasks` (1:N), `Schedules` (1:N), `AuditLogs` (1:N) |
| **Categories** | `Id`, `UserId`, `Name`, `ColorCode`, `Icon`, `CreatedAt` | `Users` (N:1), `Notes` (1:N) |
| **Notes** | `Id`, `UserId`, `CategoryId`, `Title`, `ContentJson`, `MindMapData`, `AudioUrl`, `DrawingData`, `ColorHex`, `IsVault`, `IsPinned`, `CreatedAt`, `UpdatedAt` | `Users` (N:1), `Categories` (N:1), `Tasks` (1:N) |
| **Tasks** | `Id`, `UserId`, `NoteId`, `ParentId`, `Title`, `IsCompleted`, `Priority`, `OrderIndex`, `DueDate`, `CreatedAt`, `CompletedAt` | `Users` (N:1), `Notes` (N:1), `Schedules` (1:N) |
| **Schedules** | `Id`, `UserId`, `TaskId`, `Title`, `StartTime`, `EndTime`, `EventDate`, `ReminderMinutes`, `ColorCode` | `Users` (N:1), `Tasks` (N:1) |
| **AuditLogs** | `Id`, `UserId`, `Action`, `EntityName`, `RecordId`, `Timestamp`, `IpAddress` | `Users` (N:1) |

---

## 🚀 Kurulum ve Çalıştırma Adımları

### 1. Web API (Backend) Kurulumu

#### Gereksinimler
- [.NET 8.0 / 9.0 SDK](https://dotnet.microsoft.com/)
- [PostgreSQL 15+](https://www.postgresql.org/)

#### Gizli Bilgiler ve Veritabanı Yapılandırması
Güvenlik kuralları gereği veritabanı şifresi ve JWT gizli anahtarı `appsettings.json` içinde tutulmaz. Yerel geliştirme için `api/appsettings.Development.json` (`.gitignore` içinde) dosyası oluşturun veya ortam değişkenlerini ayarlayın:

```json
{
  "ConnectionStrings": {
    "PostgreSql": "Host=localhost;Port=5432;Database=xiaominotes_db;Username=postgres;Password=SIFRENIZ"
  },
  "Jwt": {
    "Key": "EnAz32KarakterlikGucluBirJwtGizliAnahtari2026!",
    "Issuer": "XiaomiNotesApi",
    "Audience": "XiaomiNotesClient"
  }
}
```

#### Migration ve Çalıştırma Komutları
```bash
cd api
dotnet restore

# PostgreSQL kullanıyorsanız EF Core Migration ile tabloları oluşturun:
dotnet ef database update

# API sunucusunu tüm yerel ağ arayüzlerinde (0.0.0.0:5186) başlatın:
dotnet run
```

- **Swagger UI:** `http://localhost:5186/swagger`
- **Sağlık Kontrolü:** `http://localhost:5186/api/health`

> Not: İlk açılışta `DbInitializer` otomatik olarak örnek kullanıcıları, klasörleri, zengin notları, zihin haritasını, gizli kasa notunu, görevleri, alt görevleri ve günlük zamanlayıcı planlarını ekler.

---

### 2. Flutter Mobil Uygulaması Kurulumu

#### Gereksinimler
- **Flutter SDK:** `>= 3.44.0` (Dart SDK `>= 3.13.4`)
- Android Studio / Android SDK (Min SDK 24) veya fiziksel Android cihaz

#### Adımlar
```bash
cd mobile
flutter pub get
flutter run
```

#### API Adresinin Ayarlanması
Uygulama içinden **yeniden derleme yapmadan** API adresi değiştirilebilir:
1. Giriş ekranının sağ üstündeki **API Ayarla** butonuna (veya giriş yaptıktan sonra **Ayarlar > Web API Bağlantı Adresi**) dokunun.
2. Kullanım senaryonuza göre adresi girin:
   - **Android Emülatörü:** `http://10.0.2.2:5186/api` (varsayılan)
   - **Fiziksel Android Telefon (Aynı Wi-Fi):** `http://<BILGISAYAR_IP>:5186/api` (örn. `http://192.168.1.117:5186/api`)
   - **Windows / Web:** `http://localhost:5186/api`
3. **Kaydet ve Test Et** butonuna basarak canlı bağlantıyı doğrulayın.

---

## 🔑 Varsayılan Hesaplar (Seed Data)

| Rol | E-posta | Şifre | Yetki |
| :--- | :--- | :--- | :--- |
| **Yönetici (Admin)** | `admin@xiaomi.com` | `Admin123!` | Tüm özellikler + **Yönetici Paneli** (İstatistikler, Kullanıcı CRUD, İçerik Moderasyonu, Audit Logs) |
| **Standart Kullanıcı** | `user@xiaomi.com` | `User123!` | Notlar, Zengin Editör, Ses/Çizim/Zihin Haritası, Görevler, 24s Zamanlayıcı, Biyometrik Kasa |

- **Gizli Kasa Yedek PIN:** `1234` (Parmak İzi / Face ID destekleyen telefonlarda öncelikle biyometrik doğrulama açılır).

---

## 📱 Uygulama Özellikleri Özeti
- **Xiaomi MIUI Arayüzü & Masonry Grid/Liste:** Canlı Xiaomi turuncusu (`#FF6900`), 2/3/4 sütun duyarlı Masonry grid ve liste görünümü, klasör (kategori) tam CRUD, canlı arama ve sabitleme.
- **Zengin Metin Editörü (`flutter_quill`):** Kalın, italik, altı çizili, başlıklar, listeler, kontrol kutuları, renkler ve Delta JSON senkronizasyonu.
- **Sesli Not (`record` & `audioplayers`):** Not içinde ses kaydı alma, sunucuya yükleme (`/api/notes/upload-audio`) ve oynatma.
- **Çizim Motoru (`CustomPainter`):** Fırça renkleri, kalınlık ayarı, silgi, geri alma ve not içine kaydetme.
- **Zihin Haritası (Mind Map):** Etkileşimli yakınlaştırılabilir düğüm ağacı, alt dal ekleme, renklendirme, daraltma/genişletme.
- **Görevler & Checklist (`ReorderableListView`):** Sürükle-bırak sıralama (`PATCH /api/tasks/reorder`), öncelik rozetleri ve filtreleme, alt görevler, son tarih seçici ve zamanlayıcıya tek tıkla atama.
- **Yıllık / Aylık / Haftalık / 24 Saatlik Zamanlayıcı (`table_calendar`):** Görevleri saat bloklarına sürükleyip bırakma (`Draggable` / `DragTarget`), **Nager.Date** Türkiye resmî tatilleri, **Open-Meteo** canlı hava durumu ve **yerel bildirim alarmları** (`flutter_local_notifications`).
- **Biyometrik Gizli Kasa (`local_auth`):** Parmak izi / Yüz tanıma ve şifreli PIN korumalı özel not kasası.
- **Xiaomi Hızlı Kenar Çubuğu:** Sol kenardaki turuncu tutamacı kaydırarak/dokunarak her ekrandan anında not veya görev ekleme.
- **Yalnızca Yöneticiye Açık Admin Paneli:** JWT `[Authorize(Roles = "Admin")]` korumalı sistem metrikleri, kullanıcı yönetimi (ekleme, rol değiştirme, aktif/pasif yapma, silme), tüm notların moderasyonu ve denetim günlüğü (Audit Logs).
