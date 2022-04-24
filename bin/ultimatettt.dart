import 'dart:io';
import 'dart:math';

String readLineSync() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

Random rand = new Random(0);

List<Point> centers = 
    [new Point(1, 1), new Point(4, 1), new Point(7, 1),
    new Point(1, 4), new Point(4, 4), new Point(7, 4),
    new Point(1, 7), new Point(4, 7), new Point(7, 7)];
    
//2 rows, 3 cols, 2 diagonals
// counts in each winning path [me, opp]
List<List<int>> globalCounts = 
    new List.generate(8, (i) => [0, 0]);

//9 boards, rows, then cols of 8 path counts
List<List<List<int>>> localCounts = new List.generate(9,
    (i) => new List.generate(8, (i) =>[0, 0]));
    
late int myPlayer;
late int oppPlayer;
int turn = 0;

/**
 * Auto-generated code below aims at helping you parse
 * the standard input according to the problem statement.
 **/
void main() {
    List inputs;
    List<Point> validActions = [];
    Game globalGame = Board.start();
    MonteCarlo mc = new MonteCarlo(globalGame);
    int totalSims = 0;

    // game loop
    while (true) {
        inputs = readLineSync().split(' ');
        int opponentRow = int.parse(inputs[0]);
        int opponentCol = int.parse(inputs[1]);
        
        if(turn == 0){
            if(opponentRow == -1){
                myPlayer = 1;
                oppPlayer = 2;
            } else  {
                myPlayer = 2;
                oppPlayer = 1;
            }
        }
        
        if(opponentRow != -1){
            var move = new Move(oppPlayer, new Point(opponentRow, opponentCol));
            globalGame.makePlay(move);
        }
        
        int validActionCount = int.parse(readLineSync());
        validActions.clear();
        
        for (int i = 0; i < validActionCount; i++) {
            inputs = readLineSync().split(' ');
            int row = int.parse(inputs[0]);
            int col = int.parse(inputs[1]);
            validActions.add(new Point(row, col));
        }

        // Write an action using print()
        // To debug: stderr.writeln('Debug messages...');
        // stderr.writeln("Moves: ${globalGame.movesPlayed}");
        stderr.writeln("Valids: ${validActions}");
        stderr.writeln("Deadboards: ${globalGame.deadBoards}");
        // stderr.writeln("GlobalCounts: ${globalGame.globalCounts}");
        if(validActions.length != Board.legalPlays(globalGame).length){
            stderr.writeln("Legals: ${Board.legalPlays(globalGame)}");
        }
        assert(validActions.length == Board.legalPlays(globalGame).length);
        
        // stderr.writeln("Global hash: ${globalGame.hash}");
        
        var play;
        if(turn == 0) {
            play = mc.getPlay(650);
        } else {
            play = mc.getPlay(65);
        }
        stderr.writeln("Sims ${mc.simCount}");
        stderr.writeln("MonteCarlo play: $play");
        totalSims += mc.simCount;
        turn++;
        stderr.writeln("Simulation average: ${totalSims / turn }");
        
        // //check for winners
        // var winner = validActions.firstWhere(
        //     (p) => winAnyBoard(globalGame.movesPlayed, p), 
        //     orElse: () => null );
        
        if(globalGame.movesPlayed.length == 0){
            // take the middle
            var move = new Move(myPlayer, new Point(4,4));
            globalGame.makePlay(move);
            print("4 4");
        } else {
            globalGame.makePlay(play);
            print("${play.play.x} ${play.play.y}");
        }
        // } else if(winner != null){
        //     stderr.writeln("Found a winner: $winner");
        //     var move = new Move(myPlayer, winner);
        //     globalGame.makePlay(move);
        //     print("${winner.x} ${winner.y}");
        // } else {
        //     var corners = validActions.where(
        //         (orig) {
        //           Point p = new Point(orig.x % 3, orig.y %3);
        //           return p.x == p.y || p.x + p.y == 2;
        //         }).toList();
        //     if(corners.length > 0){
        //         int r = rand.nextInt(corners.length);
        //         var move = new Move(myPlayer, corners[r]);
        //         globalGame.makePlay(move);
        //         print("${corners[r].x} ${corners[r].y}");
        //     } else {
        //         int r = rand.nextInt(validActions.length);
        //         var move = new Move(myPlayer, validActions[r]);
        //         globalGame.makePlay(move);
        //         print("${validActions[r].x} ${validActions[r].y}");
        //     }
        // }

    }
}

