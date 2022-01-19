import 'dart:io';
import 'dart:math';

String readLineSync() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

List<int> platSources = [];
List<List<int>> links = [];
List<int> notLastZones = [];
List<Zone> zones = [];
List<Zone> playZones = [];
List<Zone> platZones = [];
late int playerCount;
late int myId;
Random rand = new Random(0);
int turn = 0;
late int rank;

List<List<int>> regions = [];
List<int> ignoreZones = [];
bool notLastStrategy = false;
late List<int> zonesCaptured;
/**
 * Auto-generated code below aims at helping you parse
 * the standard input according to the problem statement.
 **/
void main() {
    //antartica
    ignoreZones.addAll([57, 67, 78, 89, 97, 104, 113]);
    notLastZones.addAll([57, 67, 78, 89, 97, 104, 113]);
    //japan
    ignoreZones.addAll([143, 149, 150]);
    notLastZones.addAll([143, 149, 150]);
    
    //NA
    regions.add([]);
    for(int i = 0; i < 18; i++){
        regions[0].add(i);
    }
    for(int i = 19; i < 24; i++){
        regions[0].add(i);
    }
    regions[0].addAll([27, 28, 29, 37, 38, 43, 46, 47, 48, 49]);
    
    //SA/Africa
    regions.add([]);
    regions[1].addAll([24, 25, 26, 30, 31, 32, 33, 34, 35, 36]);
    regions[1].addAll([39, 40, 41, 42, 44, 45, 18, 50, 51]);
    regions[1].addAll([54, 55, 56, 60, 61, 62, 63, 64, 65, 66]);
    regions[1].addAll([71, 72, 73, 74, 75, 76, 77, 83, 84, 85, 86, 87, 88, 95, 96]);
    
    //Eur/Asia
    regions.add([]);
    regions[2].addAll([52, 53, 58, 59, 68, 69, 70]);
    regions[2].addAll([79, 80, 81, 82, 90, 91, 92, 93, 94, 98, 99, 100, 101, 102, 103]);
    regions[2].addAll([105, 106, 107, 108, 109, 110, 111, 112, 114, 115, 116, 117, 118, 119]);
    regions[2].addAll([120, 121, 122, 123, 124, 125, 126, 127]);
    regions[2].addAll([128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140]);
    regions[2].addAll([141, 142, 144, 145, 146, 147, 148, 151, 152, 153]);
    
    
    List inputs;
    inputs = readLineSync().split(' ');
    playerCount = int.parse(inputs[0]); // the amount of players (2 to 4)
    myId = int.parse(inputs[1]); // my player ID (0, 1, 2 or 3)
    int zoneCount = int.parse(inputs[2]); // the amount of zones on the map
    int linkCount = int.parse(inputs[3]); // the amount of links between all zones
    
    platSources = new List.filled(zoneCount, 0);
    zonesCaptured = new List.filled(playerCount, 0);
    
    for (int i = 0; i < zoneCount; i++) {
        inputs = readLineSync().split(' ');
        int zoneId = int.parse(inputs[0]); // this zone's ID (between 0 and zoneCount-1)
        int platinumSource = int.parse(inputs[1]); // the amount of Platinum this zone can provide per game turn
        platSources[zoneId] = platinumSource;
    }
    for (int i = 0; i < linkCount; i++) {
        inputs = readLineSync().split(' ');
        int zone1 = int.parse(inputs[0]);
        int zone2 = int.parse(inputs[1]);
        links.add([zone1, zone2]);
    }
    
    zones = new List.generate(zoneCount, (z) => new Zone(z, 0, 0, 0, 0, 0));
    zones.forEach((z) => z.setPlatDistances());
    platZones = zonesWithPlat();
    playZones = zones.where((z) => !ignoreZones.contains(z.zId) ).toList();
    
    stderr.writeln("Zone 84 neighbors: ${zones[84].neighbors}");
    
    stderr.writeln("${platZones.length} zones have plat");
    regions.forEach((r) {
       int totalPlat = r.fold(0, (sum, z) => sum + zones[z].plat);
       stderr.writeln("Region has $totalPlat");
    });
    
    // game loop
    while (true) {
        zonesCaptured = new List.filled(playerCount, 0);
        
        int platinum = int.parse(readLineSync()); // my available Platinum
        for (int i = 0; i < zoneCount; i++) {
            inputs = readLineSync().split(' ');
            
            int zId = int.parse(inputs[0]); // this zone's ID
            int ownerId = int.parse(inputs[1]); // the player who owns this zone (-1 otherwise)
            int podsP0 = int.parse(inputs[2]); // player 0's PODs on this zone
            int podsP1 = int.parse(inputs[3]); // player 1's PODs on this zone
            int podsP2 = int.parse(inputs[4]); // player 2's PODs on this zone (always 0 for a two player game)
            int podsP3 = int.parse(inputs[5]); // player 3's PODs on this zone (always 0 for a two or three player game)
            
            zones[zId].ownerId = ownerId;
            zones[zId].pods[0] = podsP0;
            zones[zId].pods[1] = podsP1;
            zones[zId].pods[2] = podsP2;
            zones[zId].pods[3] = podsP3;
            
            if(ownerId != -1){
                zonesCaptured[ownerId]++;
            }
            
        }
        
        stderr.writeln("Current zonesCaptured: $zonesCaptured");
        int rank = captured2rank(zonesCaptured);
        stderr.writeln("Myid $myId my rank $rank on turn $turn");
        if(!notLastStrategy && rank == playerCount &&
        playerCount > 2 && turn > 4){
            notLastStrategy = true;
            stderr.writeln("Switching to not last strategy");
        }

        //eval every zone, even ones we can't place in
        zones.forEach((z) => z.eval());
        
        //update ignore regions
        List<List<int>> source = regions.toList();
        stderr.writeln("Checking ownership of ${source.length} regions");
        for(List<int> region in source){
            if(!region.any((z) => zones[z].ownerId != myId)){
                stderr.writeln("I own this region: $region");
                ignoreZones.addAll(region);
                regions.remove(region);
                playZones = zones.where((z) => !ignoreZones.contains(z.zId) ).toList();
            }
        }
    
        // Write an action using print()
        // To debug: stderr.writeln('Debug messages...');
        Set<Zone> mine = myZones();
        int buyAmount = platinum ~/ 20;
        stderr.writeln("I own ${mine.length} zones and $platinum plat");
        stderr.writeln("Buying $buyAmount pods.");
        // printZones(mine);


        // first line for movement commands, second line for POD purchase (see the protocol in the statement for details)
        String movement = getMovements();
        String buy;
        if(turn == 0){
            buy = getFirstTurnBuys();
        } else {
            buy = getBuys(buyAmount);
        }
        
        print(movement);
    
        print(buy);
        
        turn++;
    }
}

