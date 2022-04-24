import 'dart:io';
import 'dart:math';

String readLineSync() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

/**
 * Auto-generated code below aims at helping you parse
 * the standard input according to the problem statement.
 **/
void main() {
    List inputs;
    inputs = readLineSync().split(' ');
    int playerCount = int.parse(inputs[0]); // the amount of players (always 2)
    int myId = int.parse(inputs[1]); // my player ID (0 or 1)
    int zoneCount = int.parse(inputs[2]); // the amount of zones on the map
    int linkCount = int.parse(inputs[3]); // the amount of links between all zones
    //Map<int, int> sourceMap = {};
    for (int i = 0; i < zoneCount; i++) {
        inputs = readLineSync().split(' ');
        // this zone's ID (between 0 and zoneCount-1)
        // Because of the fog, will always be 0
        //sourceMap[int.parse(inputs[0])] = int.parse(inputs[1]);
    }
    List<List<int>> links = [];
    Map<int, List<int>> adjMap = {};
    for (int i = 0; i < linkCount; i++) {
        inputs = readLineSync().split(' ');
        int left = int.parse(inputs[0]);
        int right = int.parse(inputs[1]);
        
        links.add([left, right]);
        
        if (adjMap[left] == null){
            adjMap[left] = new List.from([right]);
        } else {
            adjMap[left]!.add(right);
        }
        if(adjMap[right] == null){
            adjMap[right] = new List.from([left]);
        } else {
            adjMap[right]!.add(left);
        }
    }
    
    //stderr.writeln("SourceMap $sourceMap");
    stderr.writeln("Links $links");
    int turn = 1;
    Random rand = new Random();
    int myBase = -1;
    int oppBase = -1;
    
    // game loop
    while (true) {
        int myPlatinum = int.parse(readLineSync()); // your available Platinum
        Map<int, Zone> zones = {};
        for (int i = 0; i < zoneCount; i++) {
            inputs = readLineSync().split(' ');
            int zId = int.parse(inputs[0]); // this zone's ID
            int ownerId = int.parse(inputs[1]); // the player who owns this zone (-1 otherwise)
            int podsP0 = int.parse(inputs[2]); // player 0's PODs on this zone
            int podsP1 = int.parse(inputs[3]); // player 1's PODs on this zone
            int visible = int.parse(inputs[4]); // 1 if one of your units can see this tile, else 0
            int platinum = int.parse(inputs[5]); // the amount of Platinum this zone can provide (0 if hidden by fog)
            Zone newZone;
            if(myId == 0){
                newZone = new Zone(zId, ownerId, podsP0, podsP1,
                visible > 0, platinum, 
                platinum > 0 ? true : false);
                
            } else {
                newZone = new Zone(zId, ownerId, podsP1, podsP0,
                visible > 0, platinum, 
                platinum > 0 ? true : false);
                
            }
            if(turn == 1 && newZone.myPods > 0){
                myBase = zId;
            } else if (turn == 1 && newZone.oppPods > 0){
                oppBase = zId;
            }
            zones[zId] = newZone;
        }

        // Write an action using print()
        // To debug: stderr.writeln('Debug messages...');
        stderr.writeln("MyBase $myBase OppBase $oppBase");
        
        String commands = "";
        
        //for each zone where I have pods
        String command;
        for(Zone zone in zones.values.where((zone) => zone.myPods > 0)){
            //if neighbor contains unclaimed plat, go to it
            
            int neighborWithPlat = adjMap[zone.zId]!.firstWhere(
                (id) => zones[id]!.hasPlatinum && zones[id]!.ownerId != myId, 
                orElse: () => -1);
            if(neighborWithPlat > -1){
                commands += "1 ${zone.zId} ${neighborWithPlat} ";
            } else {
                int randNeighbor = rand.nextInt(adjMap[zone.zId]!.length);
                commands += "1 ${zone.zId} ${adjMap[zone.zId]![randNeighbor]} ";
            }
            
        }


        // first line for movement commands, second line no longer used (see the protocol in the statement for details)
        print(commands);
        print('WAIT');
        
        turn++;
    }
}

class Zone {
    int zId;
    int ownerId;
    int myPods;
    int oppPods;
    bool visible;
    int platinum;
    bool hasPlatinum;
    Zone(this.zId, this.ownerId, this.myPods, this.oppPods,
        this.visible, this.platinum, this.hasPlatinum);
        
}