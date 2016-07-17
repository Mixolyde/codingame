import '../bin/codersstrikeback.dart';
import 'package:test/test.dart';

void main() {
  group('points:', () {
    test('2 points are equal', () {
      Point a = new Point(3, 4);
      Point b = new Point(3, 4);
      expect(a == b, equals(true));
    });
  });
}
