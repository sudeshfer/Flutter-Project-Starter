/// Keys used with `SecureStorage` and `KeyValueStorage`.
///
/// Keep every key here so collisions are easy to spot.
abstract final class StorageKeys {
  // Secure storage.
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';

  // Key-value storage.
  static const String exampleItemsCache = 'example_items_cache';
}
