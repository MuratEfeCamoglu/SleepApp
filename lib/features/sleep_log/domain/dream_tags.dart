/// Rüya türü — Kaydet ekranında tek seçim; tekrar dokununca kaldırılır.
///
/// Rüya özelliği (`features/dreams`) bu dosyaya bağımlıdır, tersi değil:
/// `SleepEntry` yalnızca bu enumları bilir.
enum DreamKind { normal, lucid, nightmare, recurring }

/// Rüyada hissedilen duygu — Kaydet ekranında çoklu seçim.
enum DreamEmotion { calm, joy, fear, sadness, anger, confusion }
