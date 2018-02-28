//-------------------------------------------------------------------------------------------
//
// Scout playerclass
//
//-------------------------------------------------------------------------------------------
class S7_ScoutPlayer : S7_BasePlayer {
    default {
        // Damage
        health 75;
        player.maxHealth 75;
        player.mugShotMaxHealth 75;
        gibHealth -37;

        // Movement
        player.forwardMove 1.2, 1.2;
        player.sideMove 1.2, 1.2;
        player.jumpZ 9.797;

        // Class stuff
        player.displayName "Runner";
    }

    override void GiveBasics_ClassSpecific () {
        GiveInventory ("S7_DaggerMelee", 1);
        GiveInventory ("S7_MultiJump_Max", 1); // Scouts can do double jumps from the start
        // Equipment
        GiveInventory ("S7_TEC9", 1);
        GiveInventory ("S7_TEC9Clip", 32);
        GiveInventory ("S7_9mmCartridges", 130);

        S7_BaseWeapon tec9 = S7_TEC9 (FindInventory ("S7_TEC9"));

        if (tec9)
            weapBinds.Binds [2].Push (tec9);

        weapBinds.LastWeapon = tec9;
        EventHandler.SendNetworkEvent ("S7_WeapBindsSystem:slot:2");
    }

    states {
    Spawn:
        PSCT AAAA 1;
        loop;

    See:
        TNT1 A      0 A_JumpIf (stepFrame == true, "See2");
        TNT1 A      0 { stepFrame = true; }
        PSCT AAAAAA 1;
        PSCT BBBBBB 1;
        goto Spawn;
    See2:
        TNT1 A      0 { stepFrame = false; }
        PSCT CCCCCC 1;
        PSCT DDDDDD 1;
        goto Spawn;

    Missile:
        PSCT E 12;
        goto Spawn;
    Melee:
        PSCT F 6 bright;
        goto Missile;

    Pain:
        PSCT G 4;
        PSCT G 4 A_Pain;
        goto Spawn;

    Death.Suicide:
    Death:
        PSCT H  3 A_PlayerScream;
        PSCT I  3;
        PSCT J  3 A_NoBlocking;
        PSCT K  3;
        PSCT L  3;
        PSCT M  3 A_PlaySound ("Misc/Body", CHAN_5);
        PSCT N  3;
        PSCT O -1;
        stop;

    XDeath:
        PSCT H 1;
        PSCT H 2 {
            A_XScream ();
            A_NoBlocking ();
        }
        goto XDeath.Finish;
    /*XDeath:
        PSCT O     5;
        PSCT P     5 A_XScream;
        PSCT Q     5 A_NoBlocking;
        PSCT RSTUV 5;
        PSCT W    -1;
        stop;*/

    Death.Plasma: // Temporarily
        goto Death;
    }
}