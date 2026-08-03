import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _kIsWasm = kIsWeb && !bool.fromEnvironment('dart.library.html');

void main() {
  test('kIsWeb / dart.library.html env', () {
    // ignore: avoid_print
    print('kIsWeb=$kIsWeb');
    // ignore: avoid_print
    print('env dart.library.html=${bool.fromEnvironment('dart.library.html')}');
    // ignore: avoid_print
    print('_kIsWasm=$_kIsWasm');
  });
}