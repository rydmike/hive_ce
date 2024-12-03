import 'dart:async';

import 'package:test/test.dart';

import '../util/is_browser.dart';
import 'integration.dart';

Future _performTest(bool lazy) async {
  final amount = isBrowser ? 5 : 100;
  var box = await openBox(lazy);

  for (var i = 0; i < amount; i++) {
    for (var n = 0; n < 100; n++) {
      final completer = Completer();
      scheduleMicrotask(() async {
        await box.put('string$i', 'test$n');
        await box.put('int$i', n);
        await box.put('bool$i', n % 2 == 0);
        await box.put('null$i', null);

        expect(await await box.get('string$i'), 'test$n');
        expect(await await box.get('int$i'), n);
        expect(await await box.get('bool$i'), n % 2 == 0);
        expect(await await box.get('null$i', defaultValue: 0), null);

        completer.complete();
      });
      await completer.future;
    }
  }

  box = await box.reopen();
  for (var i = 0; i < amount; i++) {
    expect(await await box.get('string$i'), 'test99');
    expect(await await box.get('int$i'), 99);
    expect(await await box.get('bool$i'), false);
    expect(await await box.get('null$i', defaultValue: 0), null);
  }
  // Simple test to check we can read the last int value from the box.
  // Fails on WASM build, OK on native build and JS build.
  final int value = await box.get('int${amount - 1}');
  expect(value, 99);
  await box.close();
}

void main() {
  group(
    'put many entries with the same key',
    () {
      test('normal box', () => _performTest(false));

      test('lazy box', () => _performTest(true));
    },
    timeout: longTimeout,
  );
}
