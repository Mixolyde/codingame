import 'dart:io';

//rank Silver 228/266 on 20250222
//fixed some nullable bugs: Silver 14/266 on 20250222

String readLineSync() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

late int turnType;
late Player me;
late Player opp;
List<Quest> quests = [];
List<Item> items = [];
int HEIGHT = 7;
int WIDTH = 7;
// list of tiles given by id(x,y)
List<int> tiles = List.filled(HEIGHT * WIDTH, 0);
late int tempTile;
Sim sim = new Sim();
int upBits = 0x8;
int rightBits = 0x4;
int downBits = 0x2;
int leftBits = 0x1;
int deadLockCounter = 0;
List<int> deadLockTiles = List.filled(HEIGHT * WIDTH, 0);
late int lastMove;

List<Push> allPushes = Dir.values.expand((d) => 
    List<Push>.generate(7, (i) => new Push(d, i))).toList();

List<String> printCodes = 
[
	"", "", "", "\u2557", "", "\u2550", "\u2554", "\u2566", "", "\u255D", "\u2551", "\u2563", "\u255A", "\u2569", "\u2560", "\u256C"
];

enum Dir {UP, LEFT, DOWN, RIGHT}
enum ItemLoc {BOARD, MYHAND, OPPHAND}

//store opposite pushes, up 0/down 0, etc.
List<int> oppositePushes = List<int>.generate(28, (i) => (i + 14) % 28);

/**
 * Help the Christmas elves fetch presents in a magical labyrinth!
 **/
void main() {
    List inputs;
    // stderr.writeln("AllPushes: $allPushes");

    // game loop
    while (true) {
        turnType = int.parse(readLineSync());
        quests.clear();
        items.clear();
        
        for (int i = 0; i < 7; i++) {
            inputs = readLineSync().split(' ');
            for (int j = 0; j < 7; j++) {
                //i is height, j is width
                String tile = inputs[j];
                // stderr.writeln("Setting tiles $j $i ${id(j,i)} to $tile");
                tiles[id(j,i)] = stringToBits(tile);
                //stderr.writeln(tile);
            }
        }
        for (int i = 0; i < 2; i++) {
            inputs = readLineSync().split(' ');
            int numPlayerCards = int.parse(inputs[0]); // the total number of quests for a player (hidden and revealed)
            int playerX = int.parse(inputs[1]);
            int playerY = int.parse(inputs[2]);
            String playerTile = inputs[3];
            
            Player p = new Player(numPlayerCards, playerX, playerY, playerTile);
            if(i == 0){
                me = p;
            } else {
                opp = p;
            }
        }
        
        printTiles(tiles);
        stderr.writeln("Me  $me");
        stderr.writeln("Opp $opp");
        
        int numItems = int.parse(readLineSync()); // the total number of items available on board and on player tiles
        for (int i = 0; i < numItems; i++) {
            inputs = readLineSync().split(' ');
            String itemName = inputs[0];
            int itemX = int.parse(inputs[1]);
            int itemY = int.parse(inputs[2]);
            int itemPlayerId = int.parse(inputs[3]);
            
            late Item item;
            if(itemX >= 0){
                item = new Item(itemName, itemX, itemY, itemPlayerId);
            } else if (itemX == -1){
                item = new Item(itemName, null, null, itemPlayerId);
                item.itemLoc = ItemLoc.MYHAND;
            } else if (itemX == -2){
                item = new Item(itemName, null, null, itemPlayerId);
                item.itemLoc = ItemLoc.OPPHAND;
            }
            items.add(item);
        }
        
        int numQuests = int.parse(readLineSync()); // the total number of revealed quests for both players
        for (int i = 0; i < numQuests; i++) {
            inputs = readLineSync().split(' ');
            String questItemName = inputs[0];
            int questPlayerId = int.parse(inputs[1]);
            
            Quest quest = new Quest(questItemName, questPlayerId);
            quests.add(quest);
            quest.target = items.firstWhere((item) => item.itemName == quest.questItemName &&
                item.itemPlayerId == quest.questPlayerId);
        }

        // Write an action using print()
        // To debug: stderr.writeln('Debug messages...');
        // stderr.writeln(quests);
        // stderr.writeln(items);
        
        switch(turnType){
            case 0:
                //push turn
                var scores = scoresByMove();
                // stderr.writeln("After sim tiles");
                // printTiles(tiles);
                
                // deadlock check
                bool deadlock = true;
                for (int i = 0; i < HEIGHT * WIDTH; i++){
                    if(tiles[i] != deadLockTiles[i]){
                        stderr.writeln("Reset deadlock counter");
                        deadlock = false;
                        deadLockCounter = 0;
                        break;
                    }
                    
                }
                if (deadlock == true){
                    deadLockCounter++;
                    stderr.writeln("Incremented deadlock counter: $deadLockCounter");
                }
                if (deadLockCounter > 5){
                    stderr.writeln("Deadlock threshhold reached!");
                }
                
                int bestIndex = 0;
                int bestScore = 0;
                for(int i = 0; i < scores.length; i++){
                    if(scores[i] > bestScore && 
                        ( deadLockCounter < 6 || 
                            (i != lastMove && i != oppositePushes[lastMove]))){
                        bestScore = scores[i];
                        bestIndex = i;
                    }
                }
                
                stderr.writeln("Best score: $bestScore");
                stderr.writeln("Best move: ${allPushes[bestIndex]}");
                
                for(int i = 0; i < WIDTH * HEIGHT; i++){
                    deadLockTiles[i] = tiles[i];
                }
                lastMove = bestIndex;
                
                print(allPushes[bestIndex]);
                
                break;
            case 1:
                //move turn
                // MOVE <direction> | PASS
                var moves = movePathSearch();
                stderr.writeln("Moves path: $moves");
                if (moves[0] != null) {
                    String move = "MOVE";
                    int i = 0;
                    while(i < 20 && moves[i] != null){
                        move += " ${moves[i].toString().substring(4)}";
                        i++;
                    }
                    stderr.writeln("Printing move path: $move");
                    print("$move");
                    
                } else {
                    print('PASS');
                }
                break;
            default:
                stderr.writeln("Invalid turn type!");
                
        }

    }
}

