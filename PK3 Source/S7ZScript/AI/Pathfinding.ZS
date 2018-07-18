// By Dodopod
class NavIndicator : Actor { // DEBUG
    default {
        Radius 16;
        Height 16;

        RenderStyle "Add";

        +NOGRAVITY
        +NOBLOCKMAP
    }

    States {
    Spawn:
        TFOG AB 6 Bright { angle += 10; }
        Loop;
    }
}

class NavPoint : Actor {
    Array<NavPoint> links;
    Array<double>   costs;

    default {
        Radius 8;
        Height 8;

        +NOBLOCKMAP +NOGRAVITY
    }

    /*override void PostBeginPlay () {
        // Connect this NavPoint to every other NavPoint that can be reached without being blocked
        for (int i = 0; i < 5; i++) {
            let tid = args [i];

            if (tid == 0)
                continue;

            let it = ActorIterator.Create (tid, "NavPoint");

            for (NavPoint node = NavPoint (it.Next ()); node; node = NavPoint (it.Next ())) {
                if (node == self)
                    continue;

                if (CheckSight (node, SF_SeePastShootableLines)) {
                    links.Push (node);
                    costs.Push (Distance2D (node));

                    Console.PrintF ("(ZScript:NavPoint) Link added");    // DEBUG
                }
            }
        }

        if (links.Size () == 0)
            Console.PrintF ("\c[Yellow](ZScript:NavPoint) Warning: No links created!"); // DEBUG-ISH

        Super.PostBeginPlay ();
    }*/
}

class Plan {
    Array<NavPoint> path; // NavPoints that path passes through
    double givenCost;     // Distance from starting point to last NavPoint in path
    double heuristicCost; // Approx. distance from last NavPoint to the goal
}

