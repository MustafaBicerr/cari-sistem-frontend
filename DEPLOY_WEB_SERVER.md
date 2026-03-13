# Flutter Web – Sunucu (Docker) Build Notları

## Lokal vs sunucu neden farklı davranır?

- **Lokal:** `flutter run -d chrome` veya `flutter build web` kendi makinede çalışır; `ApiConstants.baseUrl` / `baseUrlImage` release’te `String.fromEnvironment('MOBILE_API_BASE_PROD')` ile belirlenir. Define verilmezse default `https://api.vetapp.com.tr/api` kullanılır.
- **Sunucu:** Build Docker içinde yapılıyorsa, **aynı kod** olsa bile:
  - `--dart-define=MOBILE_API_BASE_PROD=...` verilmiyorsa veya yanlış verilmişse (örn. panel URL’si), görsel istekleri panel’e gider.
  - `.env` / env değişkenleri container’a doğru geçmiyorsa yine yanlış base kullanılabilir.

Bu yüzden tek kaynak “build’i kaç kere aldığın” değil, **hangi base URL ile** aldığındır.

## Yapılan düzeltmeler (build’den bağımsız çalışması için)

1. **Backend (`backend/src/services/storage/local.js`):**
   - `getURL()` path’i normalize ediyor (baştaki `vetapp.com.tr/` vb. kaldırılıyor).
   - `ASSET_BASE_URL` panel olsa bile görsel URL’si **her zaman** `https://api.vetapp.com.tr/...` dönecek şekilde zorlanıyor.
   - Böylece API’den gelen `full_image_url` her zaman doğru domain’e işaret ediyor.

2. **Frontend (`lib/core/utils/image_utils.dart`):**
   - Backend’den gelen `full_image_url` zaten `https://api.vetapp.com.tr/...` ise **doğrudan** kullanılıyor (base’i tekrar eklemiyoruz).
   - Böylece Docker’da yanlış `MOBILE_API_BASE_PROD` verilse bile, API doğru URL döndüğü sürece görseller doğru yüklenir.

## Sunucu Dockerfile’da yapılacaklar

Frontend’i sunucuda Docker ile build ediyorsan, **mutlaka** doğru API base’i ver:

```dockerfile
# Örnek: Flutter build aşamasında
RUN flutter build web --release --no-cache \
  --dart-define=MOBILE_API_BASE_PROD=https://api.vetapp.com.tr/api
```

- `MOBILE_API_BASE_PROD` **panel** değil, **api** domain’i olmalı: `https://api.vetapp.com.tr/api`.
- Build sonrası `build/web/` çıktısını Nginx’in servis ettiği dizine **tamamen** kopyaladığından emin ol (eski `main.dart.js` kalmasın).

## Deploy sırası

1. **Backend’i güncelle ve yeniden başlat**  
   Böylece tüm product/response’larda `full_image_url` artık `https://api.vetapp.com.tr/...` olur.

2. **Frontend’i güncelle**  
   İster lokal build alıp `build/web/` içeriğini sunucuya at, ister sunucudaki Dockerfile’da yukarıdaki `--dart-define` ile build al; sonrasında bu çıktıyı panel’in statik dizinine koy.

3. **Tarayıcı cache’i**  
   Gerekirse Ctrl+Shift+R veya cache’i kapatıp tekrar dene.

## DNS

`api.vetapp.com.tr` ve `panel.vetapp.com.tr` aynı IP’ye (46.62.248.74) işaret ediyor; Nginx host’a göre ayırıyor. Sorun DNS’ten değil, uygulama tarafındaki base URL ve path kullanımından kaynaklanıyordu.