int id(int x, int y) => x + HEIGHT * y;

void printTiles(List<int> pTiles) {
    for (int y = 0; y < HEIGHT; y++){
        for (int x = 0; x < WIDTH; x++){
            stderr.write(printCodes[pTiles[id(x,y)]]);
        }
        if (y == 0){
            stderr.write("  My tile : ${printCodes[me.playerTile]}");
        } else if (y == 1){
            stderr.write("  Opp tile: ${printCodes[opp.playerTile]}");
        }
        
        stderr.writeln("");
    }
}

int stringToBits(String s)
{
	int binary = 0;

	for (int i = 0; i < 4; i++)
	{
		if (s[i] == '1')
			binary += 1 << (3 - i);
	}
	return binary;
}

List<Dir> movePathSearch(){
    int searchIndex = 1;
    //int questsCompleted = 0;
    int distanceLeft = 20;
    List<int> visited = List<int>.generate(49, (i) => -1);
    //TODO fix default path if needed
    List<Dir> path = List.filled(20, Dir.UP);
    List<MoveSearchNode> queue = [];
    
    MoveSearchNode parent = new MoveSearchNode(null, null, me.playerX, me.playerY, 0);
    addNeighbors(parent, queue, visited, searchIndex);
    MoveSearchNode? questNode;
    MoveSearchNode? furthestNode;
    
    while(queue.length != 0 && questNode == null){
        MoveSearchNode first = queue.removeAt(0);
        if(quests.any((q) => q.target.itemX == first.x && 
            q.target.itemY == first.y && q.questPlayerId == 0 &&
            q.completed == false)){
            questNode = first;
            furthestNode = first;
            stderr.writeln("Found a path to first quest at ${questNode.x},${questNode.y}");
        } else {
            addNeighbors(first, queue, visited, searchIndex);
        }
    }
    
    if (questNode != null){
        MoveSearchNode pointer = questNode;
        quests.firstWhere((q) => q.target.itemX == pointer.x &&
            q.target.itemY == pointer.y && q.questPlayerId == 0).completed = true;
        distanceLeft -= questNode.distance;
            
            
        //search for second quest from here
        stderr.writeln("Searching for path to second quest");
        searchIndex++;
        queue.clear();
        queue.add(questNode);
        questNode = null;
        
        while(queue.length != 0 && questNode == null){
            MoveSearchNode first = queue.removeAt(0);
            if(quests.any((q) => q.target.itemX == first.x && 
                q.target.itemY == first.y && q.questPlayerId == 0 &&
                q.completed == false)){
                questNode = first;
                furthestNode = first;
                stderr.writeln("Found a path to second quest at ${questNode.x},${questNode.y}");
            } else {
                addNeighbors(first, queue, visited, searchIndex);
            }
        }
        
        if (questNode != null){
            MoveSearchNode pointer = questNode;
            quests.firstWhere((q) => q.target.itemX == pointer.x &&
                q.target.itemY == pointer.y && q.questPlayerId == 0).completed = true;
            distanceLeft -= questNode.distance;
                
                
            //search for third quest from here
            searchIndex++;
            queue.clear();
            queue.add(questNode);
            questNode = null;
            
            while(queue.length != 0 && questNode == null){
                MoveSearchNode first = queue.removeAt(0);
                if(quests.any((q) => q.target.itemX == first.x && 
                    q.target.itemY == first.y && q.questPlayerId == 0 &&
                    q.completed == false)){
                    questNode = first;
                    furthestNode = first;
                    stderr.writeln("Found a path to third quest at ${questNode.x},${questNode.y}");
                } else {
                    addNeighbors(first, queue, visited, searchIndex);
                }
            }
        }
    }
    
    if(furthestNode != null) {
        while (furthestNode!.parent != null){
            if(furthestNode.distance < 21) {
                path[furthestNode.distance - 1] = furthestNode.move!;
            }
            furthestNode = furthestNode.parent;
        } 
    }
    
    return path;
    
}

