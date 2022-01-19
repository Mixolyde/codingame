import 'dart:collection';
import 'dart:io';
import 'dart:math';

String readLineSync() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

List<Buster> myBusters = [];
List<Buster> oppBusters = [];
List<Ghost> ghosts = [];
Map<int, Ghost> seen = {};
Map<int, Point> explorePoints = {};

late Point home;
late int bustersPerPlayer;
late int ghostCount;
late int myTeamId;
int wallId = 0;
Random rand = new Random();
late List<int> xs;
late List<int> ys;

//grid of 2000x2000 blocks
int gridWidth = 8;
int gridHeight = 4;
List<List<bool>> explored = new List.generate(gridWidth, 
    (index) => new List.filled(gridHeight, false));

List<List<int>> exploreDirs = [[1, 1], [0, 1], [1, 0], [-1, 1],
    [1, -1], [-1, 0], [0, -1], [-1, -1]];
    
enum Command {move, release, stun, bust}

/**
 * Send your busters out into the fog to trap ghosts and bring them home!
 **/
void main() {
    List inputs;
    bustersPerPlayer = int.parse(readLineSync()); // the amount of busters you control
    ghostCount = int.parse(readLineSync()); // the amount of ghosts on the map
    myTeamId = int.parse(readLineSync()); // if this is 0, your base is on the top left of the map, if it is one, on the bottom right
    
    explored[0][0] = true;
    explored[1][0] = true;
    explored[0][1] = true;
    explored[gridWidth - 1][gridHeight - 1] = true;
    explored[gridWidth - 2][gridHeight - 1] = true;
    explored[gridWidth - 1][gridHeight - 2] = true;

    if(myTeamId == 0){
        home = new Point(1130, 1130);
        xs = new List.generate(
            gridWidth, (index) => gridWidth - 1 - index );
        ys = new List.generate(
            gridHeight, (index) => gridHeight - 1 - index );
    } else {
        home = new Point(16001 - 1130, 9001 - 1130);
        xs = new List.generate(
            gridWidth, (index) => index);
        ys = new List.generate(
            gridHeight, (index) => index);
        exploreDirs = exploreDirs.reversed.toList();   
    }
               
    for(int i = 0; i < bustersPerPlayer; i++) {
        int id = i + bustersPerPlayer * myTeamId;
        myBusters.add(new Buster(id, myTeamId, 
            new Point(16000 * myTeamId, 9000* myTeamId), 
            0, -1));        
    }
    // game loop
    while (true) {
        int entities = int.parse(readLineSync()); // the number of busters and ghosts visible to you
        // stderr.writeln("$entities entities visible");
        oppBusters.clear();
        ghosts.clear();
        
        for (int i = 0; i < entities; i++) {
            inputs = readLineSync().split(' ');
            int entityId = int.parse(inputs[0]); // buster id or ghost id
            int x = int.parse(inputs[1]);
            int y = int.parse(inputs[2]); // position of this buster / ghost
            int entityType = int.parse(inputs[3]); // the team id if it is a buster, -1 if it is a ghost.
            // For busters: 0=idle, 1=carrying a ghost, 2=stunned, 3=busting a ghost
            int state = int.parse(inputs[4]); 
            int value = int.parse(inputs[5]); // For busters: Ghost id being carried. For ghosts: number of busters attempting to trap this ghost.
            
            //parse inputs, update data
            switch (entityType) {
                case -1:
                    //TODO account for symmetry of newly discovered ghosts
                    // stderr.writeln("Ghost sighting $entityId");
                    Ghost g = new Ghost(entityId, new Point(x, y), state, value);
                    ghosts.add(g);
                    // seen[entityId] = g;
                    seen.remove(entityId);
                    break;
                default:
                    if(entityType == myTeamId){
                        int index = entityId - bustersPerPlayer * myTeamId;
                        explored[(min(x, 15999)/2000).floor()]
                            [(min(y, 7999)/2000).floor()] = true;
                        myBusters[index].update(new Point(x, y), 
                            state, value);
                        if(value > -1){
                            seen.remove(value);
                        }
                    } else {
                        oppBusters.add(new Buster(entityId, entityType, new Point(x, y), state, value));
                        if(value > -1){
                            seen.remove(value);
                        }
                    }
                    break;
            }
        }
        
        //print debug data
        stderr.writeln("Visible Ghosts");
        printGhosts(ghosts);
        stderr.writeln("My Team");
        printBusters(myBusters);
        stderr.writeln("Opp Team");
        printBusters(oppBusters);
        stderr.writeln("Seen $seen");
        
        // basic default decide command
        for (int i = 0; i < bustersPerPlayer; i++) {
            Buster current = myBusters[i];
            defaultRole(current);
            
        } //for decision loop
        
        //meta decision loop
        
        //update seen
        ghosts.forEach((ghost) => seen[ghost.id] = ghost);
        
        //print commands
        for (int i = 0; i < bustersPerPlayer; i++) {
            Buster current = myBusters[i];
            current.printCommand();
        }
    }
}

