//-------------------------------------------------------------------------------------------
//
// Gore actors
//
//-------------------------------------------------------------------------------------------
class S7_GoreBase : actor {
    default {
        mass 1;
        radius 8;
        height 1;

        +corpse +noTeleport +noBlockmap +thruSpecies
    }

    states {
    Raise: // Juuuuust to make sure...
        stop;
    }
}