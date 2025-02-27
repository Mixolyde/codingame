// Copyright (c) 2016, Brian Grey. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import '../bin/connect4.dart';
import 'package:test/test.dart';



void main() {
  group('BitBoard:', () {
    test('new board', () {
      Bitboard bitboard = Bitboard();
      bitboard.printBoard();
      expect(bitboard.p0board, BigInt.zero);
      expect(bitboard.p1board, BigInt.zero);
      expect(bitboard.counter, 0);
      expect(bitboard.height, [0, 8, 16, 24, 32, 40, 48, 56, 64]);
      expect(bitboard.moves, []);
      expect(bitboard.isWin(0), false);
      expect(bitboard.isWin(1), false);
      expect(bitboard.listMoves(), [0, 1, 2, 3, 4, 5, 6, 7, 8]);
    });
    test('1 across bottom', () {
      Bitboard bitboard = Bitboard();
      bitboard.makeMove(0);
      bitboard.makeMove(1);
      bitboard.makeMove(2);

      bitboard.makeMove(3);
      bitboard.makeMove(4);
      bitboard.makeMove(5);

      bitboard.makeMove(6);
      bitboard.makeMove(7);
      bitboard.makeMove(8);
      bitboard.printBoard();
      expect(bitboard.counter, 9);
      expect(bitboard.height, [1, 9, 17, 25, 33, 41, 49, 57, 65]);
      expect(bitboard.moves, [0, 1, 2, 3, 4, 5, 6, 7, 8]);
      expect(bitboard.isWin(0), false);
      expect(bitboard.isWin(1), false);
      expect(bitboard.listMoves(), [0, 1, 2, 3, 4, 5, 6, 7, 8]);
    });
    test('X wins', () {
      Bitboard bitboard = Bitboard();
      bitboard.makeMove(0);
      bitboard.makeMove(1);
      bitboard.makeMove(0);
      bitboard.makeMove(1);
      bitboard.makeMove(0);
      bitboard.makeMove(1);
      bitboard.makeMove(0);
      bitboard.printBoard();
      expect(bitboard.counter, 7);
      expect(bitboard.height, [4, 11, 16, 24, 32, 40, 48, 56, 64]);
      expect(bitboard.moves, [0, 1, 0, 1, 0, 1, 0]);
      expect(bitboard.isWin(0), true);
      expect(bitboard.isWin(1), false);
      expect(bitboard.listMoves(), [0, 1, 2, 3, 4, 5, 6, 7, 8]);
    });
    test('y wins', () {
      Bitboard bitboard = Bitboard();
      bitboard.makeMove(0);
      bitboard.makeMove(8);
      bitboard.makeMove(7);
      bitboard.makeMove(8);
      bitboard.makeMove(7);
      bitboard.makeMove(8);
      bitboard.makeMove(7);
      bitboard.makeMove(8);
      bitboard.printBoard();
      expect(bitboard.counter, 8);
      expect(bitboard.height, [1, 8, 16, 24, 32, 40, 48, 59, 68]);
      expect(bitboard.moves, [0, 8, 7, 8, 7, 8, 7, 8]);
      expect(bitboard.isWin(0), false);
      expect(bitboard.isWin(1), true);
      expect(bitboard.listMoves(), [0, 1, 2, 3, 4, 5, 6, 7, 8]);
    });
    test('X wins diagonal', () {
      Bitboard bitboard = Bitboard();
      bitboard.makeMove(0); // X
      bitboard.makeMove(1); // O
      bitboard.makeMove(1); // X
      bitboard.makeMove(2); // O
      bitboard.makeMove(2);
      bitboard.makeMove(3);
      bitboard.makeMove(3);
      bitboard.makeMove(3);
      bitboard.makeMove(3);
      bitboard.makeMove(1);
      bitboard.makeMove(2);
      bitboard.printBoard();
      expect(bitboard.counter, 11);
      expect(bitboard.isWin(0), true);
      expect(bitboard.isWin(1), false);
      expect(bitboard.listMoves(), [0, 1, 2, 3, 4, 5, 6, 7, 8]);
    });
    test('undo moves', () {
      Bitboard bitboard = Bitboard();
      bitboard.makeMove(0);
      bitboard.makeMove(8);
      bitboard.makeMove(7);
      bitboard.makeMove(8);
      bitboard.makeMove(7);
      bitboard.makeMove(8);
      bitboard.makeMove(7);
      bitboard.makeMove(8);
      bitboard.undoMove();
      bitboard.undoMove();
      bitboard.undoMove();
      bitboard.undoMove();
      bitboard.undoMove();
      bitboard.undoMove();
      bitboard.undoMove();
      bitboard.undoMove();
      bitboard.printBoard();
      expect(bitboard.p0board, BigInt.zero);
      expect(bitboard.p1board, BigInt.zero);
      expect(bitboard.counter, 0);
      expect(bitboard.height, [0, 8, 16, 24, 32, 40, 48, 56, 64]);
      expect(bitboard.moves, []);
      expect(bitboard.isWin(0), false);
      expect(bitboard.isWin(1), false);
      expect(bitboard.listMoves(), [0, 1, 2, 3, 4, 5, 6, 7, 8]);
    });
    test('Fill some columns', () {
      Bitboard bitboard = Bitboard();
      bitboard.makeMove(0);
      bitboard.makeMove(0);
      bitboard.makeMove(0);
      bitboard.makeMove(0);
      bitboard.makeMove(0);
      bitboard.makeMove(0);
      bitboard.makeMove(0);

      bitboard.makeMove(2);
      bitboard.makeMove(2);
      bitboard.makeMove(2);
      bitboard.makeMove(2);
      bitboard.makeMove(2);
      bitboard.makeMove(2);
      bitboard.makeMove(2);
      
      bitboard.makeMove(8);
      bitboard.makeMove(8);
      bitboard.makeMove(8);
      bitboard.makeMove(8);
      bitboard.makeMove(8);
      bitboard.makeMove(8);
      bitboard.makeMove(8);

      bitboard.printBoard();
      expect(bitboard.counter, 21);
      expect(bitboard.height, [7, 8, 23, 24, 32, 40, 48, 56, 71]);
      expect(bitboard.moves, [0, 0, 0, 0, 0, 0, 0,
                              2, 2, 2, 2, 2, 2, 2,
                              8, 8, 8, 8, 8, 8, 8]);
      expect(bitboard.isWin(0), false);
      expect(bitboard.isWin(1), false);
      expect(bitboard.listMoves(), [1, 3, 4, 5, 6, 7]);
    });
  });

}

List<String> boardRows = [
  "........0",
  "........1",
  "........0",
  "........1",
  ".....0..0",
  "...0.1..1",
  ".101.0..0",
];