bool winAnyBoard(List<Move> movesPlayed, Point play){
    assert(movesPlayed.length <= 80);
    
    //not enough points to declare winner
    if(movesPlayed.length < 3)
        return false;
    
    int boardRowIndex = play.x ~/ 3;
    int boardColIndex = play.y ~/ 3;
    List<int> boardRows = [boardRowIndex * 3, boardRowIndex * 3 + 1, boardRowIndex * 3 + 2];
    List<int> boardCols = [boardColIndex * 3, boardColIndex * 3 + 1, boardColIndex * 3 + 2];
    
    //stderr.writeln("Miniboard rows ${boardRows} cols ${boardCols}");
    
    List<Point> firstMini = movesPlayed.where((p) => p.player == 1 &&
        boardRows.contains(p.play.x) && boardCols.contains(p.play.y))
        .map((p) => new Point(p.play.x % 3, p.play.y % 3))
        .toList();
    List<Point> secondMini = movesPlayed.where((p) => p.player == 2 &&
        boardRows.contains(p.play.x) && boardCols.contains(p.play.y))
        .map((p) => new Point(p.play.x % 3, p.play.y % 3))
        .toList();
        
        //not enough points to declare winner
    if(firstMini.length < 2 && secondMini.length < 2)
        return false;
    
    var mappedPlay = new Point (play.x % 3, play.y % 3);
    firstMini.add(mappedPlay);
    secondMini.add(mappedPlay);
    
    if(checkWinner(firstMini)){
        return true;
    } else if(checkWinner(secondMini)) {
        return true;
    } else {
        return false;
    }
    
    
}

bool checkWinner(List<Point> points){
    //3 rows, 3 cols, 2 diags
    List<int> counts = new List.filled(8, 0);
    points.forEach((p){
       counts[p.x]++;
       counts[p.y + 3]++;
       if(p.x == p.y){
           counts[6]++;
       } 
       if (p.x + p.y == 2){
           counts[7]++;
       }
    });
    
    return counts.any((c) => c == 3);
}


class Point {
    final int x;
    final int y;

    const Point(this.x, this.y);

    String toString() => "{$x,$y}";


    List<Point> get neighbors4 =>
        [
        new Point(x + 1, y),
        new Point(x - 1, y),
        new Point(x, y + 1),
        new Point(x, y - 1)
        ];

    List<Point> get neighbors8 =>
        [
        new Point(x + 1, y),
        new Point(x - 1, y),
        new Point(x, y + 1),
        new Point(x, y - 1),
        new Point(x + 1, y + 1),
        new Point(x - 1, y - 1),
        new Point(x - 1, y + 1),
        new Point(x + 1, y - 1)
        ];

    num distance(Point other) {
        return sqrt(distance2(other));
    }

    int distance2(Point other){
        int dx = x - other.x;
        int dy = y - other.y;
        return dx * dx + dy * dy;
    }

    // Override hashCode using strategy from Effective Java,
    // Chapter 11.
    int get hashCode {
        int result = 17;
        result = 37 * result + x;
        result = 37 * result + y;
        return result;
    }

    // You should generally implement operator == if you
    // override hashCode.
    bool operator ==(other) {
        if (other is! Point) return false;
        Point point = other;
        return (point.x == x &&
            point.y == y);
    }
}

class Move {
    final int player;
    final Point play;
    
    const Move(this.player, this.play);
    
    String toString() => "$player:$play";
    
    // Override hashCode using strategy from Effective Java,
    // Chapter 11.
    int get hashCode {
        int result = 17;
        result = 37 * result + player;
        result = 37 * result + play.hashCode;
        return result;
    }

    // You should generally implement operator == if you
    // override hashCode.
    bool operator ==(other) {
        if (other is! Move) return false;
        Move move = other;
        return (move.play.x == play.x &&
            move.play.y == play.y &&
            move.player == player);
    }
}

class Game {
    //2 rows, 3 cols, 2 diagonals
    // counts in each winning path [me, opp]
    List<List<int>> globalCounts = 
        new List.generate(8, (i) => [0, 0]);
    
    //9 boards, rows, then cols of 8 path counts
    List<List<List<int>>> localCounts = new List.generate(9,
        (i) => new List.generate(8, (i) =>[0, 0]));
        
    List<bool> deadBoards = new List.filled(9, false);
    
    List<Move> movesPlayed = [];
    
    List<Game> children = [];
    
    Map<int, List<Point>> unplayed = {};
    
    // int hash = 5;
    
    String toString() => "Moves ${movesPlayed.length} Dead ${deadBoards.where((b) => b).length} Globals $globalCounts";
    
    int get hash {
        int result = 5;
        if(movesPlayed.length > 0){
            result += movesPlayed.fold(result, (a, b) => 3 * a + b.hashCode);
        }
        return result;
    }
    
