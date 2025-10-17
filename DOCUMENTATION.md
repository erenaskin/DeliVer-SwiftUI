# DeliVer-SwiftUI Kapsamlı Proje Dokümantasyonu

Bu doküman, **DeliVer-SwiftUI** projesinin mimarisini,-   **`Repository/*`**: `APIService`'i kullanarak belirli veri türleri için mantıksal gruplama sağlar. Örneğin, `AuthRepository` sadece kimlik doğrulama ile ilgili API çağrılarını içerir. Bu, ViewModel'ların doğrudan `APIService`'e bağımlı olmasını engeller.
    -   `AuthRepository.swift`: Giriş, kayıt gibi kimlik doğrulama isteklerini yönetir.
    -   `ProductRepository.swift`: Ürünlerle ilgili verileri çeker.
    -   `CategoryRepository.swift`: Kategori verilerini çeker.
    -   **`OrderRepository.swift`**: Sipariş API'si için tüm endpoint'leri içerir (oluşturma, listeleme, detay getirme, iptal etme). Modern async/await yapısını kullanır ve hata yönetimi sağlar.
    -   `CartRepository.swift`: Sepet işlemleri için API çağrılarını yönetir.kod yapısını, program akışını ve her bir dosyanın görevini detaylı bir şekilde açıklamaktadır. Amacı, projenin tam bir resmini sunarak geliştirme ve bakım süreçlerini kolaylaştırmaktır.

---

## 1. Genel Bakış ve Mimari

Proje, modern SwiftUI prensipleriyle geliştirilmiş olup, **MVVM (Model-View-ViewModel)** mimari desenini temel almaktadır. Bu mimari, UI (`View`), iş mantığı (`ViewModel`) ve veri (`Model`) katmanlarını birbirinden ayırarak modüler, test edilebilir ve yönetilebilir bir kod tabanı sağlar.

### Temel Mimari Katmanları:

1.  **`App` (Uygulama Katmanı):** Uygulamanın giriş noktası ve ana yapılandırması.
2.  **`Core` (Çekirdek Katman):** Projenin tamamında paylaşılan, yeniden kullanılabilir bileşenler (UI Components), servisler (Networking) ve yardımcı araçlar.
3.  **`Features` (Özellik Katmanı):** Uygulamanın ana işlevlerini barındıran modüller (örn: `Auth`, `Home`, `Services`). Her bir özellik kendi içinde MVVM yapısını takip eder.

---

## 2. Program Akışı (Application Flow)

Uygulamanın baştan sona nasıl çalıştığını anlamak için tipik bir kullanıcı yolculuğu:

1.  **Başlatma (`DeliVerApp.swift`):**
    *   Uygulama `@main` ile başlar.
    *   Global bir `AuthViewModel` nesnesi oluşturulur ve tüm uygulama ortamına (`environmentObject`) enjekte edilir. Bu nesne, kullanıcının oturum durumunu uygulama genelinde takip eder.
    *   İlk olarak `SplashView` (Açılış Ekranı) gösterilir.

2.  **Açılış Ekranı (`SplashView.swift`):**
    *   Kısa bir süre (2 saniye) logo ve yükleme animasyonu gösterir.
    *   Süre dolunca, kullanıcıyı `RootView`'a yönlendirir.

3.  **Kök Yönlendirme (`RootView.swift`):**
    *   `AuthViewModel`'deki `isAuthenticated` değişkenini dinler.
    *   Eğer kullanıcı **giriş yapmışsa** (`isAuthenticated == true`), `HomeView`'a (Ana Sayfa) yönlendirir.
    *   Eğer kullanıcı **giriş yapmamışsa** (`isAuthenticated == false`), `LoginView`'a (Giriş Ekranı) yönlendirir.

4.  **Kimlik Doğrulama Akışı (`Features/Auth`):**
    *   **`LoginView`**: Kullanıcıdan e-posta ve şifre alır. `AuthViewModel`'deki `login()` fonksiyonunu tetikler.
    *   **`AuthViewModel`**: `login()` fonksiyonu, backend'e bir e-posta doğrulama kodu gönderme isteği atar.
    *   **`EmailVerificationView`**: Kullanıcı, e-postasına gelen kodu bu ekrana girer. `confirmEmailAndLogin()` fonksiyonu tetiklenir.
    *   **`AuthViewModel`**: Önce girilen kodun doğruluğunu kontrol eder, ardından `performLogin()` ile asıl giriş işlemini yapar. Başarılı olursa, backend'den gelen **JWT token**'ı `UserDefaults`'e kaydeder ve `isAuthenticated` değişkenini `true` yapar.
    *   `RootView`, `isAuthenticated`'in `true` olduğunu algılar ve kullanıcıyı otomatik olarak `HomeView`'a geçirir.
    *   **`RegisterView`**: Yeni kullanıcı kaydı için kullanılır ve benzer bir akış izler.

