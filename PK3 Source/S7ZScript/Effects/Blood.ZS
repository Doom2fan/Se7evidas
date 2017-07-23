//-------------------------------------------------------------------------------------------
//
// Blood actors
//
//-------------------------------------------------------------------------------------------
class S7_Blood : blood replaces blood {
    default {
        +puffGetsOwner +noBlockmap +noTeleport
    }

    states {
    Spawn:
        BLUD C  1 noDelay {
            A_SpawnDebris ("S7_Flying_Blood", true); // A_SpawnItemEx ("S7_Flying_Blood", 0.0, fRandom [sfx] (-0.5, 0.5), 0.0, fRandom [sfx] (2.0, 4.0), 0.0, fRandom [sfx] (1.0, 8.0), 0, SXF_TransferTranslation)
            if (target)
                target.GiveInventory ("S7_PlayerHitBloodGiver", 1);
        }
        BLUD BA 1;
        stop;
    }
}

class S7_BloodSplatter : S7_Blood replaces bloodSplatter {
    states {
    Spawn:
        TNT1 A 0 noDelay {
            A_ChangeVelocity (0.0, 0.0, 0.0, CVF_Replace);
            A_SpawnItemEx ("S7_Blood", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, SXF_TransferTranslation);
        }
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Flying blood actors
//
//-------------------------------------------------------------------------------------------
class S7_Flying_Blood : actor {
    default {
        health 1;
        mass 1;
        radius 8;
        height 1;

        +corpse +noTeleport +noBlockmap +thruSpecies
        +clientsideOnly
    }

    states {
    Spawn:
        BLUD CCCBBBAAA 1 noDelay A_SpawnItemEx ("S7_Flying_Blood_Trail", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, SXF_TransferTranslation);
        loop;
    Death:
    Crush:
    Crash:
        TNT1 A 1;
        stop;
    }
}

class S7_Flying_Blood_Trail : actor {
    default {
        +lowGravity +noTeleport +noBlockmap +clientsideOnly
        +noInteraction
    }

    states {
    Spawn:
        BLUD CCBBAA 1;
        stop;
    }
}