void defaultRole(Buster current){
    // stderr.writeln("${current.id} is deciding standard role");

    if(current.hasGhost){
        num distHome = current.point.distanceTo(home);
        //if in range, relase
        if(distHome < 1){
            current.command = Command.release;
            stderr.writeln("${current.id} has ghost at home, releasing");
            return;
        } else {
            //else go home
            stderr.writeln("${current.id} has ghost, heading to $home");
            current.command = Command.move;
            current.targetPoint = home;
            return;
        }
    } 
    
    //else look for stun target
    if(current.canStun){
        for(Buster opp in 
            oppBusters.where((buster) => 
            buster.hasGhost && !buster.stunTarget)){
                
            num dist = current.point.distanceTo(opp.point);
            if(dist < 1760){
                stderr.writeln("${current.id} is stunning ${opp.id}");
                current.command = Command.stun;
                current.targetId = opp.id;
                opp.stunTarget = true;
                current.tilStun = 0;
                return;
            }
            
        }
        
        for(Buster opp in 
            oppBusters.where((buster) => 
            !buster.hasGhost && !buster.stunTarget)){
                
            num dist = current.point.distanceTo(opp.point);
            if(dist < 1760){
                stderr.writeln("${current.id} is stunning ${opp.id}");
                current.command = Command.stun;
                current.targetId = opp.id;
                opp.stunTarget = true;
                current.tilStun = 0;
                return;
            }
            
        }
    }
    
    //if in range of ghost, bust it
    Map<num, Ghost> sortedGhosts = 
        ghostsByDistance(current.point, ghosts);
    for(num dist in sortedGhosts.keys){
        Ghost ghost = sortedGhosts[dist]!;
        //prioritize busting
        if(dist >= 900 && dist < 1760 && ghost.myBusters < 2){
            stderr.writeln("${current.id} in range of ghost, busting ${ghost.id}");
            current.command = Command.bust;
            current.targetId = ghost.id;
            ghost.myBusters++;
            return;
        }
    }
    
    if(sortedGhosts.isNotEmpty){
        num dist = sortedGhosts.keys.first;
        Ghost ghost = sortedGhosts[dist]!;
        if(dist < 900 && ghost.myBusters == 0){
            stderr.writeln("${current.id} is too close to ghost ${ghost.id}!");
            current.command = Command.move;
            current.targetPoint = current.point;
            return;
        } else if( ghost.myBusters < 2){
            stderr.writeln("${current.id} is moving to visible ghost ${ghost.id}!");
            current.command = Command.move;
            current.targetPoint = ghost.point;
            return;
        } 
    }
    
    if(seen.isNotEmpty){
        //no ghost in range check in seen map
        //move to closest ghost
        Map<num, Ghost> sortedGhosts = 
            ghostsByDistance(current.point, seen.values.toList());
        for(num dist in sortedGhosts.keys){
            Ghost target = sortedGhosts[dist]!;
            if(dist > 1500){
                stderr.writeln("${current.id} is moving toward seen ghost ${target.id}");
                current.command = Command.move;
                current.targetPoint = target.point;
                return;
            } else {
                stderr.writeln("Assume Ghost ${target.id} captured by opp");
                seen.remove(target.id);
            }
        }
    } 
    explore(current);
}

void explore(Buster current){
    //TODO multiple explorers on the same turn should not get
    //the same destination
    int id = current.id;
    if(explorePoints[id] == null || current.point.distanceTo(explorePoints[id]!) < 2000){
        stderr.writeln("Generating a new explore location");
        if(unexploredLeft()){
            Point? bfsPoint = bfs(current.point);
            if(bfsPoint != null){
                int x = bfsPoint.x;
                int y = bfsPoint.y;
                stderr.writeln("${id} New explore point $x $y");
                explorePoints[id] = new Point(x, y);
                current.command = Command.move;
                current.targetPoint = new Point(x, y);
                return;
            }
        } 
        
        //nothing unexplored, generate randomly 
        late int y;
        late int x;
        switch(wallId){
            case 0:
                y = 9000 - (9000 * myTeamId);
                x = rand.nextInt(16001);
                break;
            case 1:
                y = rand.nextInt(9001);
                x = 16000 - (16000 * myTeamId);
                break;
        }
        
        stderr.writeln("${id} New explore point $wallId $x $y");
        explorePoints[id] = new Point(x, y);
        wallId = (wallId + 1) % 2;
        current.command = Command.move;
        current.targetPoint = new Point(x, y);
        
    } else {
        Point exp = explorePoints[id]!;
        stderr.writeln("${id} prev explore point $exp");
        current.command = Command.move;
        current.targetPoint = exp;
    }
}

