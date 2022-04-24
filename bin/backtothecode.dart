import 'dart:io';
import 'dart:math';

String readLineSync() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

final int H = 20;
final int W = 35;
int N = 0;
Random rand = new Random(6);
final int FIRST_TIMEOUT = 990;
final int TIMEOUT = 90;
// initialize to field of -1s
List<int> rows = new List.generate(H * W, ((index) => -1));
int dirIndex = 0;

int NEUTRAL = -1;
int myId = 0;
    
void main() {
    List inputs;
    int opponentCount = int.parse(readLineSync()); // Opponent count
    N = 1 + opponentCount;

    Dir dir = Dir.up;
    
    Grid grid = new Grid();
    grid.players = new List.generate(N, (n) => new Player(n));
    late Point myStart;
    late Point corner;
    bool cornerReached = false;
    bool startReached = false;
    
    // game loop
    while (true) {
        int gameRound = int.parse(readLineSync());
        for (int i = 0; i < N; i++) {
            inputs = readLineSync().split(' ');
            grid.players[i].pos.x = int.parse(inputs[0]);
            grid.players[i].pos.y = int.parse(inputs[1]);
            grid.players[i].backInTimeLeft = int.parse(inputs[2]);
            if (grid.players[i].pos.x == -1 && grid.players[i].pos.y == -1){
                grid.players[i].alive = false;
            }
            
        }
        //rows = [];
        for (int i = 0; i < 20; i++) {
            // One line of the map ('.' = free, '0' = you, otherwise the id of the opponent)
            String row = readLineSync();
            for(int j = 0; j < row.length; j++){
                int cell = row[j] == "." ? -1 : int.parse(row[j]);
                grid.setCell(j, i, cell);
            }
            
        }
        
        grid.updateVorMap();
        
        stderr.writeln("GameRound $gameRound");
        
        assert(new Box.corners(new Point(0, 0), new Point(5,5)) ==
            new Box.corners(new Point(5, 0), new Point(0, 5)));
        
        Box bigBox = grid.biggestClosableInVorMap(0);
        
        // grid.printCells();
        if(gameRound == 1){
            myStart = new Point(grid.players[0].pos.x, 
                grid.players[0].pos.y);
            if (myStart.x < 18) {
                if (myStart.y < 10) {
                    corner = new Point(0, 0);
                } else {
                    corner = new Point(0, 19);
                }
            } else {
                if (myStart.y < 10) {
                    corner = new Point(34, 0);
                } else {
                    corner = new Point(34, 19);
                }
            }
            
            if(corner.x == myStart.x || corner.y == myStart.y){
                cornerReached = true;
                startReached = true;
            }
            
            stderr.writeln("Heading to $corner from $myStart");
        }
        
        if(grid.players[0].pos == corner){
            cornerReached = true;
        }
        
        if(cornerReached && grid.players[0].pos.validNeighbors().contains(myStart)){
            startReached = true;
        }
        
        if(!cornerReached){
            print("${corner.x} ${corner.y}");
        } else if( cornerReached && !startReached) {
            print("${myStart.x} ${myStart.y}");
        } else {
            //try voronoi and closest neutral
            Point? myVor = grid.voronoiNeighbor(0);
            
            if(myVor != null){
                stderr.writeln("Using Player 0 vor point: $myVor");
                print("${myVor.x} ${myVor.y}");
                
            } else {
                Point? clsNeutral = bfsNeutral(grid, grid.players[0].pos);
                stderr.writeln("Closest neutral to ${grid.players[0].pos} ${clsNeutral}");
                
                // action: "x y" to move or "BACK rounds" to go back in time
                if(clsNeutral != null){
                    print("${clsNeutral.x} ${clsNeutral.y}");
                } else {
                    print("${myStart.x} ${myStart.y}");
                }
            }
        }
    }
}

enum Dir {up, right, down, left}

Dir nextDir(Dir dir){
    return Dir.values[(dir.index + 1) % 4];
}

bool intoWall(Dir dir, Point pos){
    if (dir == Dir.up && pos.y == 0){
        return true;
    }
    if (dir == Dir.down && pos.y == 19){
        return true;
    }
    if (dir == Dir.left && pos.x == 0){
        return true;
    }
    if (dir == Dir.right && pos.x == 34){
        return true;
    }    
    return false;
}

class Point {
    int x;
    int y;
    Point(this.x, this.y);
    
    String toString() { return "{$x,$y}"; }
    
