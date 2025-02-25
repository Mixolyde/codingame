// smitsimax pseudocode
// https://www.codingame.com/playgrounds/36476/smitsimax

// player controlled entity class
class Entity
{
    //position
    //velocity
    //shield 
    //...
}

abstract class Sim
{
    List<Entity> entities = [];  // all 4 pods that will be simulated
    List<Node> current = []; // 4 current nodes, one for each pod. Current nodes start as a reference to the root nodes of each tree
    List<num> lowestscore = []; // the lowest score earned by the tree, one for each pod.
    List<num> highestscore = []; // the highest score earned by the tree, one for each pod.
    List<num> scaleparameter = [];  // the scaleparameter calculated by subtracting the lowest score from the highest, needed for the UCB formula.
    
    void Reset(); // To reset the sim after search
    
    void Search(); // The important bit, the actual search
    
    void Play();  // a CSB specific algorithm that handles movement and collisions (see Magus CSB postmortem)
    
    void BackPropagate();  // each tree has the score result backpropagated along the branch of the tree.
}

abstract class Node 
{
    late Node parent; // each node has a parent except the root node
    late num score; // the total score obtained by this node. To get the average, you can divide by the number of visits
    late int firstChildIndex; // I use a preallocated array that I use this index for
    late int childCount; // the number of children
    late int visits; // the number of times this node has been visited
    late int move; // this is the move that was made to get to this node

}

void Search()
{
    CreateRootNodes() // create nodes, one for each tree. These are also the "current" nodes of the sim.

    while (we still have calculation time left)
    {
        Reset() // reset the sim using the pod instances you obtained during the update
        int depth = 0;

        while (depth < maximum_depth)
        {
            for (each pod, 4 times total)
            {
                Node node = current[i];

                if (node.visits == 1)
                    node.MakeChildren() // give the node children if it doesnt have them yet, each with a possible move

                Node child = node.Select() // select a node that you want to use for the sim. 
                //At first it is best to select randomly a few times. 
                //I currently random 10 times. After this I use the UCB formula to select a child. 

                child.visits++; // increment the child visitcount

                current[i] = child; // the child becomes the current node

                pod.ApplyMove // do the stuff the child node tells you to do (rotate, accelerate, shield etc.)
            }

            Play(); // Simulate what actually happens, including movement and collisions
            depth++;
        }
        
        float[4] score = GetScore(); 
        // get a score for each pod when the simulation depth is reached. 
        //The way the score is calculated is not that different from what it would be in minimax or GA or any other search method. 

        for (each pod, 4 times total)
        {
            // update the lowest score, highest score and scaleparameter for this pod. 
            // the scale parameter is the difference between the highest and lowest score
        }

        void Backpropagate() {
          
        }
        // We go up the tree back to the root node, adding the score to each node we pass. We do this for each pod (4x)
    }
}

// num ucb = (score / (visits_of_child * scale_param)) + exploration_param * Sqrt(Log(visits of parent)) * (1/Sqrt(visits_of_child);