Point? bfs(Point bfsPoint){
    List<Point> open = [
        new Point((min(bfsPoint.x, 15999) / 2000).floor(), 
        (min(bfsPoint.y, 7999) / 2000).floor())];
    List<Point> closed = [];
    while(open.isNotEmpty){
        Point current = open.removeAt(0);
        if(explored[current.x][current.y] == false){
            explored[current.x][current.y] == true;
            return fromExplored(current.x, current.y);
        }
        
        closed.add(current);
        exploreDirs.forEach((dirs) => 
            ifValidAdd(current.x + dirs[0], 
                current.y + dirs[1], closed, open)
        );
        
    }
    return null;
    
}

bool unexploredLeft(){
    for(List<bool> bools in explored){
        if(bools.any((item) => !item)){
            return true;
        }
    }
    return false;
}

Point fromExplored(int i, int j){
    int x = i * 2000 + 1000;
    int y = j * 2000 + 1000;
    return new Point(x, y);
}

bool validGrid(int x, int y){
    return x >= 0 && y >= 0 &&
    x < gridWidth && y < gridHeight;
}

void ifValidAdd(int x, int y, List<Point> closed, List<Point> open){
    Point valid = new Point(x, y);
    if(validGrid(x, y) && !closed.contains(valid)){
        open.add(valid);
    }
}

Map<num, Ghost> ghostsByDistance(Point from, List<Ghost> ghosts){
    Map<num, Ghost> distMap = new SplayTreeMap<num, Ghost>();
    ghosts.forEach((ghost) => distMap[from.distanceTo(ghost.point)] = ghost);
    return distMap;
}
printGhosts(List<Ghost> ghosts){
    if(ghosts.length > 0){
        stderr.writeln(" ID|   X   |   Y   | B| S");
    }
    String id;
    String x;
    String y;
    String bc;
    String st;
    for(Ghost ghost in ghosts){
        id = ghost.id.toString().padLeft(3);
        x = ghost.point.x.toString().padLeft(7);
        y = ghost.point.y.toString().padLeft(7);
        bc = ghost.busterCount.toString().padLeft(2);
        st = ghost.stamina.toString().padLeft(2);
        stderr.writeln("$id|$x|$y|$bc|$st");
    }
}

printBusters(List<Buster> busters){
    if(busters.length > 0){
        stderr.writeln(" ID|   X   |   Y   | G| S| Stun");
    }
    String id;
    String x;
    String y;
    String g;
    String s;
    String cs;
    for(Buster buster in busters){
        id = buster.id.toString().padLeft(3);
        x = buster.point.x.toString().padLeft(7);
        y = buster.point.y.toString().padLeft(7);
        g = buster.ghostId.toString().padLeft(2);
        s = buster.state.toString().padLeft(2);
        cs = buster.canStun.toString().padLeft(5);
        stderr.writeln("$id|$x|$y|$g|$s|$cs");
    }
}

class Buster{
    int id;
    int teamId;
    Point point;
    int state;
    int ghostId;
    bool stunTarget = false;
    int tilStun = 10;
    
    late Command command;
    late int targetId;
    late Point targetPoint;
    
    Buster(this.id, this.teamId, this.point, this.state, this.ghostId){
        int x = 16000 - 16000 * myTeamId;
        int y = 9000 - 9000 * myTeamId;
        targetPoint = new Point(x, y);
        
    }
    
    void update(Point point, int state, int ghostId){
        this.point = point;
        this.state = state;
        this.ghostId = ghostId;
        
        if(tilStun < 10){
            tilStun++;
        }
    }
    
    void printCommand(){
        switch(command){
            case Command.bust:
                print('BUST $targetId');
                break;
            case Command.release:
                print('RELEASE');
                break;
            case Command.stun:
                print('STUN $targetId');
                break;
            case Command.move:
            default:
                //if no matching command, move toward enemy base
                print('MOVE ${targetPoint.x} ${targetPoint.y}');
                break;
        }
    }
    
    String toString() { return "Buster $id team $teamId at $point command $command"; }
    
    bool get hasGhost => state == 1;
    bool get isStunned => state == 2;
    bool get canStun => tilStun == 10;
}

class Ghost {
    int id;
    Point point;
    int stamina;
    int busterCount;
    int myBusters = 0;
    bool bustTarget = false;
    
    Ghost(this.id, this.point, this.stamina, this.busterCount);
    
    String toString() { return "Ghost $id at $point with $stamina stamina and $busterCount busters"; }
    
}

class Point {
    int x;
    int y;
    Point(this.x, this.y);
    
    String toString() { return "{$x,$y}"; }
    
    num distanceTo(Point other) {
        var dx = x - other.x;
        var dy = y - other.y;
        return sqrt(dx * dx + dy * dy);
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

class Velocity {
    final Point first;
    final Point second;
    
    late int dx;
    late int dy;
    late num dist;
    
    Velocity(this.first, this.second){
        dx = second.x - first.x;
        dy = second.y - first.y;
        dist = sqrt(dx * dx + dy * dy); 
    }
    
    String toString() { return "$first to $second dx: $dx dy $dy dist $dist"; }
}