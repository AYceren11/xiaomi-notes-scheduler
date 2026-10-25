# Xiaomi Notes & Gelişmiş Zamanlayıcı (Xiaomi Notes & Scheduler)

**BLM4587 iOS ile Mobil Uygulama Geliştirme I (Flutter) — Dönem Projesi**  
**Geliştirici / Proje Lideri:** Ayşe Ceren Şenel (23290973)  
**GitHub Deposu:** [AYceren11/xiaomi-notes-scheduler](https://github.com/AYceren11/xiaomi-notes-scheduler)

---

## 📌 Proje Genel Bakışı
Bu proje, Xiaomi ekosisteminin resmi **Xiaomi Notes (MIUI / HyperOS Notes)** uygulamasının zengin metin düzenleme, hızlı kenar çubuğu, görevler ve şifreli kasa özelliklerini Flutter altyapısında klonlayan; bu yapıyı 24 saatlik dikey zaman matrisine sahip gelişmiş bir ajanda/scheduler sistemi ile birleştiren kurumsal bir mobil verimlilik platformudur.

Proje, ders kurallarına ve teknik isterlere tam uyumlu olarak iki ana katmandan oluşur:
1. **/api**: ASP.NET Core 8/9 Web API, Entity Framework Core ORM, PostgreSQL veritabanı, JWT Authentication & Role-based Authorization (Admin & User rolleri) ve Swagger/OpenAPI arayüzü.
2. **/mobile**: Flutter (Dart) ile geliştirilmiş, MIUI temasını ve kullanıcı deneyimini yansıtan, REST API ile haberleşen modern mobil uygulama.

---

## 🏗️ Proje Mimarisi ve Klasör Yapısı

```
xiaomi-notes-scheduler/
├── api/                             # ASP.NET Core Web API (Backend)
│   ├── Controllers/                 # REST Controller sınıfları (Notes, Tasks, Auth, Admin, Categories)
│   ├── Data/                        # AppDbContext ve DbInitializer (Seed Data)
│   ├── DTOs/                        # Request / Response veri transfer nesneleri
│   ├── Models/                      # EF Core ilişkisel varlık modelleri (User, Category, Note, Task, Schedule, AuditLog)
│   ├── appsettings.json             # Yapılandırma ve bağlantı dizeleri
│   └── Program.cs                   # Middleware, Swagger, JWT ve Dependency Injection yapılandırması
├── mobile/                          # Flutter Mobil Uygulaması (Frontend)
│   ├── lib/
│   │   ├── models/                  # Dart veri modelleri
│   │   ├── screens/                 # Uygulama ekranları (Notlar, Editör, Görevler, Zamanlayıcı, Yönetici, Giriş)
│   │   ├── services/                # Dio tabanlı REST API istemcisi (ApiService)
│   │   ├── theme/                   # Xiaomi MIUI renk ve tipografi teması
│   │   ├── widgets/                 # Özel UI bileşenleri (Arama çubuğu, klasör çipleri, not kartları)
│   │   └── main.dart                # Uygulama başlangıç noktası
└── README.md                        # Kurulum ve çalıştırma kılavuzu
```

---

## 🚀 Kurulum ve Çalıştırma Adımları

### 1. Web API (Backend) Kurulumu

#### Gereksinimler:
- [.NET 8.0 veya .NET 9.0 SDK](https://dotnet.microsoft.com/)
- [PostgreSQL](https://www.postgresql.org/) (veya yerel test için dahili SQLite fallback)

#### Adımlar:
1. Terminalde `/api` klasörüne geçiş yapın:
   ```bash
   cd api
   ```
2. Bağımlılıkları geri yükleyin:
   ```bash
   dotnet restore
   ```
3. PostgreSQL veritabanını kullanmak için `appsettings.json` dosyasındaki bağlantı dizesini düzenleyin ve `"UsePostgres": true` yapın:
   ```json
   "ConnectionStrings": {
     "PostgreSql": "Host=localhost;Port=5432;Database=xiaominotes_db;Username=postgres;Password=YOUR_PASSWORD"
   },
   "UsePostgres": true
   ```
4. Veritabanını oluşturun ve migration adımlarını uygulayın:
   ```bash
   dotnet ef database update
   ```
   *(Not: Uygulama ilk başlatıldığında `DbInitializer` otomatik olarak tabloları ve örnek başlangıç verilerini oluşturur).*
5. API servisini başlatın:
   ```bash
   dotnet run
   ```
6. Swagger arayüzüne tarayıcınızdan erişin:
   ```
   http://localhost:5000/swagger
   ```

---

### 2. Flutter Mobil Uygulamasının Kurulumu

#### Gereksinimler:
- Flutter SDK (v3.27+ veya v3.47+)
- Dart SDK (v3.13+)
- Android Studio / VS Code ve Android Emülatörü (veya fiziksel Android cihaz)

#### Adımlar:
1. Terminalde `/mobile` klasörüne geçiş yapın:
   ```bash
   cd mobile
   ```
2. Gerekli paketleri indirin:
   ```bash
   flutter pub get
   ```
3. API Adresinin Yapılandırılması:
   - `lib/services/api_service.dart` dosyasında `baseUrl` tanımlanmıştır:
     - **Android Emülatörü:** `http://10.0.2.2:5000/api` (Emülatörün bilgisayarınızdaki `localhost`a erişmesi için zorunlu Android adresi).
     - **Windows / Web / Fiziksel Cihaz:** `http://localhost:5000/api` veya bilgisayarınızın yerel IP adresi (örn. `http://192.168.1.XX:5000/api`).
4. Mobil uygulamayı başlatın:
   ```bash
   flutter run
   ```

---

## 🔑 Varsayılan Kullanıcı Hesapları (Seed Data)

| Rol | E-posta | Şifre | Erişim Yetkisi |
| :--- | :--- | :--- | :--- |
| **Yönetici (Admin)** | `admin@xiaomi.com` | `Admin123!` | Tüm notlar/görevler + **Yönetici Paneli (İstatistikler, Denetim Günlüğü, Kullanıcı Yönetimi)** |
| **Standart Kullanıcı** | `user@xiaomi.com` | `User123!` | Notlar, Görevler, 24 Saatlik Zamanlayıcı, Kasa |

---

## 📱 Temel Özellikler
- **Xiaomi MIUI Arayüzü:** Canlı Xiaomi turuncusu (`#FF6900`), yumuşak not renk paletleri ve kart tasarımı.
- **Zengin Notlar & Klasörler:** Kategoriye göre filtreleme, başlık/içerik arama, iğneleme (pin), gizli kasa kilidi.
- **Görevler & Checklist:** Tamamlama durumu, öncelik rozetleri (Yüksek/Orta/Düşük), hiyerarşik alt görevler.
- **24 Saatlik Zamanlayıcı (Scheduler):** Günlük zaman matrisine görev/etkinlik atama.
- **Admin Dashboard:** Sistem logları ve canlı metrikler.
