# Uyku

Sakin bir uyku ve toparlanma takipçisi (Flutter). Tasarım: `Uyku sağlığı uygulaması.html`, kurallar: `CLAUDE.md`.

## Çalıştırma

```sh
flutter pub get
flutter run
```

İlk açılışta Kurulum gelir. Tasarımdaki gibi dolu ekranları görmek için **Ayarlar → Örnek verilerle doldur**.

## Uyku sesleri

`assets/sounds/` altındaki 4 MP3 (sleep_music, piano, sleep_cycle, lofi). Ses eklemek için dosyayı buraya koy ve `lib/features/sounds/domain/sleep_sound.dart` içindeki `SleepSound`'a ekle.

## Doğrulama

```sh
flutter analyze          # 0 sorun
```