List<int> scoresByMove(){
    List<int> scores = List.filled(allPushes.length, 0);
    Sim sim = new Sim();
    sim.save();
    for (int i = 0; i < allPushes.length; i++){
        //apply push
        sim.play(allPushes[i]);
        
        //get score
        scores[i] = sim.score(0);
        stderr.writeln("Score for move ${allPushes[i]}: ${scores[i]}");
        
        //unapply push
        sim.reset();
        
    }
    
    return scores;
    
}

void addNeighbors(MoveSearchNode node, List<MoveSearchNode> queue, List<int> visited,
    searchIndex){
    int index = id(node.x, node.y);
    int tile = tiles[index];
    // stderr.writeln("Adding neighbors for node at ${node.x},${node.y} index $searchIndex");
    //check up neighbor
    if(node.y > 0 && 
        (tile & upBits == upBits) && 
        (tiles[id(node.x, node.y - 1)] & downBits == downBits &&
        visited[id(node.x,node.y - 1)] != searchIndex)  ){
            
        // stderr.writeln("Tile at ${node.x},${node.y} connects up");
        queue.add(new MoveSearchNode(node, Dir.UP, node.x, node.y - 1, node.distance + 1));
        visited[id(node.x,node.y - 1)] = searchIndex;
    }
    if (node.y < HEIGHT - 1 &&
        tile & downBits == downBits &&
        tiles[id(node.x, node.y + 1)] & upBits == upBits &&
        visited[id(node.x, node.y + 1)] != searchIndex){
            
        // stderr.writeln("Tile at ${node.x},${node.y} connects down");
        queue.add(new MoveSearchNode(node, Dir.DOWN, node.x, node.y + 1, node.distance + 1));
        visited[id(node.x,node.y + 1)] = searchIndex;
    }
    if(node.x > 0 && 
        (tile & leftBits == leftBits) && 
        (tiles[id(node.x - 1, node.y)] & rightBits == rightBits &&
        visited[id(node.x - 1,node.y)] != searchIndex) ){
            
        // stderr.writeln("Tile at ${node.x},${node.y} connects left");
        queue.add(new MoveSearchNode(node, Dir.LEFT, node.x - 1, node.y, node.distance + 1));
        visited[id(node.x - 1,node.y)] = searchIndex;
    }
    if (node.x < WIDTH - 1 &&
        tile & rightBits == rightBits &&
        tiles[id(node.x + 1, node.y)] & leftBits == leftBits &&
        visited[id(node.x + 1, node.y)] != searchIndex){
            
        // stderr.writeln("Tile at ${node.x},${node.y} connects right");
        queue.add(new MoveSearchNode(node, Dir.RIGHT, node.x + 1, node.y, node.distance + 1));
        visited[id(node.x + 1,node.y)] = searchIndex;
    }
    
}

