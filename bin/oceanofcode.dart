import 'dart:io';
import 'dart:math';

String readLineSync() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

Random rand = new Random(0);

late int WIDTH;
late int HEIGHT;
late int myId;
late Me me;

enum Cell {ocean, land}
enum Dir {N, E, S, W}

/**
 * Auto-generated code below aims at helping you parse
 * the standard input according to the problem statement.
 **/
void main() {
    List inputs;
    inputs = readLineSync().split(' ');
    WIDTH = int.parse(inputs[0]);
    HEIGHT = int.parse(inputs[1]);
    myId = int.parse(inputs[2]);
    
    Board board = new Board();
    
    for (int i = 0; i < HEIGHT; i++) {
        String line = readLineSync();
        // stderr.writeln('Line: $line');
        for(int j = 0; j < line.length; j++){
            //check for land at index j
            if(line[j] == "x"){
                // stderr.writeln('Replacing board [$j][$i] with land.');
                board.cells[j][i] = Cell.land;
                
            }
        }
    }

    // Write an action using print()
    // To debug: stderr.writeln('Debug messages...');
    stderr.writeln('Dart Platform Version: ${Platform.version}');
    // stderr.writeln('Initial board:');
    // stderr.writeln('${board}');
    
    myAssert(new Point(0,0) == new Point(0,0), "Two points should be equal");
    board.computeNeighbors();
    
    Point? start = null;
    for(int x = 0; x < WIDTH; x++){
        for(int y = HEIGHT - 1; y >= 0; y--){
            if (board.cellAt(new Point (x, y)) == Cell.ocean){
                start = new Point (x, y);
                break;
            }
        }
        if (start != null)
            break;
    }
    
    
    stderr.writeln("Cell at final start $start ${board.cellAt(start!)}");
    
    me = new Me(myId, start);

    print("${start.x} ${start.y}");

    // game loop
    while (true) {
        inputs = readLineSync().split(' ');
        int x = int.parse(inputs[0]);
        int y = int.parse(inputs[1]);
        me.myLife = int.parse(inputs[2]);
        int oppLife = int.parse(inputs[3]);
        int torpedoCooldown = int.parse(inputs[4]);
        int sonarCooldown = int.parse(inputs[5]);
        int silenceCooldown = int.parse(inputs[6]);
        int mineCooldown = int.parse(inputs[7]);
        String sonarResult = readLineSync();
        String opponentOrders = readLineSync();

        // Write an action using print()
        // To debug: stderr.writeln('Debug messages...');
        
        me.current = new Point(x, y);
        me.path.add(me.current);
        assert(me.path.contains(me.current));
        stderr.writeln("Path contains current: ${me.path.contains(me.current)}");
        assert(me.path.contains(start));
        stderr.writeln("Path contains start: ${me.path.contains(start)}");
        
        
        
        stderr.writeln("Current Point ${me.current}");
        stderr.writeln("Current path: ${me.path}");
        Map<Dir, Point> neighbors = new Map.from(board.getNeighbors(me.current));
        neighbors.removeWhere((d, p) => me.path.contains(p));
        stderr.writeln("Possible neighbors after remove: $neighbors");
        
        if(neighbors.keys.length > 0){
            Dir selected = neighbors.keys.first;
            stderr.writeln("Selected: $selected");
            print('MOVE ${selected.toString().substring(4)} TORPEDO');
        } else {
            stderr.writeln("No moves, have to surface");
            print('SURFACE');
            me.path.clear();
            
        }
        

    }
}

void myAssert(bool test, String message){
    if(!test){
        stderr.writeln("AssertionError: $message");
        throw new AssertionError(message);
    }
}

class Point {
    final int x;
    final int y;
    
    static late final List<Point> _cache;
    static bool _cacheInitialized = false;
      
    factory Point.fromId(int id) {
      if(!_cacheInitialized){
        _cache = List.generate(HEIGHT * WIDTH, (int idx) =>
          Point.internal( idx % WIDTH, idx ~/ HEIGHT));
        _cacheInitialized = true;
      }
      return _cache[id];

    }

    factory Point(int x, int y) {
      if(!_cacheInitialized){
        _cache = List.generate(HEIGHT * WIDTH, (int idx) =>
          Point.internal( idx % WIDTH, idx ~/ HEIGHT));
        _cacheInitialized = true;
      }
      return _cache[x * HEIGHT + y];
    }
    
    Point.internal(this.x, this.y);
    
    String toString() => "[$x][$y]";

    int get id => x * HEIGHT + y;
}

class Board {
    late List<List<Cell>> cells;
    late List<Map<Dir,Point>> neighbors;
    
    Board() {
        stderr.writeln('Constructing new board');
        cells = new List<List<Cell>>.generate(WIDTH,
            (i) => new List<Cell>.generate(HEIGHT, (j) => Cell.ocean));
        // stderr.writeln('Cells: $cells');
        
    }
    void computeNeighbors(){
        neighbors = List.generate(WIDTH * HEIGHT, 
          (int idx) => {Dir.N: Point(0, 0)}, growable: false);
        
        for(int i = 0; i < WIDTH * HEIGHT; i++){
            Point p = Point.fromId(i);
            //stderr.writeln("Compute neighbors for $p");
            neighbors[i] = new Map<Dir, Point>();
            Dir.values.forEach((d){
            switch(d){
                case Dir.N:
                    if(p.y > 0 && cellAt(new Point(p.x, p.y - 1)) != Cell.land){
                        neighbors[i][d] = new Point(p.x, p.y - 1);
                    }
                    break;
                case Dir.E:
                    if(p.x < WIDTH - 1 && cellAt(new Point(p.x + 1, p.y)) != Cell.land){
                        neighbors[i][d] = new Point(p.x + 1, p.y);
                    }
                    break;
                case Dir.S:
                    if(p.y < HEIGHT - 1 && cellAt(new Point(p.x, p.y + 1)) != Cell.land){
                        neighbors[i][d] = new Point(p.x, p.y + 1);
                    }
                    break;
                case Dir.W:
                    if(p.x > 0 && cellAt(new Point(p.x - 1, p.y)) != Cell.land){
                        neighbors[i][d] = new Point(p.x - 1, p.y);
                    }
                    break;
            }});
        }
    }
    
    
    Cell cellAt(Point p){
        return cells[p.x][p.y];
    }
    
    Map<Dir, Point> getNeighbors(Point p){
        return neighbors[p.id];
    }
    
    String toString(){
        String result = "";
        for (int y = 0; y < HEIGHT; y++){
            for(int x = 0; x < WIDTH; x++){
                switch(cells[x][y]){
                    case Cell.ocean:
                        result += ".";
                        break;
                    case Cell.land:
                        result += "x";
                        break;
                        
                }
            }
            result += "\n";
        }
        
        return result;
    }
}

class Me {
    Point current;
    final int myId;
    final List<Point> path = <Point>[];
    int myLife = 6;
    
    Me(this.myId, this.current){
    }
}