    List<Point> validNeighbors(){
        return Dir.values
            .map(this.moveDirInvertedY)
            .where((p) => p.isValid).toList();
    }
    
    bool get isValid {
        return y>=0 && y<H && x>=0 && x<W;
    }
    
    //manhattan distance
    num distanceTo(Point other) {
        var dx = (x - other.x).abs();
        var dy = (y - other.y).abs();
        return dx + dy;
    }
    
    Point moveDirInvertedY(Dir dir){
        switch (dir){
            case Dir.up:
                return new Point(x, y - 1);
                break;
            case Dir.down:
                return new Point(x, y + 1);
                break;
            case Dir.left:
                return new Point(x - 1, y);
                break;
            case Dir.right:
                return new Point(x + 1, y);
            default:
                return this;
                break;
        }
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

class Grid {
    List<Player> players = [];
    List<int> rows = new List.generate(H * W, ((index) => -1));
    
    late Grid previousGrid;
    
    Map<Point, int> vorMap = {};
    
    Grid(){
        
    }
    void setCell(int x, int y, int cell){
        rows[x + y * W] = cell;
    }
    
    int cellAt(int x, int y){
        return rows[x + y * W];
    }
    
    void updateVorMap(){
        for (int y = 0; y < 20; y++) {
            for (int x = 0; x < 35; x++) {
                if (cellAt(x, y) == NEUTRAL) {
                    var distances = players
                    .map((p) => (p.pos.x - x).abs() + (p.pos.y - y).abs()).toList();
                    // stderr.writeln("Neutral: $x, $y distances: $distances");
                    int? best;
                    late int dist;
                    for(int id = 0; id < players.length; id++){
                        if(best == null || distances[id] < dist){
                            dist = distances[id];
                            best = id;
                        } else if (dist == distances[id]){
                            best = -1;
                        }
                    }
                    if(best! >= 0){
                        // stderr.writeln("Best $best Neutral: $x, $y distances: $distances");
                        vorMap[new Point(x, y)] = best;
                    }
                } else {
                    //cellAt(x, y) is not neutral
                    vorMap[new Point(x, y)] = -1;
                }
            }
        }
    }
    
    Box biggestClosableInVorMap(int playerId){
        updateVorMap();
        
        Point? bfs = bfsNeutral(this, players[playerId].pos);
        Box startBox = new Box.corners(new Point(bfs!.x - 1, bfs.y - 1), 
        new Point(bfs.x + 1, bfs.y + 1));
        stderr.writeln("Starting box search with $startBox");
        
        return startBox;
    }
    
    bool closableBox(Box box, int playerId){
        return closableBoxIntCheck(box, playerId);
    }
    
    bool closableBoxIntCheck(Box box, int playerId){
        //test interior is completely neutral
        for(int x = box.leftX + 1; x < box.rightX; x++){
            for(int y = box.topY + 1; y < box.bottomY; y++){
                if(cellAt(x, y) != NEUTRAL){
                    return false;
                }
            }
        }
        return true;
    }
    
    bool closableBoxExtCheck(Box box, int playerId){
        bool closable = false;
        //test outer boundary for (playerid or neutral) and in vormap
        
        return closable;
    }
    
    Point? voronoiNeighbor(int playerId){
        var valids = players[playerId].pos.validNeighbors();
        var neutrals = valids.where((v) => cellAt(v.x, v.y) == NEUTRAL).toList();
        stderr.writeln("Neutrals for $playerId $neutrals");
        if(neutrals.length == 0){
            return null;
        }
        if(neutrals.length == 1){
            return neutrals.first;
        }
        
        int origX = players[playerId].pos.x;
        int origY = players[playerId].pos.y;
        
        Map<Point, List<int>> vorMap = {};
        for(Point neutral in neutrals){
            vorMap[neutral] = new List.generate(players.length, (p) => 0);
            players[playerId].pos.x = neutral.x;
            players[playerId].pos.y = neutral.y;
            for (int y = 0; y < 20; y++) {
                for (int x = 0; x < 35; x++) {
                    if (cellAt(x, y) == NEUTRAL) {
                        var distances = players
                        .map((p) => (p.pos.x - x).abs() + (p.pos.y - y).abs()).toList();
                        // stderr.writeln("Neutral: $x, $y distances: $distances");
                        int? best;
                        late int dist;
                        for(int id = 0; id < players.length; id++){
                            if(best == null || distances[id] < dist){
                                dist = distances[id];
                                best = id;
                            } else if (dist == distances[id]){
                                best = -1;
                            }
                        }
                        if(best! >= 0){
                            // stderr.writeln("Best $best Neutral: $x, $y distances: $distances");
                            vorMap[neutral]![best]++;
                        }
                    }
                }
            }
        }
        
        stderr.writeln("Vormap for $playerId: $vorMap");
        players[playerId].pos.x = origX;
        players[playerId].pos.y = origY;
        
        Point? result;
        for(Point neutral in neutrals){
            if(result == null || vorMap[neutral]![playerId] > vorMap[result]![playerId]){
                result = neutral;
            }
        }
        
        return result;
        
    }
    
    void printCells(){
        stderr.writeln(">>>00000000001111111111222222222233333<<<");
        stderr.writeln(">>>01234567890123456789012345678901234<<<");
        stderr.writeln(">>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<");
        List<String> output = new List.generate(H, (h) =>
        " " * W);
        
        String ownerChars  = "0123";
        String playerChars = "4567";
        
        for (int y = 0; y < 20; y++) {
            for (int x = 0; x < 35; x++) {
                int owner = cellAt(x, y);
                String c = owner==NEUTRAL ? '=' : '\$';
                if (owner>=0) {
                    c = ownerChars[owner];
                }
                output[y] = output[y].replaceRange(x, x+1, c);
            }
        }
        
        for (int y = 0; y < 20; y++) {
            stderr.writeln(y.toString().padLeft(2) + ">${output[y]}<" + y.toString().padLeft(2));
        }
        
        
        stderr.writeln(">>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<");
        stderr.writeln(">>>01234567890123456789012345678901234<<<");
        stderr.writeln(">>>00000000001111111111222222222233333<<<");
    
    }

}

class Player {
    int id;
    Point pos = new Point (-1, -1);
    int backInTimeLeft = 1;
    late Dir direction;
    late Dir lastTurn; //Left or Right
    int score = 0;
    bool alive = true;
    
    Player(this.id);
}

class Box {
    late int leftX;
    late int rightX;
    late int topY;
    late int bottomY;
    Box(this.leftX, this.rightX, this.topY, this.bottomY);
    
    Box.corners(Point corner1, Point corner2){
        leftX = min(corner1.x, corner2.x);
        rightX = max(corner1.x, corner2.x);
        topY = min(corner1.y, corner2.y);
        bottomY = max(corner1.y, corner2.y);
    }
    
    String toString() => "[$leftX, $topY] - [$rightX, $bottomY]";
    
    // Override hashCode using strategy from Effective Java,
    // Chapter 11.
    int get hashCode {
        int result = 17;
        result = 37 * result + leftX;
        result = 37 * result + rightX;
        result = 37 * result + topY;
        result = 37 * result + bottomY;
        return result;
    }
    
    // You should generally implement operator == if you
    // override hashCode.
    bool operator ==(other) {
        if (other is! Box) return false;
        Box box = other;
        return 
            box.leftX == leftX &&
            box.rightX == rightX &&
            box.topY == topY &&
            box.bottomY == bottomY;
    }
    
}

Point? bfsNeutral(Grid grid, Point p){
    // if(cellAt(p.x, p.y) < 0){
    //     return p;
    // }
    List<Point> open = [p];
    List<Point> closed = [];
    while(open.length > 0){
        Point first = open.removeAt(0);
        closed.add(first);
        
        List<Point> neighbors = openNeighbors(first).
        where((neighbor) => !closed.contains(neighbor)).
        where((neighbor) => !open.contains(neighbor)).toList();
        
        for(Point neighbor in neighbors){
            int cell = grid.cellAt(neighbor.x, neighbor.y);
            if(cell < 0){
                return neighbor;
            } else {
                open.add(neighbor);
            }
        }
    }
    return null;
}

List<Point> openNeighbors(Point pos){
    int x = pos.x;
    int y = pos.y;
    List<Point> valids = [];
    List<List<int>> poss = [[x+1,y], [x,y+1], [x-1,y], [x,y-1]];
    //stderr.writeln("$poss");
    poss.shuffle(rand);
    for(int i = 0; i < 4; i ++) {
        var pos = poss[i];
        if(pos[0] >= 0 && pos[0] < W &&
            pos[1] >= 0 && pos[1] < H ) {
            valids.add(new Point(pos[0], pos[1]));
        }
    }
    dirIndex++;
    if (dirIndex > 3){
        dirIndex = 0;
    }
    return valids;
}


