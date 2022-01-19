import '../bin/codersstrikeback.dart';
import 'package:test/test.dart';

typedef SolutionCounter = int Function(List<Pod> startPods, int length, int timeout);
List<SolutionCounter> solutionCounters = 
  [naiveSolutionCount, monteCarloSolutionCount, geneticSolutionCount];

void main() {
  // measure eval performances
  // Laps 3 CPs 4 Goal: 12
  // Checkpoints: [CP: 0 at {10051,5947}, CP: 1 at {13946,1945}, CP: 2 at {8035,3288}, CP: 3 at {2663,7036}]
  //  ID|   X   |   Y   |   A| C|  T| S
  //   0|   9693|   5598|  -1| 0|100|false
  //   1|  10409|   6296|  -1| 0|100|false
  //   2|   8976|   4901|  -1| 0|100|false
  //   3|  11126|   6993|  -1| 0|100|false
  cpCount = 4;
  cpGoal = 12;
  checkpoints = [
    Checkpoint(0,10051,5947),
    Checkpoint(1,13946,1945),
    Checkpoint(2,8035,3288),
    Checkpoint(3,2663,7036)];
  List<Pod> pods = <Pod>[
    Pod(0,  9693, 5598, 0, 0, -1, 0),
    Pod(1, 10409, 6296, 0, 0, -1, 0),
    Pod(2,  8976, 4901, 0, 0, -1, 0),
    Pod(3, 11126, 6993, 0, 0, -1, 0),
    ];
    
  pods[0].partner = pods[1];
  pods[1].partner = pods[0];

  pods[2].partner = pods[3];
  pods[3].partner = pods[2];
  
  int length = 6;
  int timeout = 2000;
  var naiveCount = naiveSolutionCount(pods, length, timeout);
  var monteCount = monteCarloSolutionCount(pods, length, timeout);
  var geneticCount = geneticSolutionCount(pods, length, timeout);
  
  print("Naive Solution Count: $naiveCount");
  print("Monte Solution Count: $monteCount");
  print("Genetic Solution Count: $geneticCount");
  
} 

int naiveSolutionCount(List<Pod> startPods, int length, int timeout){
    Solution naive = naiveSolution(startPods, length);
    int count = 0;
    Stopwatch sw = new Stopwatch();
    sw.start();
    while(sw.elapsedMilliseconds < timeout){
      naive = naiveSolution(startPods, length);
      count++;
    }
    return count;
}

int monteCarloSolutionCount(List<Pod> startPods, int length, int timeout){
  monteEvals = 0;
  Solution monte = monteCarlo(startPods, length, timeout);
  return monteEvals;
}

int geneticSolutionCount(List<Pod> startPods, int length, int timeout){
  totalEvals = 0;
  Solution geneticSol = genetic(startPods, length, timeout, null, null);
  return totalEvals;
}