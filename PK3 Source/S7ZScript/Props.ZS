/*** Red Torch ***/
class S7_RedTorchFire : S7_FireBase {
    default {
        alpha 1.0;
        scale 0.25;

        +noInteraction +clientsideOnly
    }

    states {
    Spawn:
        FIR1 ABCDEFHIJKL 1;
        stop;
    Nope:
        TNT1 A 0;
        stop;
    }
}
class S7_RedTorchFireSpawner : actor {
    default {
        +noBlockmap +noGravity +noTeleport +thruActors
        +cannotPush +noInteraction +clientsideOnly
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_CheckSight ("Nope");
        TNT1 AA 0 A_SpawnItemEx ("S7_RedTorchFire", fRandom [sfx] (-4.0, 4.0), fRandom [sfx] (-4.0, 4.0), 0.0, 0.0, 0.0, 1.5);
        stop;
    Nope:
        TNT1 A 0;
        stop;
    }
}
class S7_RedTorch : redTorch replaces redTorch {
    default {
        radius 16;
        height 68;
        projectilePassHeight -16;

        +solid
    }

    states {
    Spawn:
        TRED AAAABBBBBBBBBBBB 1 bright A_SpawnItemEx ("S7_RedTorchFireSpawner", 0.0, 0.0, 78.0, 0.0, 0.0, 0.0, 0.0, SXF_NoCheckPosition | SXF_Clientside);
        loop;
    }
}

/*** Green Torch ***/
class S7_GreenTorchFire : S7_RedTorchFire {
    states {
    Spawn:
        TNT1 A 0 noDelay A_CheckSight ("Nope");
        FIR2 ABCDEFHIJKL 1;
        stop;
    }
}
class S7_GreenTorch : S7_RedTorch replaces greenTorch {
    states {
    Spawn:
        TGRE AAAABBBBCCCCDDDD 1 bright A_SpawnItemEx ("S7_GreenTorchFire", fRandom [sfx] (-1.0, 1.0), fRandom [sfx] (-1.5, 1.5), 65.0, 0.0, 0.0, 2.0, SXF_NoCheckPosition | SXF_Clientside);
        loop;
    }
}

/*** Blue Torch ***/
class S7_BlueTorchFire : S7_RedTorchFire {
    states {
    Spawn:
        TNT1 A 0 noDelay A_CheckSight ("Nope");
        FIR3 ABCDEFHIJKL 1;
        stop;
    }
}
class S7_BlueTorch : S7_RedTorch replaces blueTorch {
    states {
    Spawn:
        TBLU AAAABBBBCCCCDDDD 1 bright A_SpawnItemEx ("S7_BlueTorchFire", fRandom [sfx] (-1.0, 1.0), fRandom [sfx] (-1.0, 1.0), 54.0, 0.0, 0.0, 2.0, SXF_NoCheckPosition | SXF_Clientside);
        loop;
    }
}