import 'dart:io';
import 'dart:math';

String readLineSync() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

enum TYPE {mybot, oppbot, radar, trap}
enum ITEM {none, radar, trap, ore}
late int width;
late int height; // size of the map
List<int> ores = List.filled(width * height, -2);
List<int> holes = List.filled(width * height, -2);
List<MyBot> myBots = <MyBot>[];
List<OppBot> oppBots = <OppBot>[];
List<Radar> radars = <Radar>[];
List<Trap> traps = <Trap>[];
List<Command> commands = List.filled(5, Wait());
List<List<int>> veins = <List<int>>[];

/**
 * Deliver more ore to hq (left side of the map) than your opponent. Use radars to find ore but beware of traps!
 **/
void main() {
    List inputs;
    inputs = readLineSync().split(' ');
    width = int.parse(inputs[0]);
    height = int.parse(inputs[1]); // size of the map

    // game loop
    while (true) {
        inputs = readLineSync().split(' ');
        int myScore = int.parse(inputs[0]); // Amount of ore delivered
        int opponentScore = int.parse(inputs[1]);
        veins.clear();
        for (int i = 0; i < height; i++) {
            inputs = readLineSync().split(' ');
            for (int j = 0; j < width; j++) {
                if(inputs[2*j] == "?"){
                    ores[idx(j, i)] = -1;
                } else {
                    ores[idx(j, i)] = int.parse(inputs[2*j]);
                    if(ores[idx(j, i)] > 0 ){
                        veins.add([j, i]);
                    }
                }
                holes[idx(j, i)] = int.parse(inputs[2*j+1]);
            }
        }
        inputs = readLineSync().split(' ');
        int entityCount = int.parse(inputs[0]); // number of entities visible to you
        int radarCooldown = int.parse(inputs[1]); // turns left until a new radar can be requested
        int trapCooldown = int.parse(inputs[2]); // turns left until a new trap can be requested
        myBots.clear();
        oppBots.clear();
        radars.clear();
        traps.clear();
        stderr.writeln("RadarCooldown: $radarCooldown TrapCooldown $trapCooldown");

        for (int i = 0; i < entityCount; i++) {
            inputs = readLineSync().split(' ');
            int entityId = int.parse(inputs[0]); // unique id of the entity
            int entityType = int.parse(inputs[1]); // 0 for your robot, 1 for other robot, 2 for radar, 3 for trap
            int x = int.parse(inputs[2]);
            int y = int.parse(inputs[3]); // position of the entity
            int itemInt = int.parse(inputs[4]); // if this entity is a robot, the item it is carrying (-1 for NONE, 2 for RADAR, 3 for TRAP, 4 for ORE)

            late ITEM item;
            switch (itemInt){
                case -1:
                    item = ITEM.none;
                    break;
                case 2:
                    item = ITEM.radar;
                    break;
                case 3:
                    item = ITEM.trap;
                    break;
                case 4:
                    item = ITEM.ore;
                    break;
            }

            switch(entityType){
                case 0:
                    myBots.add(new MyBot(entityId, x, y, item));
                    break;
                case 1:
                    oppBots.add(new OppBot(entityId, x, y, item));
                    break;
                case 2:
                    radars.add(new Radar(entityId, x, y));
                    break;
                case 3:
                    traps.add(new Trap(entityId, x, y));
                    break;

            }
        }

        // inputs collected
        printOres();
        //printHoles();
        printRadars();
        printTraps();


        for (int i = 0; i < 5; i++) {

            // Write an action using print()
            // To debug: stderr.writeln('Debug messages...');
            // WAIT|MOVE x y|DIG x y|REQUEST item
            switch(i){
                case 0:
                case 1:
                    MyBot radarBot = myBots[i];
                    stderr.writeln("Radar bot $i: $radarBot");

                    if(radarCooldown == 0 && radarBot.item == ITEM.none){
                        commands[i] = new Request(ITEM.radar);
                    } else if (radarBot.item == ITEM.none){
                        commands[i] = new Move(0, radarBot.y);
                    } else {
                        commands[i] = new Dig(8, radarBot.y);
                        //commands[0] = new Wait();
                    }
                    break;
                default:
                    MyBot oreBot = myBots[i];
                    stderr.writeln("Ore bot $i: $oreBot");
                    if(oreBot.item == ITEM.ore){
                        commands[i] = new Move(0, oreBot.y);
                    } else if(veins.length > 0){
                        //dig first vein in list
                        commands[i] = new Dig(veins[0][0], veins[0][1]);
                        veins.removeAt(0);
                    } else {
                        commands[i] = new Move(8, myBots[i].y);
                    }
                    break;
            }
        }

        for (int i = 0; i < 5; i++) {
            print(commands[i].toString());
        }
    }
}

int idx(int w, int h) => h * width + w;
List<int> wh(int idx) => [idx % width, idx ~/ width ];

void printOres(){
    for (int h = 0; h < height; h++){
        for (int w = 0; w < width; w++){
            if(ores[idx(w, h)] == -1){
                stderr.write("?");
            } else {
                stderr.write(ores[idx(w, h)]);
            }
        }
        stderr.writeln("");
    }
}

void printHoles(){
    for (int h = 0; h < height; h++){
        for (int w = 0; w < width; w++){
            stderr.write(holes[idx(w, h)]);
        }
        stderr.writeln("");
    }
}

void printRadars(){
    radars.forEach((r) {
        stderr.writeln("Radar: $r");
    });
}

void printTraps(){
    traps.forEach((t) {
        stderr.writeln("Trap:  $t");
    });
}

int diagDistance(int x1, int y1, int x2, int y2){
    int dx = (x1 - x2).abs();
    int dy = (y1 - y2).abs();

    return min(dx, dy) + (dx - dy).abs();
}

abstract class Entity {
    int entityId;
    TYPE entityType;
    int x;
    int y;
    ITEM item;

    Entity(this.entityId, this.entityType, this.x, this.y, this.item);

    String toString() => "Id:$entityId [$x,$y] Item:${item.toString().substring(5)}";
}

class MyBot extends Entity{
    MyBot(int entityId, int x, int y, ITEM item):
        super(entityId, TYPE.mybot, x, y, item);
}

class OppBot extends Entity{
    OppBot(int entityId, int x, int y, ITEM item):
        super(entityId, TYPE.oppbot, x, y, item);
}

class Radar extends Entity{
    Radar(int entityId, int x, int y):
        super(entityId, TYPE.radar, x, y, ITEM.none);
}

class Trap extends Entity{
    Trap(int entityId, int x, int y):
        super(entityId, TYPE.trap, x, y, ITEM.none);
}

abstract class Command{}

class Wait extends Command{
    String toString() => "WAIT";
}

class Move extends Command {
    int x;
    int y;
    Move(this.x, this.y);

    String toString() => "MOVE $x $y";
}

class Dig extends Command {
    int x;
    int y;
    Dig(this.x, this.y);

    String toString() => "DIG $x $y";
}

class Request extends Command {
    ITEM item;
    Request(this.item);

    String toString() => "REQUEST ${item.toString().substring(5).toUpperCase()}";
}