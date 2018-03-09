/*** Red Torch ***/
class S7_RedTorchFire : S7_FireBase {
    default {
        Alpha 1.0;
        Scale 0.25;

        +NOINTERACTION +CLIENTSIDEONLY
    }

    states {
    Spawn:
        FIR1 ABCDEFHIJKL 1 bright;
        stop;
    Nope:
        TNT1 A 0;
        stop;
    }
}
class S7_RedTorchFireSpawner : Actor {
    default {
        +NOBLOCKMAP +NOGRAVITY  +NOTELEPORT +NOINTERACTION
        +CANNOTPUSH +THRUACTORS +CLIENTSIDEONLY
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
class S7_RedTorch : RedTorch replaces RedTorch {
    default {
        Radius 16;
        Height 68;
        ProjectilePassHeight -16;

        +SOLID
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
        FIR2 ABCDEFHIJKL 1 bright;
        stop;
    }
}
class S7_GreenTorch : S7_RedTorch replaces GreenTorch {
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
        FIR3 ABCDEFHIJKL 1 bright;
        stop;
    }
}
class S7_BlueTorch : S7_RedTorch replaces BlueTorch {
    states {
    Spawn:
        TBLU AAAABBBBCCCCDDDD 1 bright A_SpawnItemEx ("S7_BlueTorchFire", fRandom [sfx] (-1.0, 1.0), fRandom [sfx] (-1.0, 1.0), 54.0, 0.0, 0.0, 2.0, SXF_NoCheckPosition | SXF_Clientside);
        loop;
    }
}