class Player {
    int numPlayerCards;
    int playerX;
    int playerY;
    int playerTile;
    
    late int saveX;
    late int saveY;
    late int saveTile;
    
    Player(this.numPlayerCards, this.playerX, this.playerY, String tile)
        : playerTile = stringToBits(tile);
    
    String toString() => "[$playerX,$playerY] ${printCodes[playerTile]} #:$numPlayerCards";
    
    void save(){
        saveX = playerX;
        saveY = playerY;
        saveTile = playerTile;
    }
    
    void reset(){
        playerX = saveX;
        playerY = saveY;
        playerTile = saveTile;
    }
}

class Item {
    String itemName;
    int? itemX;
    int? itemY;
    int itemPlayerId;
    ItemLoc itemLoc = ItemLoc.BOARD;
    
    int? saveX;
    int? saveY;
    late ItemLoc saveLoc;
    
    Item(this.itemName, this.itemX, this.itemY, this.itemPlayerId);
    
    String toString() => "I:$itemName [$itemX,$itemY] P:$itemPlayerId";
    
    void save(){
        saveX = itemX;
        saveY = itemY;
        saveLoc = itemLoc;
    }
    
    void reset(){
        itemX = saveX;
        itemY = saveY;
        itemLoc = saveLoc;
    }

}

class Quest {
    String questItemName;
    int questPlayerId;
    late Item target;
    bool completed = false;
    
    Quest(this.questItemName, this.questPlayerId);
    
    String toString() => "Q:$questItemName P:$questPlayerId";
    
}

class Sim {
    late List<Player> players;
    late List<Node> nodes;
    List<int> savedTiles = List.filled(tiles.length, 0);
    int searchIndex = 0;
    List<int> visited = List<int>.generate(49, (i) => -1);
    List<Item> itemsFound = <Item>[];
    
    Sim(){
        players = [me, opp];
    }
    
    void save(){
        players[0].save();
        players[1].save();
        items.forEach((item) => item.save());
        for (int i = 0; i < tiles.length; i++){
            savedTiles[i] = tiles[i];
        }
        
    }
    
    void reset(){
        players[0].reset();
        players[1].reset();
        items.forEach((item) => item.reset());
        quests.forEach((quest) => quest.completed = false);
        for (int i = 0; i < tiles.length; i++){
            tiles[i] = savedTiles[i];
        }
        
    }
    
