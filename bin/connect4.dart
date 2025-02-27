import 'dart:io';
import 'dart:math';

String readLineSync() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

Random rand = Random(0);
int HEIGHT = 7;
int WIDTH = 9;
int myId = 0;
int oppId = 1;
int turnIndex = 0;
List<String> boardRows = List.filled(WIDTH, "");

/**
 * Drop chips in the columns.
 * Connect at least 4 of your chips in any direction to win.
 **/
void main() {
    List inputs;
    inputs = readLineSync().split(' ');
    myId = int.parse(inputs[0]); // 0 or 1 (Player 0 plays first)
    oppId = int.parse(inputs[1]); // if your index is 0, this will be 1, and vice versa

    // game loop
    while (true) {
        turnIndex = int.parse(readLineSync()); // starts from 0; As the game progresses, first player gets [0,2,4,...] and second player gets [1,3,5,...]
        for (int i = 0; i < 7; i++) {
            String boardRow = readLineSync(); // one row of the board (from top to bottom)
            boardRows[i] = boardRow;
            stderr.writeln("boardRow: $boardRow");
        }
        int numValidActions = int.parse(readLineSync()); // number of unfilled columns in the board
        List<int> validActions = [];
        for (int i = 0; i < numValidActions; i++) {
            int action = int.parse(readLineSync()); // a valid column index into which a chip can be dropped
            validActions.add(action);
        }
        int oppPreviousAction = int.parse(readLineSync()); // opponent's previous chosen column index (will be -1 for first player in the first turn)

        // Write an action using print()
        // To debug: stderr.writeln('Debug messages...');


        // Output a column index to drop the chip in. Append message to show in the viewer.
        //output random column index
        int randPick = rand.nextInt(validActions.length);
        stderr.writeln("randPick: $validActions[randPick]");

        print(validActions[randPick]);
    }
}

class Bitboard{
  // 7 x 9 board
  // 7 15 23 31 39 47 55 63 71 - extra row for win detection
  // -------------------------
  // 6 14 22 30 38 46 54 62 70
  // 5 13 21 29 37 45 53 61 69
  // 4 12 20 28 36 44 52 60 68
  // 3 11 19 27 35 43 51 59 67
  // 2 10 18 26 34 42 50 58 66
  // 1  9 17 25 33 41 49 57 65
  // 0  8 16 24 32 40 48 56 64
  // -------------------------

  BigInt p0board = BigInt.zero;
  BigInt p1board = BigInt.zero;
  int counter = 0;
  List<int> height = [0, 8, 16, 24, 32, 40, 48, 56, 64];
  List<int> moves = [];

  Bitboard(){
  }

  void printBoard(){
    stderr.writeln("p0board: $p0board");
    stderr.writeln("p1board: $p1board");
    for(int i = HEIGHT - 1; i >= 0; i--){
      for(int j = 0; j < WIDTH; j++){

        if((p0board & BigInt.one << (j * (HEIGHT + 1) + i)) != BigInt.zero){
          stderr.write('X');
        } else if((p1board & BigInt.one << (j * (HEIGHT + 1) + i)) != BigInt.zero){
          stderr.write('O');
        } else {
          stderr.write('.');
        }
      }
      stderr.writeln();
    }
    if (counter % 2 == 0){
      stderr.writeln("X's turn");
    } else {
      stderr.writeln("O's turn");
    }
  }

  void makeMove(int move){
    if(counter % 2 == 0){
      p0board |= BigInt.one << height[move];
    } else {
      p1board |= BigInt.one << height[move];
    }
    height[move]++;
    moves.add(move);
    counter++;
  }

  void undoMove(){
    counter--;
    int move = moves.removeLast();
    height[move]--;

    if(counter % 2 == 0){
      p0board ^= (BigInt.one << height[move]);
    } else {
      p1board ^= (BigInt.one << height[move]);
    }
  }

  // magic numbers are 1, 7, 8, 9
  bool isWin(int player) {
    List<int> directions = [1, 7, 8, 9];
    BigInt bitboard;
    for(int direction in directions) {
      switch (player) {
        case 0:
          bitboard = p0board;
          break;
        case 1:
          bitboard = p1board;
          break;
        default:
          return false;
      }
      
      if (bitboard & (bitboard >> direction) &
           (bitboard >> (2 * direction)) & (bitboard >> (3 * direction)) != BigInt.zero)
        return true;
    }
    return false;
  }

  List<int> listMoves() {
    List<int> moves = [];
    // 0b1000000_1000000_1000000_1000000_1000000_1000000_1000000_1000000_1000000L;
    BigInt TOP = BigInt.parse(
      // 776666666666555555555544444444443333333333222222222211111111110000000000
      // 109876543210987654321098765432109876543210987654321098765432109876543210
        '100000001000000010000000100000001000000010000000100000001000000010000000',
        radix: 2);

    for(int col = 0; col < WIDTH; col++) {
        if ((TOP & (BigInt.one << height[col])) == BigInt.zero) moves.add(col);
    }
    return moves;
}
}