5.  **Ana Sayfa (`HomeView.swift`):**
    *   `ServiceListViewModel`'i kullanarak backend'den mevcut tüm servisleri (`Yemek`, `Market`, `Su` vb.) çeker.
    *   Servisleri bir `LazyVGrid` içinde `ServiceCard` bileşenleriyle gösterir.
    *   Kullanıcı bir servise tıkladığında, o servise ait `serviceId` ve `serviceName` ile `CategoryListView`'a yönlendirilir.

6.  **Servis ve Ürün Akışı (`Features/Services`):**
    *   **`CategoryListView`**: Seçilen servise ait ana kategorileri `CategoryListViewModel` aracılığıyla çeker ve listeler.
    *   **`DeliVerFoodView` gibi özel görünümler**: Bazı servisler (örn: Yemek) alt kategorileri destekler. Bu `View`, `ExpandableCategoryView` bileşenini kullanarak iç içe kategori yapısını gösterir.
    *   Kullanıcı bir kategori seçtiğinde, `ServiceProductListView`'a yönlendirilir.
    *   **`ServiceProductListView`**: `ServiceProductListViewModel`'i kullanarak seçilen kategoriye veya servise ait ürünleri çeker. Ürünleri `ProductCard` ile bir grid yapısında gösterir. Arama çubuğu ile ürünler içinde filtreleme yapılabilir.
    *   Kullanıcı bir ürüne tıkladığında `ProductDetailView`'a geçer.

7.  **Sepet ve Sipariş Akışı (`Features/Cart` & Order Integration):**
    *   **Sepete Ekleme**: Kullanıcı ürün detay sayfasından veya ürün kartından ürünleri sepete ekler.
    *   **`CartView`**: Kullanıcının sepetindeki ürünleri gösterir. "Siparişi Tamamla" butonuna tıklandığında `CheckoutView` açılır.
    *   **`CheckoutView`**: Teslimat adresi, telefon numarası, ödeme yöntemi ve özel notlar için form görüntüler.
    *   **Sipariş Oluşturma**: Form doldurulduktan sonra `CartViewModel.createOrderFromCart()` fonksiyonu çağrılır.
    *   **`OrderRepository.createOrder()`**: Backend'e POST /api/orders isteği gönderilir.
    *   **Sipariş Takibi**: Sipariş başarıyla oluşturulduktan sonra kullanıcı sipariş numarası alır ve sipariş durumunu takip edebilir.

8.  **Sipariş Durumu Takibi:**
    *   **Sağ Üst Buton**: Service view'larında sağ üstte sipariş durumu butonu (sepet ikonu yerine) bulunur. Aktif sipariş varsa badge gösterir.
    *   **`OrderStatusView`**: Kullanıcının aktif siparişlerini listeler. Her sipariş için durum, tahmini teslimat zamanı ve ürün listesi gösterilir.
    *   **Sipariş Detayı**: Kullanıcı bir siparişe tıklayarak `OrderDetailView`'da detayları görebilir.
    *   **Sipariş İptal Etme**: PENDING veya CONFIRMED durumundaki siparişler iptal edilebilir.
    *   **Tüm Siparişler**: Geçmiş siparişleri görüntülemek için `AllOrdersView` sayfası mevcuttur.

---

## 3. Detaylı Dosya Analizi

### 3.1. `App` Klasörü

-   **`DeliVerApp.swift`**: Uygulamanın ana giriş noktası. `AuthViewModel`'i oluşturur ve `SplashView`'ı ilk ekran olarak ayarlar.
-   **`SplashView.swift`**: Uygulama logosunu ve bir `ProgressView` gösteren açılış ekranı. 2 saniye sonra `RootView`'a geçiş yapar.
-   **`ContentView.swift`**: Bu dosya, `RootView` tarafından üstlenilen eski bir yönlendirme mantığı içerir. `isAuthenticated` durumuna göre `HomeView` veya `LoginView` gösterir. Şu anki akışta `RootView` daha merkezidir.
-   **`RootView.swift`**: Uygulamanın ana yönlendiricisidir. `AuthViewModel`'i dinleyerek kimliği doğrulanmış ve doğrulanmamış kullanıcılar için doğru ekranı (`HomeView` veya `LoginView`) sunar.

### 3.2. `Core` Klasörü

#### `Core/Components` (Yeniden Kullanılabilir UI Bileşenleri)