    void play(Push move){
        // stderr.writeln("Playing move:$move");
        // stderr.writeln("${players}");
        switch(move.dir){
            case Dir.RIGHT:
                //slide tiles
                tempTile = tiles[id(WIDTH - 1, move.rank)];
                for(int x = WIDTH - 2; x >= 0; x--){
                    tiles[id(x + 1, move.rank)] = tiles[id(x, move.rank)];
                }
                tiles[id(0, move.rank)] = me.playerTile;
                me.playerTile = tempTile;
                //update items
                items.forEach((item){
                    if(item.itemLoc == ItemLoc.MYHAND){
                        item.itemX = 0;
                        item.itemY = move.rank;
                        item.itemLoc = ItemLoc.BOARD;
                    } else if (item.itemLoc == ItemLoc.BOARD &&
                        item.itemY == move.rank){
                        if(item.itemX! < WIDTH -1){
                            item.itemX = item.itemX! + 1;
                        } else {
                            item.itemX = null;
                            item.itemY = null;
                            item.itemLoc = ItemLoc.MYHAND;
                        }
                    }
                });
                //update players
                players.forEach((p){
                    if(p.playerY == move.rank){
                        p.playerX = (p.playerX + 1) % WIDTH;
                    }
                });
                break;
            case Dir.LEFT:
                //slide tiles
                tempTile = tiles[id(0, move.rank)];
                for(int x = 0; x < WIDTH - 2; x++){
                    tiles[id(x, move.rank)] = tiles[id(x + 1, move.rank)];
                }
                tiles[id(WIDTH - 1, move.rank)] = me.playerTile;
                me.playerTile = tempTile;
                //update items
                items.forEach((item){
                    if(item.itemLoc == ItemLoc.MYHAND){
                        item.itemX = WIDTH - 1;
                        item.itemY = move.rank;
                        item.itemLoc = ItemLoc.BOARD;
                    } else if (item.itemLoc == ItemLoc.BOARD &&
                        item.itemY == move.rank){
                        if(item.itemX! > 0){
                            item.itemX = item.itemX! - 1;
                        } else {
                            item.itemX = null;
                            item.itemY = null;
                            item.itemLoc = ItemLoc.MYHAND;
                        }
                    }
                });
                //update players
                players.forEach((p){
                    if(p.playerY == move.rank){
                        p.playerX = (p.playerX - 1) % WIDTH;
                    }
                });
                break;
            case Dir.DOWN:
                //slide tiles
                tempTile = tiles[id(move.rank, HEIGHT - 1)];
                for(int y = HEIGHT - 2; y >= 0; y--){
                    tiles[id(move.rank, y + 1)] = tiles[id(move.rank, y)];
                }
                tiles[id(move.rank, 0)] = me.playerTile;
                me.playerTile = tempTile;
                //update items
                items.forEach((item){
                    if(item.itemLoc == ItemLoc.MYHAND){
                        item.itemX = move.rank;
                        item.itemY = 0;
                        item.itemLoc = ItemLoc.BOARD;
                    } else if (item.itemLoc == ItemLoc.BOARD &&
                        item.itemX == move.rank){
                        if(item.itemY! < HEIGHT - 1){
                            item.itemY = item.itemY! + 1;
                        } else {
                            item.itemX = null;
                            item.itemY = null;
                            item.itemLoc = ItemLoc.MYHAND;
                        }
                    }
                });
                //update players
                players.forEach((p){
                    if(p.playerX == move.rank){
                        p.playerY = (p.playerY + 1) % HEIGHT;
                    }
                });
                break;
            case Dir.UP:
                //slide tiles
                tempTile = tiles[id(move.rank, 0)];
                for(int y = 0; y < HEIGHT - 2; y++){
                    tiles[id(move.rank, y)] = tiles[id(move.rank, y + 1)];
                }
                tiles[id(move.rank, HEIGHT - 1)] = me.playerTile;
                me.playerTile = tempTile;
                //update items
                items.forEach((item){
                    if(item.itemLoc == ItemLoc.MYHAND){
                        item.itemX = move.rank;
                        item.itemY = HEIGHT - 1;
                        item.itemLoc = ItemLoc.BOARD;
                    } else if (item.itemLoc == ItemLoc.BOARD &&
                        item.itemX == move.rank){
                        if(item.itemY! > 0){
                            item.itemY = item.itemY! - 1;
                        } else {
                            item.itemX = null;
                            item.itemY = null;
                            item.itemLoc = ItemLoc.MYHAND;
                        }
                    }
                });
                //update players
                players.forEach((p){
                    if(p.playerX == move.rank){
                        p.playerY = (p.playerY - 1) % HEIGHT;
                    }
                });
                break;
        }
       
        if(move.rank == 0){ 
            // printTiles(tiles);
            // stderr.writeln(items);
            // stderr.writeln(players);
        }
        
    }
    