class Zone {
    int zId;
    int ownerId;
    List<int> pods = [0,0,0,0];
    late Set<int> neighbors;
    late num attractiveness;
    late Set<int> platDist1;
    late Set<int> platDist2;
    
    String toString() => "[zId $zId ownerId $ownerId attr $attractiveness]";
    
    Zone(this.zId, this.ownerId, 
        int podsP0, int podsP1, int podsP2, int podsP3){
        pods[0] = podsP0;
        pods[1] = podsP1;
        pods[2] = podsP2;
        pods[3] = podsP3;
        
        neighbors = neighborZones(zId);
    }
    
    void setPlatDistances(){
        platDist1 = new Set();
        platDist2 = new Set();
        for(int n in neighbors){
            if(platSources[n] > 0){
                platDist1.add(n);
            }
            for(int m in zones[n].neighbors){
                if(platSources[m] > 0){
                    platDist2.add(m);
                }
            }
        }
        platDist2.removeWhere((z) => neighbors.contains(z));
        
    }
    
    void eval() {
        num attr = 0;
        attr += 0.1 + plat; 
        int adjacentNeutral = 0;
        int adjacentEnemy = 0;
        for(int n in neighbors){
            if(platSources[zId] > 0){
                if(zones[zId].ownerId == -1){
                    adjacentNeutral++;
                } else if (zones[zId].ownerId != myId){
                    adjacentEnemy++;
                }
            }
        }
        attr += .25 * (adjacentNeutral + .75 * adjacentEnemy )
            / neighbors.length;
        
        
        //attra 0.25*numberOfPlatinumSourcesThatICanTakeInNextTwoMove/2
        int takeable = 0;
        List<int> takeables = platDist1.where((zId) => 
            zones[zId].enemyPods == 0 && 
            zones[zId].ownerId != myId ).toList();
        if(takeables.length > 0){
            takeable += takeables.fold(0, 
            (sum, z) => sum + platSources[z]);
            if(takeables.any((zId) => zones[zId].platDist1
                .any((zId2) => zones[zId2].enemyPods == 0 &&
                zones[zId2].ownerId != myId))) {
                takeable++;
            }
        } else {
            List<int> takeables2 = platDist2.where((zId) => 
            zones[zId].enemyPods == 0 && 
            zones[zId].ownerId != myId ).toList();
            if(takeables2.length > 0){
                takeable += takeables2.fold(0, 
                (sum, z) => sum + platSources[z]);
            }

        }
        
        attr += 0.125 * takeable;
        
        //-= 0.5*attractiveness for each not compensated enemy POD around
        int enemyPodNeighbors = neighbors.fold(0, (sum, zId) => 
            zones[zId].enemyPods > 0 ? sum + 1 : sum);
        for(int i = 0; i < enemyPodNeighbors; i++){
            attr -= .5 * attr;
        }
        
        //TODO add factor for being the only zone left of mine in a region
        
        attractiveness = attr;
    }
    
