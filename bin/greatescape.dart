import 'dart:io';
//import 'dart:math';

String readLineSync() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

enum Dir {RIGHT, UP, DOWN, LEFT}

late int w;
late int h;
late int playerCount;
late int myId;
late int nextId;

bool goalTestP0(int x, int y) => x == 8;
bool goalTestP1(int x, int y) => x == 0;
bool goalTestP2(int x, int y) => y == 8;
List goalTests = [goalTestP0, goalTestP1, goalTestP2];

// heuristic scores
typedef fScorer = int Function(int x, int y);
int fScoreP0(int x, int y) => 8 - x;
int fScoreP1(int x, int y) => x;
int fScoreP2(int x, int y) => 8 - y;
List<fScorer> fScores = [fScoreP0, fScoreP1, fScoreP2];

Stopwatch sw = new Stopwatch();


/**
 * Auto-generated code below aims at helping you parse
 * the standard input according to the problem statement.
 **/
void main() {
    List inputs;
    inputs = readLineSync().split(' ');
    w = int.parse(inputs[0]); // width of the board
    h = int.parse(inputs[1]); // height of the board
    playerCount = int.parse(inputs[2]); // number of players (2 or 3)
    myId = int.parse(inputs[3]); // id of my player (0 = 1st player, 1 = 2nd player, ...)
    nextId = (myId + 1) % playerCount;
    int round = 1;
    List<Wall> walls = [];
    // game loop
    sw.start();
    while (true) {
        Map<int, Player> players = {};
        walls.clear();
        for (int i = 0; i < playerCount; i++) {
            inputs = readLineSync().split(' ');
            int x = int.parse(inputs[0]); // x-coordinate of the player
            int y = int.parse(inputs[1]); // y-coordinate of the player
            int wallsLeft = int.parse(inputs[2]); // number of walls available for the player
            if(x != -1){
                players[i] = new Player(i, x, y, wallsLeft);
            }
        }
        
        int wallCount = int.parse(readLineSync()); // number of walls on the board
        for (int i = 0; i < wallCount; i++) {
            inputs = readLineSync().split(' ');
            int wallX = int.parse(inputs[0]); // x-coordinate of the wall
            int wallY = int.parse(inputs[1]); // y-coordinate of the wall
            String wallOrientation = inputs[2]; // wall orientation ('H' or 'V')
            
            walls.add(new Wall(wallX, wallY, wallOrientation == "V" ? true : false));
        }

        // Write an action using print()
        // To debug: stderr.writeln('Debug messages...');
        sw.reset();
        Player me = players[myId]!;
        
        stderr.writeln("Me: $me");
        stderr.writeln(players);
        stderr.writeln(walls);
        
        stderr.writeln("SW: ${sw.elapsed}");
        Game game = new Game(players, walls);
        stderr.writeln("Creating initial game: $game");
        stderr.writeln("SW: ${sw.elapsed}");
        
        List<Dir>? winningPathMe = game.winningPath(me.playerId);
        stderr.writeln("Winning Path for me: $winningPathMe");
        if (winningPathMe != null){
            print(winningPathMe.first.toString().substring(4) + " Can't lose!");
            continue;
        }
        
        if (walls.length > 2 && me.wallsLeft > 0){
            //try to finding winningWalls
            stderr.writeln("SW: ${sw.elapsed}");
            var result = game.winningWalls(myId);
            stderr.writeln("Winning walls: $result");
            if(result != null){
                print(result.first);
                continue;
            }

        }
        

        List<Dir>? myGoalPath = search(me, walls);
        stderr.writeln("myGoalPath $myGoalPath");
        if(myGoalPath == null){
            stderr.writeln("No goal path found at all!");
            stderr.writeln("SW: ${sw.elapsed}");
            print("UP");
        } else if(myGoalPath.length == 1 || me.wallsLeft == 0 || round < 3){
            stderr.writeln("Winning, skipping or no walls left!");
            stderr.writeln("SW: ${sw.elapsed}");
            print(myGoalPath.first.toString().substring(4));
        } else {
            List<Player> oppPlayers = players.values.where((p) => p.playerId != myId).toList();
            List<List<Dir>?> oppPaths = oppPlayers.map((p) => 
                search(p, walls)).toList();
            List<Dir> targetOppPath = oppPaths[0]!;
            int targetOppPathId = 0;
            if(oppPaths.length > 1){
                if(oppPaths[1]!.length < targetOppPath.length){
                    targetOppPath = oppPaths[1]!;
                    targetOppPathId = 1;
                }
            }
            stderr.writeln("Target Opp Path length: ${targetOppPath.length}");
            if(targetOppPath.length < myGoalPath.length) {
                Wall? blocker = findBlocker(game, targetOppPathId, targetOppPath, oppPlayers, walls);

                if(blocker != null){
                    stderr.writeln("Block with $blocker");
                    print("$blocker Blocking");
                } else if (oppPaths.length > 1){
                    targetOppPathId = targetOppPathId == 1 ? 0 : 1;
                    targetOppPath = oppPaths[1]!;
                    blocker = findBlocker(game, targetOppPathId, targetOppPath, oppPlayers, walls);
                    
                    if(blocker != null) {
                        stderr.writeln("Block with $blocker");
                        print("$blocker Blocking");
                    } else {
                        stderr.writeln("No valid blocker found");
                        print(myGoalPath.first.toString().substring(4) + " No Blocker");
                    }
                } else {
                    stderr.writeln("No valid blocker found");
                    print(myGoalPath.first.toString().substring(4) + " No Blocker");
                }
            } else {
                stderr.writeln("Closest to winning");
                // action: LEFT, RIGHT, UP, DOWN or "putX putY putOrientation" to place a wall
                String moveString = myGoalPath.first.toString().substring(4);
                print("$moveString I'm winning!");
            }
        }
        round++;
    }
}

