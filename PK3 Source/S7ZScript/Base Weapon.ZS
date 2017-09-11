//-------------------------------------------------------------------------------------------
//
// Melee type tokens
//
//-------------------------------------------------------------------------------------------
/* Credits:
** Sprites: Apocalyptic Studio, Captain J, Chronos "phantombeta" Ouroboros
** Animation: Chronos "phantombeta" Ouroboros
** Sounds: Credits in the SNDINFO file
*/
class S7_DaggerMelee  : S7_Boolean { }

/* Credits:
** Sprites: Id Software, ???, Chronos "phantombeta" Ouroboros
** Animation: Chronos "phantombeta" Ouroboros
** Sounds: Credits in the SNDINFO file
*/
class S7_PunchMelee : S7_Boolean { }

/* Credits:
** Sprites: ???, Chronos "phantombeta" Ouroboros
** Animation: Chronos "phantombeta" Ouroboros
** Sounds: Credits in the SNDINFO file
*/
class S7_KickMelee    : S7_Boolean { }

//-------------------------------------------------------------------------------------------
//
// Base weapon
//
//-------------------------------------------------------------------------------------------
class S7_BaseWeapon : weapon {
    default {
        inventory.pickupSound "misc/gunpickup";
        weapon.bobRangeX 0.3;
        weapon.bobRangeY 0.5;
        weapon.bobSpeed 2.0;
        weapon.bobStyle "inverseSmooth";
        weapon.kickback 100;

        +inventory.undroppable
        +weapon.ammo_Optional +weapon.noAutoFire +weapon.noAlert
    }

    int fireModeIcon; // 0: none, 1: semi-auto, 2: burst-fire, 3: full-auto.

    states {
    DryFire:
        TNT1 A 0 {
            A_PlaySound ("Weapons/DryFire", CHAN_Weapon);

            if (CheckInventory ("S7_AutoReloading", 1))
                return ResolveState ("Reload");

            return ResolveState (null);
        }
        TNT1 A 0 A_Jump (256, "Ready2");
        wait;

    Ready:
        TNT1 A 0 A_Jump (256, "Ready2");
        wait;
    Fire:
        TNT1 A 1;
        goto Ready;

    Select:
    TrueSelect:
        TNT1 A 0 {
            TakeInventory ("S7_WeapReady", 0x7FFFFFFF);
            A_Raise ();
        }
        loop;
    Deselect:
    TrueDeselect:
        TNT1 A 0 {
            TakeInventory ("S7_HoldingZoom", 0x7FFFFFFF);
            TakeInventory ("S7_Weap_ReadyFrame", 0x7FFFFFFF);
            TakeInventory ("S7_WeapReady", 0x7FFFFFFF);
            A_ZoomFactor (1.0);

            if (!health)
                return ResolveState ("Deselect.DEAD");

            A_Lower ();
            return ResolveState (null);
        }
        loop;
    Deselect.DEAD:
        TNT1 A 1 A_Lower;
        wait;

    QuickMelee:
        TNT1 A 0 {
            TakeInventory ("S7_DoMelee", 0x7FFFFFFF);
            if (CheckInventory ("S7_DaggerMelee", 1))
                return ResolveState ("DaggerMelee");
            if (CheckInventory ("S7_PunchMelee", 1))
                return ResolveState ("PunchMelee");
            if (CheckInventory ("S7_KickMelee", 1))
                return ResolveState ("KickMelee");

            return ResolveState ("KickMelee");
        }

    DaggerMelee:
        TNT1 A 0 A_Jump (256, "DaggerMelee1", "DaggerMelee2");
        wait;
    DaggerMelee1:
        DAG1 ABCD 1;
        DAG1 E    1 A_CustomPunch (callACS ("S7_MeleeDamage", 3, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_DaggerPuffSilent");
        DAG1 F    1 A_CustomPunch (callACS ("S7_MeleeDamage", 3, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_DaggerPuff");
        DAG1 G    1 A_CustomPunch (callACS ("S7_MeleeDamage", 3, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_DaggerPuffSilent");
        DAG1 H    1;
        TNT1 A    5;
        TNT1 A    0 A_Jump (256, "MeleeDone");
        wait;
    DaggerMelee2:
        DAG2 AB  1;
        DAG2 C   1 A_CustomPunch (callACS ("S7_MeleeDamage", 2, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_DaggerPuffSilent");
        DAG2 D   1 A_CustomPunch (callACS ("S7_MeleeDamage", 2, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_DaggerPuff");
        DAG2 EF  1 A_CustomPunch (callACS ("S7_MeleeDamage", 2, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_DaggerPuffSilent");
        DAG2 GH  1;
        TNT1 A   5;
        TNT1 A   0 A_Jump (256, "MeleeDone");
        wait;

    PunchMelee:
        TNT1 A 0 A_Jump (256, "MeleeDone");
        wait;

    KickMelee:
        KICK BCD   1;
        KICK H     1 A_CustomPunch (callACS ("S7_MeleeDamage", 13, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_MeleePuff");
        KICK HHHIG 1;
        KICK FEDCB 1;
        KICK A     1;

        TNT1 A 0 A_Jump (256, "MeleeDone");
        wait;

    MeleeDone:
        TNT1 A 0 A_JumpIfInventory ("S7_DoMelee", 1, "QuickMelee");
        TNT1 A 0 A_Jump (256, "Ready");
        wait;
    }
}

//-------------------------------------------------------------------------------------------
//
// Melee puffs
//
//-------------------------------------------------------------------------------------------
class S7_MeleePuff : actor { // By Jekyll Grim Payne/zer0, edited by Chronos "phantombeta" Ouroboros
    default {
        damageType "Kick";
        attackSound "Weapons/Kick/HitWall";
        activeSound "Weapons/Kick/Swing";

        +noBlockmap +noGravity +puffOnActors +noExtremeDeath
    }
}

class S7_MeleePuffStrong : S7_MeleePuff { // Ditto
    default {
        decal "FistScorch";
        attackSound "Weapons/Kick/Strong";
        activeSound "Weapons/Kick/Swing";

        +extremeDeath
        -noExtremeDeath
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnItem ("S7_ShotSmoke");
        stop;
    }
}

class S7_DaggerPuff : S7_MeleePuff {
    default {
        damageType "Blade";
        attackSound "Weapons/Tridagger/HitWall";
        activeSound "Weapons/Tridagger/Swing";
    }
}
class S7_DaggerPuffSilent : S7_DaggerPuff {
    default {
        attackSound "";
        activeSound "";
    }
}

//-------------------------------------------------------------------------------------------
//
// Misc crap
//
//-------------------------------------------------------------------------------------------
class S7_Unarmed : S7_BaseWeapon { default { tag "$UNARMED"; } }