    int get plat => platSources[zId];
    
    int get totalPods => pods[0] + pods[1] + pods[2] + pods[3];
    
    int get myPods => pods[myId];
    
    int get enemyPods {
        int sum = 0;
        for(int i = 0; i < playerCount; i++ ){
            if(i != myId){
                sum += pods[i];
            }
        }
        return sum;
    }
    
    bool get peaceful {
        int neighborPods = neighbors.fold(0, (sum, n) => sum + zones[n].enemyPods);
        if(neighborPods > myPods){
            return false;
        } else {
            // return neighbors.every((z) => zones[z].ownerId == myId);
            return true;
        }
    }
    
    bool get deep {
        return !neighbors.any((n) => zones[n].ownerId != myId);
    }
}

Set<Zone> myZones() {
    return zones.where((zone) => zone.ownerId == myId).toSet();
}

List<Zone> placementZones() {
    return playZones.where((zone) => 
    (zone.ownerId == myId && !zone.deep) ||
        zone.ownerId == -1).toList();
}

List<Zone> zonesWithPlat() {
    return zones.where((zone) => zone.plat > 0).toList();
}

printZones(List<Zone> zones){
    if(zones.length > 0){
        stderr.writeln(" ID| O|  P| My| OP| PL| Deep|  Eval");
    }
    String id;
    String o;
    String p;
    String my;
    String op;
    String pl;
    String dp;
    String at;
    for(Zone zone in zones){
        id = zone.zId.toString().padLeft(3);
        o = zone.ownerId.toString().padLeft(2);
        p = zone.totalPods.toString().padLeft(3);
        my = zone.myPods.toString().padLeft(3);
        op = zone.enemyPods.toString().padLeft(3);
        pl = zone.plat.toString().padLeft(3);
        dp = zone.deep.toString().padLeft(5);
        at = zone.attractiveness.toString().padLeft(7);
        stderr.writeln("$id|$o|$p|$my|$op|$pl|$dp|$at");
    }
}

Set<int> neighborZones(int zId){
    Set<int> neighbors = new Set();
    links.forEach((link) {
        if(link[0] == zId){
            neighbors.add(link[1]);
        } else if (link[1] == zId){
            neighbors.add(link[0]);
        }
    });
    return neighbors;
}

Comparator zoneCompare = ((a, b) => b.attractiveness.compareTo(a.attractiveness));

String getFirstTurnBuys(){
    int buyAmount = 10;
    List<Zone> placers = placementZones();
    
    // printZones(placers);
    Map<int,num> regionPlatMap = {};
    for(int rIndex = 0; rIndex < regions.length; rIndex++) {
        List r = regions[rIndex];
        int totalPlat = r.fold(0, (sum, z) => sum + zones[z].plat);
        // regionPlatMap[rIndex] = totalPlat / r.length;
        regionPlatMap[rIndex] = totalPlat;
        stderr.writeln("Region $rIndex has $totalPlat");
    }
        
    if(playerCount == 2){
        convertToProbablities(placers, 40);
    } else if (playerCount == 3){
        
        int? rPick;
        late num last;
        regionPlatMap.keys.forEach((key){
            if(rPick == null || regionPlatMap[key]! > last){
                rPick = key;
                last = regionPlatMap[key]!;
            }
        });
        stderr.writeln("Chose region $rPick for first turn concentration");
        placers = placers.where((p) => regions[rPick!].contains(p.zId)).toList();
        printZones(placers);
        
        convertToProbablities(placers, 7);
    } else if (playerCount == 4){
        
        int? rPick;
        late num last;
        regionPlatMap.keys.forEach((key){
            if(rPick == null || regionPlatMap[key]! < last){
                rPick = key;
                last = regionPlatMap[key]!;
            }
        });
        stderr.writeln("Chose region $rPick for first turn concentration");
        placers = placers.where((p) => regions[rPick!].contains(p.zId)).toList();
        printZones(placers);
        
        convertToProbablities(placers, 3);
    } else {
        convertToProbablities(placers, 5);
    }
    
    //purchase
    String buy = "WAIT";
    if(buyAmount > 0){
        buy = "";
        int buyCount = 0;
        
        for (int buyIndex = 0; buyIndex < buyAmount; buyIndex++){
            num randBuy = rand.nextDouble();
            stderr.writeln("Choosing from ${placers.length} placers number: $randBuy");
            for(int pIndex = 0; pIndex < placers.length; pIndex++){
                if(randBuy < placers[pIndex].attractiveness){
                   int randSource = placers[pIndex].zId;
                   stderr.writeln("Chose zone $randSource attr: ${placers[pIndex].attractiveness}");
                   buy += "1 $randSource ";
                   buyCount++;
                   break;
                } else {
                    randBuy -= placers[pIndex].attractiveness;
                }
            }
        }
        
        stderr.writeln("Count $buyCount Amount $buyAmount");
        assert(buyCount == buyAmount);
    }
    
    return buy;
}
String getBuys(int buyAmount){
    List<Zone> placers = placementZones();
    // stderr.writeln("Placers:");
    
    printZones(placers);
    if(playerCount == 2){
        convertToProbablities(placers, 20);
    } else {
        convertToProbablities(placers, 5);
    }
    
    //purchase
    String buy = "WAIT";
    if(buyAmount > 0 && placers.length > 0){
        buy = "";
        int buyCount = 0;
        
        for (int buyIndex = 0; buyIndex < buyAmount; buyIndex++){
            num randBuy = rand.nextDouble();
            stderr.writeln("Choosing from ${placers.length} placers number: $randBuy");
            for(int pIndex = 0; pIndex < placers.length; pIndex++){
                if(randBuy < placers[pIndex].attractiveness){
                   int randSource = placers[pIndex].zId;
                   stderr.writeln("Chose zone $randSource attr: ${placers[pIndex].attractiveness}");
                   buy += "1 $randSource ";
                   buyCount++;
                   break;
                } else {
                    randBuy -= placers[pIndex].attractiveness;
                }
            }
        }
        
        stderr.writeln("Count $buyCount Amount $buyAmount");
        assert(buyCount == buyAmount);
    }
    
    return buy;
}