Wall? findBlocker(Game game, int id, List<Dir> oppPath, List<Player> oppPlayers, List<Wall> walls){
    Wall? blocker;
    var opp = oppPlayers[id];
    stderr.writeln("Opp $opp has a shorter path: $oppPath");
    var oppPos = [opp.x, opp.y];
    var blockerAcc = [];
    for(int j = 0; j < oppPath.length; j++){
        blockerAcc.addAll(blockers(oppPos[0], oppPos[1], oppPath[j], walls));
        oppPos = pointToDir(opp.x, opp.y, oppPath[j]);
    }
    int maxLength = oppPath.length;
    stderr.writeln("Blockers: $blockerAcc");
    blockerAcc.forEach((b){
        List<Dir>? newPath = search( opp, walls..add(b));
        walls.removeLast();
        if(newPath != null && newPath.length > maxLength && game.playableWall(b)){
            maxLength = newPath.length;
            blocker = b;
        }
    });
    
    stderr.writeln("Result blocker: $blocker");
    
    return blocker;
}

List<Dir>? search(Player player, List<Wall> walls, {blockable = true}){
    int x = player.x;
    int y = player.y;
    int playerId = player.playerId;
    var goalTest = goalTests[playerId];
    
    List<List<int>> open = [[x, y]];
    List<List<int>> closed = [];
    
    assert(pointsContains(open, x, y));
    
    Map<int, List<Dir>> cameFrom = {x + y * w: []};
    Map<int, int> gScoreMap = {x + y * w: 0};
    Map<int, int> fScoreMap = {x + y * w: fScores[playerId](x, y) };
    
    // stderr.writeln("Search Start data playerId:$playerId");
    // stderr.writeln("open $open");
    // stderr.writeln("cameFrom $cameFrom");
    // stderr.writeln("gScoreMap $gScoreMap");
    // stderr.writeln("fScoreMap $fScoreMap");
    
    while(open.isNotEmpty){
        //TODO replace BFS/DFS with a*
        
        int? lowest;
        List<int> current = open[0];
        open.forEach((o) {
            int pos = o[0] + o[1] * w;
            if(lowest == null || fScoreMap[pos]! < lowest!){
                current = o;
                lowest = fScoreMap[pos];
            }
        });
        
        if(goalTest(current[0], current[1])){
            List<Dir> returnPath = cameFrom[current[0] + current[1] * w]!; 
            // stderr.writeln("Goal found! Returning Path length: ${returnPath.length}");
            return returnPath;
        }
        
        open.removeWhere((o) => 
            o[0] == current[0] && o[1] == current[1]);
    
        closed.add(current);
        
        Dir.values.expand((dir) {
            var neighbor = pointToDir(current[0], current[1], dir);
            var x = neighbor[0];
            var y = neighbor[1];
            if(x >= 0 && x < w &&
                y >= 0 && y < h &&
                canPass(current[0], current[1], dir, walls) &&
                (blockable || !canBeBlocked(current[0], current[1], dir, walls))
                ) {
                
                return [[dir, neighbor]];
            } else {
                return [];
            }
            
        }).forEach((dirNeighbor) {
            // stderr.writeln("Handling $dirNeighbor");
            var dir = dirNeighbor[0];
            var x = dirNeighbor[1][0];
            var y = dirNeighbor[1][1];
            if(pointsContains(closed, x, y)){
                return;
            }
            
            int tentative_gScore = gScoreMap[current[0] + current[1] * w]! + 1;
            
            if(!pointsContains(open, x, y)){
                //BFS add at the end
                open.add(dirNeighbor[1]);
            } else if (gScoreMap[x + y * w] != null && tentative_gScore >= gScoreMap[x + y * w]!){
                return;
            }
            
            //this is the best path to neighbor, record it!
            cameFrom[x + y * w] = new List.from(cameFrom[current[0] + current[1] * w]!)
                ..add(dir);
            gScoreMap[x + y * w] = tentative_gScore;
            fScoreMap[x + y * w] = tentative_gScore + fScores[playerId](x, y);
        });
        
    }
    
    // stderr.writeln("No path to goal found!");
    return null;
}

