// From Samsara
class S7_Boolean : inventory {
    default {
        inventory.maxAmount 1;
        inventory.interHubAmount 1;

        +inventory.undroppable
        -inventory.invBar
    }
}

class S7_Counter : inventory {
    default {
        inventory.maxAmount 0x7FFFFFFF;
        inventory.interHubAmount 0x7FFFFFFF;

        +inventory.undroppable
        -inventory.invBar
    }
}

// By Jekyll Grim Payne "Aka" zer0
class S7_DebrisGeneral : Actor {
    default {
        radius 1;
        height 1;
        mass 1;
        damage 0;

        +missile +noBlockmap +noGravity +dropOff
        +noTeleport +forceXYBillboard +ghost
    }
}

// By Chronos "phantombeta" Ouroboros
//-------------------------------------------------------------------------------------------
//
// Action runner item base
//
//-------------------------------------------------------------------------------------------
class S7_ActionRunnerBase : customInventory {
    default {
        inventory.maxAmount 1;

        +inventory.autoActivate +inventory.quiet +inventory.alwaysPickup
    }

    states {
    Spawn:
        TNT1 A 0;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Custom key base
//
//-------------------------------------------------------------------------------------------
class S7_CustomKey : customInventory {
    default {
        inventory.amount 1;
        inventory.maxAmount 1;

        +inventory.undroppable
        -inventory.invBar
    }
}

//-------------------------------------------------------------------------------------------
//
// Distance testing puff
//
//-------------------------------------------------------------------------------------------
class S7_DistanceTestPuff : actor {
    default {
        damage 0;
        damageType "TesterProjectile";
        alpha 0.0;
        scale 0.0;
        decal "None";

        +bloodlessImpact +painless +noPain +puffGetsOwner
        +noTimeFreeze
    }

    states {
    Spawn:
    Death:
    Crash:
    Crush:
        TNT1 A 1 A_Jump (256, "RunStuff");
        wait;
    RunStuff:
        TNT1 A 2;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Distance testing projectile
//
//-------------------------------------------------------------------------------------------
class S7_DistanceTestProjectile : fastProjectile {
    default {
        speed 25;
        projectile;
        damage 0;
        damageType "TesterProjectile";
        alpha 0.0;
        scale 0.0;
        decal "None";

        +bloodlessImpact +painless +noPain +noTimeFreeze
    }

    states {
    Spawn:
        TNT1 A 2;
        stop;
    }
}