-   **`AuthHeader.swift`**: Giriş/Kayıt ekranlarında kullanılan başlık (logo ve başlık metni).
-   **`CodeInputField.swift`**: E-posta doğrulama kodunu girmek için kullanılan, tek tek rakam kutucuklarından oluşan özel `TextField`.
-   **`CustomTextField.swift`**: İkon, başlık ve güvenli giriş seçeneği sunan özelleştirilmiş metin alanı.
-   **`ErrorMessage.swift` / `SuccessMessage.swift`**: Kullanıcıya geri bildirim vermek için kullanılan standart hata ve başarı mesajı `View`'ları.
-   **`ExpandableCategoryView.swift`**: Ana kategoriyi ve tıklandığında açılan alt kategorileri gösteren gelişmiş bir bileşen. `DeliVerFoodView`'da kullanılır.
-   **`GradientButton.swift`**: Projenin genelinde kullanılan, gradyan arka planlı standart buton.
-   **`InfoCard.swift`**: Bilgilendirme metinleri göstermek için kullanılan basit kart.
-   **`ProductCard.swift`**: Bir ürünün resmini, adını ve fiyatını gösteren temel kart bileşeni. `ServiceProductListView`'da kullanılır.
-   **`ProductResponseCard.swift`**: `ProductResponse` modelini doğrudan alarak bir ürün kartı gösterir.
-   **`ValidationHint.swift`**: Form alanlarının altında doğrulama ipuçları (örn: "Şifre en az 6 karakter olmalı") göstermek için kullanılır.

#### `Core/Networking` (Ağ Katmanı)

-   **`Services/APIService.swift`**: Projenin beyni. Backend ile tüm iletişimi yöneten `singleton` sınıf.
    -   `request<T: Codable>()`: Tüm `GET` istekleri için kullanılan generic bir fonksiyondur. URL oluşturma, `URLRequest` hazırlama, veri çekme, HTTP durum kodunu kontrol etme ve gelen JSON'ı `Codable` modellere dönüştürme işlemlerini yapar. Hata ayıklama için detaylı loglama içerir.
    -   `fetchServices()`, `fetchCategories()`, `fetchProducts()`, `searchProducts()` gibi endpoint'e özel fonksiyonlar içerir.
-   **`Services/TokenManager.swift`**: JWT token'ını yönetir. Şu anki implementasyonda `UserDefaults` kullanılıyor, ancak daha güvenli bir çözüm için `Keychain`'e geçilebilir.
-   **`Repository/*`**: `APIService`'i kullanarak belirli veri türleri için mantıksal gruplama sağlar. Örneğin, `AuthRepository` sadece kimlik doğrulama ile ilgili API çağrılarını içerir. Bu, ViewModel'ların doğrudan `APIService`'e bağımlı olmasını engeller.

### 3.3. `Features` Klasörü

#### `Features/Auth` (Kimlik Doğrulama)

-   **`Models/*`**: `LoginRequest`, `RegisterRequest`, `AuthResponse` gibi kimlik doğrulama API'sinin kullandığı veri yapıları.
-   **`ViewModels/AuthViewModel.swift`**:
    -   `@Published` değişkenler aracılığıyla form alanlarının (`email`, `password`) ve UI durumunun (`isLoading`, `errorMessage`) durumunu tutar.
    -   `is...Valid` ve `...ValidationColor` gibi hesaplanmış özelliklerle form doğrulama mantığını içerir.
    -   `register()`, `login()`, `confirmEmailAndLogin()`, `logout()` gibi tüm kimlik doğrulama işlevlerini yönetir. Bu fonksiyonlar, ağ isteklerini yapar ve UI'ı günceller.
-   **`Views/*`**: `LoginView`, `RegisterView`, `EmailVerificationView` gibi kullanıcı arayüzü ekranları. Bu `View`'lar, `AuthViewModel`'den veri okur ve kullanıcı etkileşimlerini (buton tıklamaları vb.) `ViewModel`'deki fonksiyonlara iletir.

#### `Features/Home` (Ana Sayfa)

-   **`Models/Service.swift`**: Ana sayfada gösterilen bir servisin temel bilgilerini (ID, isim, ikon vb.) içeren model.
-   **`ViewModels/ServiceListViewModel.swift`**: `APIService`'i kullanarak servis listesini çeker ve `HomeView`'ın görüntülemesi için `@Published var services` dizisinde saklar.
-   **`Views/HomeView.swift`**: Uygulamanın ana ekranı. Adres bilgisi, promosyon banner'ı ve `ServiceCard`'lardan oluşan bir `LazyVGrid` içerir.

#### `Features/Services` (Servisler ve Ürünler)

-   **`Models/*`**:
    -   **`ProductResponse.swift`**: En karmaşık model dosyası. API'den gelen ürün verisini temsil eder. Backend'den gelen JSON'ın tutarsız yapısıyla başa çıkmak için özel `init(from: Decoder)` implementasyonları içerir. Örneğin, `pricing` alanı bazen tek bir nesne, bazen bir dizi olarak gelebilir. Bu model bu iki durumu da sorunsuz bir şekilde işler.
    -   **`OrderModels.swift`**: Sipariş API'si için gerekli tüm modelleri içerir (`OrderResponse`, `OrderItemResponse`, `CreateOrderRequest`, vb.). UI helper özellikleri (renk, format, ikon) ve enum'ları (`OrderStatus`, `PaymentStatus`, `PaymentMethod`) da burada tanımlanmıştır.
    -   `CategoryResponse.swift`, `ServiceType.swift` gibi diğer veri modelleri.