bool pointsContains(var points, int x, int y){
    return points.any((l) => l[0] == x && l[1] == y);
}

List<int> pointToDir(int x, int y, Dir dir){
    switch (dir){
        case Dir.UP:
            return [x, y - 1];
        case Dir.DOWN:
            return [x, y + 1];
        case Dir.LEFT:
            return [x - 1, y];
        case Dir.RIGHT:
            return [x + 1, y];
    }
}

bool canPass(int x, int y, Dir dir, List<Wall> walls){
    return !walls.any((wall){
        switch (dir){
            case Dir.UP:
                return !wall.isVertical &&
                    wall.wallY == y &&
                    (wall.wallX == x || wall.wallX == x - 1);
            case Dir.DOWN:
                return !wall.isVertical &&
                    wall.wallY == y + 1 &&
                    (wall.wallX == x || wall.wallX == x - 1);
            case Dir.LEFT:
                return wall.isVertical &&
                    wall.wallX == x &&
                    (wall.wallY == y || wall.wallY == y - 1);
            case Dir.RIGHT:
                return wall.isVertical &&
                    wall.wallX == x + 1 &&
                    (wall.wallY == y || wall.wallY == y - 1);
        }
    });
}

bool canBeBlocked(int x, int y, Dir dir, List<Wall> walls){
    return blockers(x, y, dir, walls).isNotEmpty;
}

List<Wall> blockers(int x, int y, Dir dir, List<Wall> walls){
    var results = <Wall>[];
    switch(dir){
        case Dir.UP:
            if(x < 8)
                results.add(new Wall(x, y, false));
            if(x > 0)
                results.add(new Wall(x - 1, y, false));
            break;
        case Dir.DOWN:
            if(x < 8)
                results.add(new Wall(x, y + 1, false));
            if(x > 0)
                results.add(new Wall(x - 1, y + 1, false));
            break;
        case Dir.LEFT:
            if(y < 8)
                results.add(new Wall(x, y, true));
            if(y > 0)
                results.add(new Wall(x, y - 1, true));
            break;
        case Dir.RIGHT:
            if(y < 8)
                results.add(new Wall(x + 1, y, true));
            if(y > 0)
                results.add(new Wall(x + 1, y - 1, true));
            break;
    }
    return results.where((w) => legalWall(w, walls)).toList();
}

bool legalWall(Wall wall, List<Wall> walls){
    // stderr.writeln("Testing $wall vs. $walls");
    if(walls.contains(wall)) return false;
    
    switch(wall.isVertical){
        case true:
            return !walls.any((w) => 
                (w.isVertical && w.wallX == wall.wallX &&
                (w.wallY == wall.wallY - 1 ||
                w.wallY == wall.wallY + 1)) || 
                (!w.isVertical && w.wallX == wall.wallX - 1 &&
                w.wallY == wall.wallY + 1)
                );
        case false:
            return !walls.any((w) => 
                (!w.isVertical && w.wallY == wall.wallY &&
                (w.wallX == wall.wallX - 1 ||
                w.wallX == wall.wallX + 1)) ||
                (w.isVertical && w.wallX == wall.wallX + 1 &&
                w.wallY == wall.wallY - 1)
                );
        default:
          return false;
        
    }
}