    Game(){
        var boards = [0, 1, 2, 3, 4, 5, 6, 7, 8];
        boards.forEach((board){
            unplayed[board] = 
            new List.generate(9, (i) =>
            new Point( (board % 3) * 3 + i % 3,
            (board ~/ 3 ) * 3 + i ~/ 3));
            // new Point(i ~/ 3 + board % 3, i % 3 + board ~/ 3));
        });
        
    }
    
    Game.clone(Game other){
        var boards = [0, 1, 2, 3, 4, 5, 6, 7, 8];
        boards.forEach((board){
            unplayed[board] = 
            new List.generate(9, (i) =>
            new Point( (board % 3) * 3 + i % 3,
            (board ~/ 3 ) * 3 + i ~/ 3));
            // new Point(i ~/ 3 + board % 3, i % 3 + board ~/ 3));
        });
        
        other.movesPlayed.forEach((m) => this.makePlay(m));
    }
    
    void makePlay(Move move){
        addCounts(move);
        movesPlayed.add(move);
        unplayed[globalBoardIndex(
            new Point(move.play.x ~/ 3, move.play.y ~/ 3))]!
            .remove(move.play);
    }
    
    void addCounts(Move move){
        int player = move.player;
        Point play = move.play;
        int boardRowIndex = play.x ~/ 3;
        int boardColIndex = play.y ~/ 3;
        var mappedPlay = new Point (play.x % 3, play.y % 3);
        
        //which of the 9 local boards
        int localIndex = boardRowIndex * 3 + boardColIndex;
        var counts = localCounts[localIndex];
        counts[mappedPlay.x][player - 1]++;
        counts[mappedPlay.y + 3][player - 1]++;
        if(mappedPlay.x == mappedPlay.y){
            counts[6][player - 1]++;
        } 
        if (mappedPlay.x + mappedPlay.y == 2){
            counts[7][player - 1]++;
        }
        
        //update globalcounts if it's a win
        if (counts.any((c) => c[player - 1] == 3)) {
            // stderr.writeln("Adding $play for $player won a local");
            Point board = new Point(boardRowIndex, boardColIndex);
            globalCounts[board.x][player - 1]++;
            globalCounts[board.y + 3][player - 1]++;
            if(board.x == board.y){
                globalCounts[6][player - 1]++;
            } 
            if (board.x + board.y == 2){
                globalCounts[7][player - 1]++;
            }
            
            //update dead boards and unplayed moves
            deadBoards[globalBoardIndex(board)] = true;
            unplayed[globalBoardIndex(board)]!.clear();
        }
    }
    
}

//rules of the game
class Board {
    static Game start(){
        // Returns a representation of the starting state of the game.
        return new Game();
    }

    static int currentPlayer(Game state){
        // Takes the game state and returns the current player's
        // number.
        //if even, it's player 1's turn, else player 2
        return (state.movesPlayed.length % 2) + 1;
    }

    static Game nextState(Game state, Move play){
        // Takes the game state, and the move to be applied.
        // Returns the new game state.
        Game clone = new Game.clone(state);
        clone.makePlay(play);
        
        return clone;

    }
    
    static List<Move> legalPlays(Game game){
        // Takes a sequence of game states representing the full
        // game history, and returns the full list of moves that
        // are legal plays for the current player.
        if (game.movesPlayed.length == 0){
            return game.unplayed.values
            .expand((v) => v.map((p) => 
              Move(Board.currentPlayer(game), p)))
            .toList();
        } else {
            var lastMove = game.movesPlayed.last;
            //determine if we are mini-board bound or not
            int boardRowIndex = lastMove.play.x % 3;
            int boardColIndex = lastMove.play.y % 3;
            Point globalBoard = new Point(boardRowIndex, boardColIndex);
            if(game.deadBoards[globalBoardIndex(globalBoard)]){
                return game.unplayed.values
                  .expand((v) => v.map((p) => 
                    Move(Board.currentPlayer(game), p)))
                  .toList();
            } else {
                //on a live board
                return game.unplayed[globalBoardIndex(globalBoard)]!
                  .map((p) => Move(Board.currentPlayer(game), p)).toList();
            }
        
        }
    }

    static int winner(Game game){
        // Takes a sequence of game states representing the full
        // game history.  If the game is now won, return the player
        // number.  If the game is still ongoing, return zero.  If
        // the game is tied, return a different distinct value, e.g. -1.
        
        if(game.globalCounts.any((c) => c[0] == 3)) {
            return 1;
        } else if (game.globalCounts.any((c) => c[1] == 3)) {
            return 2;
        } else {
            if(Board.legalPlays(game).length == 0){
                return -1;
            }
            return 0;
        }
        
    }
    
}

class PlayerHash{
    final int player;
    final int hash;
    
    const PlayerHash(this.player, this.hash);
    
    int get hashCode {
        int result = 17;
        result = 37 * result + player;
        result = 37 * result + hash;
        return result;
    }

