import '../bin/dontpanic2.dart';
import 'package:test/test.dart';

void main() {
  group('legal moves:', () {
    exitFloor = 1;
    nbRounds = 10;
    width = 10;
    test('new game no elevators', () {
      Game game = new Game(0, 5, 0, true, 0,
        [[]], [[]], []);
      expect(game.legalMoves().length, equals(2));
    });
    test('new game elevators', () {
      Game game = new Game(0, 5, 0, true, 5,
        [[]], [[]], []);
      expect(game.legalMoves().length, equals(3));
    });
  });
}
