import 'lib/src/core/cache/cache_key_manager.dart';

void main() {
  print('Available CacheKeyType values:');
  for (final type in CacheKeyType.values) {
    print('- ${type.name}');
  }
  print('---');
  print('Testing fundData:');
  final fundDataType = CacheKeyType.values.where((e) => e.name == 'fundData').firstOrNull;
  print('Result: $fundDataType');
}