void convertToProbablities(List<Zone> placers, int power){
    //scale power
    placers.forEach((z) => z.attractiveness = pow(z.attractiveness, power));
    
    //scale to probability
    num attrSum = placers.fold(0, (sum, z) => sum + z.attractiveness);
    stderr.writeln("First attr probability sum: $attrSum");
    placers.forEach((z) => z.attractiveness /= attrSum);
    attrSum = placers.fold(0, (sum, z) => sum + z.attractiveness);
    stderr.writeln("New attr probability sum: $attrSum");
}

String getMovements(){
    Set<Zone> mine = myZones();
    mine.removeWhere((z) => ignoreZones.contains(z.zId));
    stderr.writeln("Moving ${mine.length}");
    //movement
    String movement = "WAIT";
    if(mine.length > 0){
        movement = "";
        for(Zone zone in mine){
            for(int i = 0; i < zone.pods[myId]; i++){
                Map<int, num> attrMap = {};
                num attrSum = 0;
                for(int n in zone.neighbors){
                    if(zones[n].ownerId == myId && zones[n].peaceful){
                        attrMap[n] = 0;
                    } else {
                        attrMap[n] = pow(zones[n].attractiveness, 10);
                    }
                    attrSum += attrMap[n]!;
                }
                if(attrSum != 0) {
                    attrMap.forEach((k, v) => attrMap[k] = v / attrSum);
                    // stderr.writeln("Attr Map for $zone: $attrMap");
                    num randMove = rand.nextDouble();
                    for(int n in attrMap.keys){
                        if(randMove < attrMap[n]!){
                            movement += "1 ${zone.zId} $n ";
                            break;
                        } else {
                            randMove -= attrMap[n]!;
                        }
                    }
                } else {
                    //deep in my territory, go random
                    int bfsMove = bfs(zone.zId);
                    movement += "1 ${zone.zId} $bfsMove ";
                }
            }
        }
    }
    return movement;
}

int bfs(int zId){
    List<int> seen = [zId];
    List<int> start = [zId];
    List<List<int>> queue = [start];
    
    while(queue.isNotEmpty){
        List<int> current = queue.removeAt(0);
        if(zones[current.last].ownerId != myId){
            //first zone in path after the starter
            return current[1];
        } else {
            zones[current.last].neighbors.forEach((n) {
               if(!seen.contains(n)) {
                   seen.add(n);
                   List<int> path = current.toList();
                   path.add(n);
                   queue.add(path);
               }
            });
        }
    }

    throw StateError("BFS not found");
    
}

int captured2rank(proj){
	int me = proj[myId];
	int rank = 1;
	for(int p = 0; p < playerCount; p++){
		if (p != myId && ( proj[p] > me || (proj[p] == me && p > myId ))){
			rank += 1;
		}
	}
	return rank;
}