class Player {
    int playerId;
    int x;
    int y;
    int wallsLeft;
    
    Player(this.playerId, this.x, this.y, this.wallsLeft);
    
    String toString() => "Id:$playerId Loc:[$x,$y] Walls:$wallsLeft";
    
}

class Wall {
    final int wallX;
    final int wallY;
    final bool isVertical;
    
    const Wall(this.wallX, this.wallY, this.isVertical);
    
    String toString() => "$wallX $wallY ${isVertical ? 'V' : 'H'}";
    
    // Override hashCode using strategy from Effective Java,
    // Chapter 11.
    int get hashCode {
        int result = 17;
        result = 37 * result + wallX;
        result = 37 * result + wallY;
        if(isVertical){
            result = 17 * result;
        }
        return result;
    }

    // You should generally implement operator == if you
    // override hashCode.
    bool operator ==(other) {
        if (other is! Wall) return false;
        
        return (other.wallX == wallX &&
            other.wallY == wallY &&
            other.isVertical == isVertical);
    }
}

class Game {
    Map<int, Player> players;
    List<Wall> walls;
    List<Wall> possibleWalls = [];
    
    Game(this.players, this.walls){
        buildPossibleWalls();
    }
    
    String toString() => "Player Count: ${players.keys.length} Wall Count: ${walls.length} Possible Wall Count ${possibleWalls.length}";
    
    void buildPossibleWalls(){
        //from 1,0 to 8, 7
        for(int i = 1; i < w; i++){
            for(int j = 0; j < h - 1; j++){
                possibleWalls.add(new Wall(i, j, true));
            }
            
        }
        
        //from 0,1 to 7, 8
        for(int i = 0; i < w - 1; i++){
            for(int j = 1; j < h; j++){
                possibleWalls.add(new Wall(i, j, false));
            }
        }
        
        //test all walls
        possibleWalls.removeWhere((w) => walls.contains(w));
        possibleWalls.removeWhere((w) => !playableWall(w));
        
        // stderr.writeln("Possible walls (${possibleWalls.length}): $possibleWalls");
    }
    
    bool playableWall(Wall wall){
        bool legalPlacement = legalWall(wall, walls);
        if (!legalPlacement) return false;
        
        //ensure all players can still reach their goal
        walls.add(wall);
        bool result = players.values.any((p) => search(p, walls) == null);
        walls.removeLast();
        return !result;
        
    }
    
    List<Dir>? winningPath(int id){
        //player id has winning position if their path is the shortest
        //or tied for shortest, and no wall placement can make it worse
        Map paths = {};
        bool wallsLeft = players.values.any((p) => p.playerId != id && p.wallsLeft > 0);
        if(wallsLeft){
            paths[id] = search(players[id]!, walls, blockable: false);
            if(paths[id] == null){
                return null;
            }
        }
        players.values.forEach((p){
            if(p.playerId != id || !wallsLeft){
                paths[p.playerId] = search(p, walls);
            }
        });
        
        var shortestPath = paths.values.reduce((a, b) => a.length <= b.length ? a : b);
        
        if(paths[id].length > shortestPath.length){
            return null;
        }
        
        return paths[id];
    }
    
    List<Wall>? winningWalls(int id){
        Player player = players[id]!;
        
        if(player.wallsLeft == 0){
            return null;
        }
        
        var result = winningWallsRec(<Wall>[], player, 0);
        return result;
    }
    
    List<Wall>? winningWallsRec(List<Wall> acc, Player player, int depth){
        // stderr.writeln("WinWallsRec acc:$acc Depth:$depth SW: ${sw.elapsedMilliseconds}");
        if(depth > 0 || depth > player.wallsLeft){
            //hit max depth without a solution
            return null;
        }
        
        var result = null;
        
        for(Wall w in possibleWalls){
            if(acc.contains(w) || !playableWall(w)){
                continue;
            }
            walls.add(w);
            acc.add(w);
            if(winningPath(player.playerId) != null){
                walls.remove(w);
                return acc;
            } else {
                var recurse = winningWallsRec(acc, player, depth + 1);
                if(recurse == null){
                   acc.remove(w);
                   walls.remove(w);
                   continue;
                } else {
                   walls.remove(w);
                   stderr.writeln("Winning Wall Combo found: $acc!!!");
                   return recurse;
                }
            }
        }
        
        return null;
        
    }
}