-   **`ViewModels/*`**:
    -   **`ServiceProductListViewModel.swift`**: Belirli bir servis veya kategori ID'sine göre ürünleri `APIService` aracılığıyla çeker. Arama metnini (`searchText`) alarak ürünleri filtreler.
    -   **`CategoryListViewModel.swift`**: Bir servise ait kategorileri çeker.
    -   **`OrderViewModel.swift`**: Sipariş oluşturma, listeleme, iptal etme gibi tüm sipariş işlemlerini yönetir. Aktif siparişleri takip eder ve UI state'ini yönetir.
    -   `CartViewModel.swift`: Sepet işlevselliğini yönetir ve Order API entegrasyonu içerir.
-   **`Views/*`**:
    -   **`DeliVerFoodView.swift`, `DeliVerMarketView.swift` vb.**: Her bir servis için özelleştirilmiş giriş noktaları. Sağ üstte sipariş durumu butonu bulunur. `DeliVerFoodView`, `ExpandableCategoryView` kullanarak alt kategorileri destekler.
    -   **`ServiceProductListView.swift`**: Ürünleri listeleyen, filtrelenebilen ve yeniden kullanılabilen merkezi `View`. `ServiceProductListViewModel` ile çalışır.
    -   **`OrderStatusView.swift`**: Kullanıcının aktif siparişlerini gösteren ana sipariş takip ekranı. Sipariş kartları, detay görüntüleme ve iptal etme işlevleri içerir.
    -   **`CheckoutView.swift`**: Sipariş tamamlama formu. Teslimat adresi, telefon, ödeme yöntemi ve notlar için alanlar içerir.
    -   `CategoryListView.swift`: Kategorileri basit bir liste olarak gösterir.
    -   `CartView.swift`, `ProductDetailView.swift`: Sepet ve ürün detay ekranları.

---

## 4. Önemli Tasarım Kararları ve Notlar

-   **State Management**: Uygulama genelindeki oturum durumu gibi global state'ler için `@EnvironmentObject`, bir `View` ve alt `View`'ları arasında paylaşılan state'ler için `@StateObject` ve `@ObservedObject`, basit ve yerel UI state'leri için ise `@State` kullanılmıştır.
-   **Sağlam `Codable` Yapısı**: `ProductResponse.swift` dosyasındaki özel `Codable` implementasyonu, projenin en kritik noktalarından biridir. Bu yapı, backend API'sindeki olası tutarsızlıklara karşı uygulamayı daha dayanıklı hale getirir.
-   **Sipariş Yönetimi**: Modern Order API entegrasyonu ile Getir tarzı sipariş takip sistemi. Gerçek zamanlı sipariş durumu takibi, sipariş iptal etme ve geçmiş siparişleri görüntüleme özellikleri.
-   **Loglama**: `APIService` içindeki detaylı `print` ifadeleri, geliştirme sırasında ağ hatalarını ve veri çözümleme sorunlarını ayıklamak için hayati öneme sahiptir.
-   **Yeniden Kullanılabilirlik**: `Core/Components` altındaki bileşenler ve `ServiceProductListView`, `OrderStatusView` gibi `View`'lar, kod tekrarını önlemek ve tutarlı bir UI sağlamak amacıyla tasarlanmıştır.

---

## 5. API Entegrasyonları

### Sipariş API'si (Order API)
Proje, kapsamlı bir sipariş yönetim sistemi içerir:

-   **POST /api/orders**: Sepetten sipariş oluşturma
-   **GET /api/orders**: Kullanıcının tüm siparişlerini sayfalama ile listeleme
-   **GET /api/orders/active**: Aktif siparişleri getirme
-   **GET /api/orders/{id}**: ID ile sipariş detayı
-   **GET /api/orders/by-number/{orderNumber}**: Sipariş numarası ile detay
-   **PUT /api/orders/{id}/status**: Sipariş durumu güncelleme (iptal etme)

### Sipariş Durumları
-   **PENDING**: Onay bekliyor
-   **CONFIRMED**: Onaylandı
-   **PREPARING**: Hazırlanıyor
-   **OUT_FOR_DELIVERY**: Yola çıktı
-   **DELIVERED**: Teslim edildi
-   **CANCELLED**: İptal edildi

### Ödeme Yöntemleri
-   **CASH**: Kapıda nakit ödeme
-   **CARD**: Kredi kartı
-   **ONLINE**: Online ödeme