    bool operator ==(other) {
        if (other is! PlayerHash) return false;
        PlayerHash move = other;
        return (move.player == player &&
            move.hash == hash);
    }
    
    String toString() => "$player:$hash";
}

class MonteCarlo {
    Game game;
    Stopwatch sw = new Stopwatch();
    int simCount = 0;
    
    //{[player, hash] -> count}
    Map<PlayerHash, int> wins = new Map<PlayerHash, int>();
    Map<PlayerHash, int> plays = new Map<PlayerHash, int>();
    
    MonteCarlo(this.game) {
        sw.start();
    }
    
    Move getPlay(int timeout){
        var legals = Board.legalPlays(game);
        if(legals.length == 0){
            return legals.first;
        }
        
        simCount = 0;
        sw.reset();
        while(sw.elapsedMilliseconds < timeout){
            //find best move
            runSimulation();
            simCount++;
        }
        
        //[move, hash]
        var nextStates = legals.map((l) => 
            [l, Board.nextState(game,  l)
                .hash])
            .toList();
        // stderr.writeln("Looking in hash for $nextStates");
        // stderr.writeln("Wins $wins");
        // stderr.writeln("Plays $plays");
        
        //[move, percent]
        var percentWins = nextStates.map((ns) {
            PlayerHash pHash = new PlayerHash(myPlayer, ns[1] as int);
            int winCount = 0;
            if(wins.containsKey(pHash)){
                winCount = wins[pHash]!;
            }
            int playCount = 1;
            if(plays.containsKey(pHash)){
                playCount = plays[pHash]!;
            }
            return [ns[0], 
             winCount / playCount];
        }).toList();
        
        // stderr.writeln("PercentWins: $percentWins");
        
        var bestPercent = percentWins.reduce((a, b) => 
          (a[1] as double) > (b[1] as double) ? a : b);
        
        stderr.writeln("Best Percent: $bestPercent");
        
        return bestPercent[0] as Move;
       
    }
    
    void runSimulation(){
        var state = new Game.clone(game);
        int firstHash = state.hash;
        int player = Board.currentPlayer(game);
        //set of [player, hash]
        var visited = <PlayerHash>[];
        bool expand = true;
        int winner = 0;
        
        //pre calc first rung legal state hashes
        int turnplayer;
        turnplayer = Board.currentPlayer(state);
        var legals;
        legals = Board.legalPlays(state);
        var legalStates = legals.map((l) =>
            [l, new PlayerHash(turnplayer, 
            Board.nextState(state, l).hash)])
            .toList();
        var play;
        while(true){
            legals = Board.legalPlays(state);
            turnplayer = Board.currentPlayer(state);
            play = null;
            //UCB
            if(expand){
                //UCB
                if( legalStates.every((l) => 
                    plays.containsKey(l[1])) ) {
                    // play = legals[rand.nextInt(legals.length)];
                    num logTotal = legalStates.fold(0, (sum, l) => sum + plays[l[1]]);
                    var best = legalStates.map((l) =>
                        [wins[l[1]]! / plays[l[1]]! +
                        1.4 * sqrt( logTotal / plays[l[1]]!), l]
                    ).reduce((a, b) => a[0] > b[0] ? a : b);
                    // stderr.writeln("Best score: $best");
                    play = best[1][0];
                    
                } else {
                    //random
                    play = legals[rand.nextInt(legals.length)];
                }
            } else {
                //random
                play = legals[rand.nextInt(legals.length)];
                
            }
            
            state.makePlay(play);
            
            // `player` here and below refers to the player
            // who moved into that particular state.
            int hash = state.hash;
            PlayerHash pHash = new PlayerHash(turnplayer, hash);
            if(expand && !plays.containsKey(pHash)){
                expand = false;
                plays[pHash] = 0;
                wins[pHash] = 0;
            }
            
            visited.add(pHash);
            
            winner = Board.winner(state);
            if(winner != 0){
                // stderr.writeln("Winner $winner found in $state");
                break;
            }
        }
            
        // stderr.writeln("Update winner $winner stats for ${visited.first}");
        
        visited.forEach((visit) {
            if(plays.containsKey(visit)){
                // stderr.writeln("Update play count for $visit");
                plays[visit] = plays[visit]! + 1;
                if(player == winner){
                    // stderr.writeln("Update win count for $visit");
                    wins[visit] = wins[visit]! + 1;
                }
            }
        });
        
    }
    
}

// 0 | 3 | 6
//---+---+--
// 1 | 4 | 7
//---+---+--
// 2 | 5 | 8
int globalBoardIndex(Point point){
    // global boards
    // (0, 0) - (2, 2)
    return point.y * 3 + point.x;
}