    int score(int player){
        //greedy BFS
        searchIndex++;
        itemsFound.clear();
        int score = 0;
        
        List<int> queue = <int>[];
        queue.add(id(players[player].playerX, players[player].playerY));
        visited[id(players[player].playerX, players[player].playerY)] = searchIndex;
        
        while(queue.length > 0){
            //add neighbors, mark visited
            int index = queue.removeAt(0);
            addNeighbors(index, queue);
        }
        
        quests.forEach((q) {
            if(q.target.itemLoc == ItemLoc.BOARD &&
            visited[id(q.target.itemX!, q.target.itemY!)] == searchIndex &&
            q.questPlayerId == player
            ){
                stderr.writeln("$me can reach ${q.target}");
                score += 299;
            } else if (q.target.itemLoc == ItemLoc.MYHAND){
                if(q.questPlayerId == player){
                    score += 20;
                } else {
                    score += 15;
                }
            }
        });
        items.forEach((i) {
            if(i.itemLoc == ItemLoc.BOARD &&
            visited[id(i.itemX!, i.itemY!)] == searchIndex &&
            i.itemPlayerId == player){
                score += 1;
            }
        });
        
        
        return score;
    }
    
    void backPropogate(){
        
    }
    
    void addNeighbors(int index, List<int> queue){
        int tile = tiles[index];
        int upIndex = index - WIDTH;
        int downIndex = index + WIDTH;
        int leftIndex = index - 1;
        int rightIndex = index + 1;
        // stderr.writeln("Adding neighbors for node at ${node.x},${node.y} index $searchIndex");
        //check up neighbor
        if(index >= WIDTH && 
            (tile & upBits == upBits) && 
            (tiles[upIndex] & downBits == downBits &&
            visited[upIndex] != searchIndex)  ){
            // stderr.writeln("Tile at ${index} connects up");
            queue.add(upIndex);
            visited[upIndex] = searchIndex;
        }
        if (index < WIDTH * (HEIGHT - 1) &&
            tile & downBits == downBits &&
            tiles[downIndex] & upBits == upBits &&
            visited[downIndex] != searchIndex){
                
            // stderr.writeln("Tile at ${node.x},${node.y} connects down");
            queue.add(downIndex);
            visited[downIndex] = searchIndex;
        }
        if(index % WIDTH > 0 && 
            (tile & leftBits == leftBits) && 
            (tiles[leftIndex] & rightBits == rightBits &&
            visited[leftIndex] != searchIndex) ){
            // stderr.writeln("Tile at ${node.x},${node.y} connects left");
            queue.add(leftIndex);
            visited[leftIndex] = searchIndex;
        }
        if (index % WIDTH < WIDTH - 1 &&
            tile & rightBits == rightBits &&
            tiles[rightIndex] & leftBits == leftBits &&
            visited[rightIndex] != searchIndex){
                
            // stderr.writeln("Tile at ${node.x},${node.y} connects right");
            queue.add(rightIndex);
            visited[rightIndex] = searchIndex;
        }
        
    }
    
}

class Node{
    Node? parent;
    num score = 0;
    int visits = 0;
    Move? move;
    
    Node();
}

abstract class Move{
    const Move();
}

class Push extends Move{
    final Dir dir;
    final int rank;
    
    const Push(this.dir, this.rank);
    
    String toString() => "PUSH $rank ${dir.toString().substring(4)}";
}

class MoveMove extends Move {
    final Dir dir;
    
    const MoveMove(this.dir);
}

class MoveSearchNode{
    MoveSearchNode? parent;
    int x;
    int y;
    int distance;
    Dir? move;
    
    MoveSearchNode(this.parent, this.move, this.x, this.y, this.distance);
}