//class Pathfinder : Actor {
extend class S7_MonsterBase {
    Array<NavPoint> path;

    Actor navIndicator;

    action void A_Star () {
        invoker.AStar ();
    }

    void AStar () {
        if (CheckSight (target)) {
            path.Clear ();
            goal = null;

            A_Chase ();

            if (navIndicator) navIndicator.A_Remove (AAPTR_DEFAULT, RMVF_EVERYTHING);  // DEBUG
        } else if (NavPoint (goal) && Distance2D (goal) > radius) {
            int oldMoveDir = moveDir;

            A_Face (goal);
            moveDir = (8 * angle / 360) % 8;

            if (!TryWalk ()) {
                moveDir = oldMoveDir;

                if (!TryWalk ())
                    newChaseDir ();
            }
        } else if (path.Size () > 0) {
            Console.PrintF ("(ZScript:PathFinder:A_Star) NavPoint reached."); // DEBUG

            goal = path [path.Size () - 1];
            path.Pop ();

            // DEBUG
            if (navIndicator) navIndicator.A_Remove (AAPTR_DEFAULT, RMVF_EVERYTHING);
            navIndicator = Spawn ("NavIndicator", goal.pos);
        } else {
            Console.PrintF ("(ZScript:PathFinder:A_Star) Planning path..."); // DEBUG

            // Find first and last NavPoints
            // That is, closest Nav in LOS,
            // and closest Nav to target in target's LOS
            // WARNING: LOS doesn't imply a straight-line path, so this is technically broken
            NavPoint startNav, goalNav;

            {
                double startDist = -1.0;
                double goalDist = -1.0;

                ThinkerIterator it = ThinkerIterator.Create ("NavPoint");
                NavPoint nav = NavPoint (it.Next ());

                for (; nav; nav = NavPoint (it.Next ())) {
                    double dist = Distance2D (nav);

                    if ((startDist < 0 || dist < startDist) && CheckSight (nav)) {
                        startNav = nav;
                        startDist = dist;
                    }

                    dist = target.Distance2D (nav);
                    if ((goalDist < 0 || dist < goalDist) && target.CheckSight (nav)) {
                        goalNav = nav;
                        goalDist = dist;
                    }
                }

                if (!(startNav && goalNav)) {
                    Console.PrintF ("\c[Red](ZScript:PathFinder:A_Star) Error: NavPoint graph incomplete!"); // DEBUG-ISH
                    return;
                }
            }

            // Find the shortest path from one to the other using A* search
            {
                // Fringe contains partial plans under consideration
                // In spite of appearances, it's actually a binary min-heap
                // This means that the plan w/ the shortest path is always first
                // It also means that adding/removing elements is complex (see below)
                Array<Plan> fringe;

                // Initial plan
                fringe.Push (new ('Plan'));
                fringe [0].path.Push (startNav);
                fringe [0].givenCost = Distance2D (startNav);
                fringe [0].heuristicCost = startNav.Distance2D (goalNav);

                // Contains NavPoints we've already searched once, so we don't repeat work
                // Ideally, this should be a tree, but even a dynamic array works wonders
                Array<NavPoint> closed;

                // Until we run out of ideas
                while (fringe.Size () > 0) {
                    // Remove best partial plan from fringe
                    Plan currentPlan = fringe [0];

                    {
                        // Replace root node w/ right-most leaf node
                        fringe [0] = fringe [fringe.Size () - 1];
                        fringe.Pop ();

                        // Let new root node trickle down until its cost is <= both its children's
                        int index = 0;
                        int childIndex1 = 1;
                        int childIndex2 = 2;

                        while (fringe.Size () > childIndex1) { // Until new node is at bottom of heap
                            double cost = fringe [index].givenCost + fringe [index].heuristicCost;
                            double childCost1 = fringe [childIndex1].givenCost
                                              + fringe [childIndex1].heuristicCost;

                            // Find out which is cheapest: the node, or one of its children
                            int minIndex = index;

                            if (fringe.Size () > childIndex2) {
                                double childCost2 = fringe [childIndex2].givenCost
                                                  + fringe [childIndex2].heuristicCost;

                                if (childCost2 < childCost1 && childCost2 < cost)
                                    minIndex = childIndex2;
                                else if (childCost1 < cost)
                                    minIndex = childIndex1;
                            } else if (childCost1 < cost)
                                minIndex = childIndex1;

                            // Swap node w/ child, if needed
                            if (index != minIndex) {
                                Plan temp = fringe [index];
                                fringe [index] = fringe [minIndex];
                                fringe [minIndex] = temp;

                                index = minIndex;
                                childIndex1 = 2 * index + 1;
                                childIndex2 = childIndex1 + 1;
                            } else
                                break;
                        }
                    }

                    // If plan reaches goal, we're done
                    NavPoint lastNav = currentPlan.path [currentPlan.path.Size () - 1];
                    if (lastNav == goalNav) {
                        Console.PrintF ("(ZScript:PathFinder:A_Star) Path found!");   // DEBUG

                        // path is a stack, so NavPoints go into it in reverse order
                        for (int i = currentPlan.path.Size () - 1; i >= 0; --i)
                            path.Push (currentPlan.path [i]);

                        return;
                    }

                    // Put last NavPoint in closed set
                    closed.Push (lastNav);

                    // Add plans w/ one more NavPoint to fringe
                    int linkCount = lastNav.links.Size ();
                    for (int i = 0; i < linkCount; ++i) {
                        // Don't add plans that include Navs in closed set
                        if (closed.Find (lastNav.links [i]) < closed.Size ())
                            continue;

                        fringe.Push (new ('Plan'));
                        int index = fringe.Size () - 1;

                        fringe [index].path.Copy (currentPlan.path);
                        fringe [index].path.Push (lastNav.links [i]);

                        fringe [index].givenCost = currentPlan.givenCost + lastNav.costs [i];
                        fringe [index].heuristicCost = lastNav.links [i].Distance2D (goalNav);

                        // Let new node bubble up until its cost is >= its parent's
                        while (index > 0) {
                            int parentIndex = (index - 1) / 2;

                            double cost = fringe [index].givenCost + fringe [index].heuristicCost;
                            double parentCost = fringe [parentIndex].givenCost
                                              + fringe [parentIndex].heuristicCost;

                            // Swap node w/ parent, if needed
                            if (parentCost > cost) {
                                Plan temp = fringe [index];
                                fringe [index] = fringe [parentIndex];
                                fringe [parentIndex] = temp;

                                index = parentIndex;
                            } else
                                break;
                        }
                    }
                }

                Console.PrintF ("\c[Yellow](ZScript:PathFinder:A_Star) Warning: No Path found!"); // DEBUG
            }
        }
    }
}