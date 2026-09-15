// lib/core/services/web_storage/web_storage.dart
// Conditional export for cross-platform local storage access

export 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage_web.dart';
