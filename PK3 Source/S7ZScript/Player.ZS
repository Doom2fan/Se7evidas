// By Chronos "phantombeta" Ouroboros
//-------------------------------------------------------------------------------------------
//
// Inventory tokens
//
//-------------------------------------------------------------------------------------------
class S7_IsPlayer              : S7_Boolean { }
class S7_PlayerHit             : S7_Boolean { }
class S7_IsUnderwater          : S7_Boolean { }
class S7_Dying                 : S7_Boolean { }
class S7_AutoReloading         : S7_Boolean { }
class S7_DisableHud            : S7_Boolean { }
class S7_SoulLance_BeamGrabbed : S7_Boolean { }
class S7_HoldingZoom           : S7_Boolean { }
class S7_ReadySequence         : S7_Boolean { }
class S7_WeapReady             : S7_Boolean { }
/** Weapon slot tokens **/
class S7_Slot1Taken : S7_Boolean { }
class S7_Slot2Taken : S7_Boolean { }
class S7_Slot3Taken : S7_Boolean { }
class S7_Slot4Taken : S7_Boolean { }
class S7_Slot5Taken : S7_Boolean { }
class S7_Slot6Taken : S7_Boolean { }
class S7_Slot7Taken : S7_Boolean { }
class S7_Slot8Taken : S7_Boolean { }
class S7_Slot9Taken : S7_Boolean { }
class S7_Slot0Taken : S7_Boolean { }

/** S7_Counters **/
class S7_AirTime      : S7_Counter { default { inventory.maxAmount 700; } }
class S7_ZoomHoldTime : S7_Counter { }

/** Action Runners **/
class S7_PlayerHitBloodGiver : S7_ActionRunnerBase {
    default {
        inventory.amount 1;
        inventory.maxAmount 1;

        +inventory.undroppable
        -inventory.invBar
    }

    states {
    Use:
        TNT1 A 0 A_JumpIfInventory ("S7_IsPlayer", 1, "Continue");
        TNT1 A 0 A_RailWait;
        stop;
    Continue:
        TNT1 A 0 GiveInventory ("S7_PlayerHit", 1);
        TNT1 A 0 A_RailWait;
        stop;
    }
}

extend class S7_ActorExtensions {
    static bool KeyPressed (Actor act, int key, int ptr = AAPTR_DEFAULT) {
        int newbuttons = (act.GetPlayerInput (MODINPUT_BUTTONS, ptr) ^ act.GetPlayerInput (MODINPUT_OLDBUTTONS, ptr)) & act.GetPlayerInput (MODINPUT_BUTTONS, ptr);

        return (newbuttons & key) == key;
    }
}

//-------------------------------------------------------------------------------------------
//
// Base playerpawn
//
//-------------------------------------------------------------------------------------------
class S7_BasePlayer : playerPawn {
    default {
        // Damage
        gibHealth -50;
        painChance 255;
        painChance "SoulLanceSelfDamage", 0.0;

        // Movement
        player.forwardMove 0.8, 0.8;
        player.sideMove 0.8, 0.8;

        /** Starting items **/
        // Weapons
        /*player.startItem "S7_Raptor";
        player.startItem "S7_RaptorClip", 8;*/
        player.startItem "S7_BerserkWeap";
        // Ammo and similars
        player.startItem "S7_Stamina", 150;
        player.startItem "S7_Mana", 250;
        // Keys/controls
        player.startItem "S7_ReloadKey";
        player.startItem "S7_MeleeKey";
        player.startItem "S7_FiringModeKey";
        player.startItem "S7_ShowPop1Key";
        player.startItem "S7_ToggleShopKey";
        player.startItem "S7_ToggleMenuKey";
        // Tokens:
        player.startItem "S7_IsPlayer";
        player.startItem "S7_StaminaRegen";
        player.startItem "S7_ManaRegen";
        player.startItem "S7_KickMelee";
        player.startItem "S7_MultiJump_Max", 1;

        // Class stuff
        player.displayName "Player";

        // Weapon Slots
        /*player.weaponSlot 1, "S7_Raptor", "S7_TEC9", "S7_Revolver"
        player.weaponSlot 2, "S7_Shotgun", "S7_AMG", "S7_ManxCarbine", "S7_HitterSMG", "S7_Fauchard", "S7_SSG", "S7_LaserPewPew", "S7_ConquerorRifle", "S7_AK47"
        player.weaponSlot 3, "S7_HellwarriorBladeForm1"
        player.weaponSlot 4, "S7_PrettyShootyIonCannonGun", "S7_PlasmaGun", "S7_Thumper", "S7_AntimatterGun"
        player.weaponSlot 5, "S7_GrenadeWeap"
        player.weaponSlot 6, "S7_BerserkWeap"*/

        // Misc
        radius 16;
        height 56;
        player.viewHeight 48;
        player.attackZOffset 20;
        player.invulnerabilityMode "Reflective";
        player.colorRange 112, 127;

        +solid +noSkin
    }

    bool stepFrame;
    actor playerLineTarget;

    override void Tick () {
        super.Tick ();

        playerLineTarget = AimTarget ();
    }

    states {
    Spawn:
        PLAY AAAA 1;
        loop;
    See:
        TNT1 A      0 A_JumpIf (stepFrame == true, "See2");
        TNT1 A      0 { stepFrame = true; }
        PLAY AAAAAA 1;
        PLAY BBBBBB 1;
        goto Spawn;
    See2:
        TNT1 A      0 { stepFrame = false; }
        PLAY CCCCCC 1;
        PLAY DDDDDD 1;
        goto Spawn;
    Missile:
        PLAY E 12;
        goto Spawn;
    Melee:
        PLAY F 6 bright;
        goto Missile;
    Pain:
        PLAY G 4 GiveInventory ("S7_PlayerHit", 1);
        PLAY G 4 A_Pain;
        goto Spawn;
    Death.Suicide:
    Death:
        PLAY H  10 A_PlayerScream;
        PLAY I  10;
        PLAY J  10 A_NoBlocking;
        PLAY K  10;
        TNT1 A   0 A_PlaySound ("Misc/Body", CHAN_5);
        PLAY LM 10;
        PLAY N  -1;
        stop;
    XDeath:
        PLAY O     5;
        PLAY P     5 A_XScream;
        PLAY Q     5 A_NoBlocking;
        PLAY RSTUV 5;
        PLAY W    -1;
        stop;
    Death.Fire2:
    Death.Fire:
        BURN ABC        5 bright;
        BURN D          5 bright;
        BURN EFGHIJKLMN 5 bright;
        BURN O          5 bright A_NoBlocking;
        BURN PQRSTU     5 bright;
        BURN V         -1;
        stop;
    Death.Plasma:
        TNT1 A                  0 Thing_SetTranslation (0, 7);
        TNT1 A                  0 A_SpawnItemEx ("S7_BlackSmoke", random [sfx] (-16, 16), random [sfx] (-16, 16), random [sfx] (8, 16), 0, 0, 1);
        PLAY H                 10 A_PlayerScream;
        PLAY I                 10 A_SpawnItemEx ("S7_BlackSmoke", random [sfx] (-16, 16), random [sfx] (-16, 16), random [sfx] (8, 16), 0, 0, 1);
        TNT1 A                  0 A_SpawnItemEx ("S7_BlackSmoke", random [sfx] (-16, 16), random [sfx] (-16, 16), random [sfx] (8, 16), 0, 0, 1);
        PLAY J                 10 A_NoBlocking;
        PLAY K                 10 A_SpawnItemEx ("S7_BlackSmoke", random [sfx] (-16, 16), random [sfx] (-16, 16), random [sfx] (8, 16), 0, 0, 1);
        TNT1 A                  0 A_SpawnItemEx ("S7_BlackSmoke", random [sfx] (-16, 16), random [sfx] (-16, 16), random [sfx] (8, 16), 0, 0, 1);
        PLAY L                 10 A_PlaySound ("Misc/Body", CHAN_Body);
        PLAY M                 10 A_SpawnItemEx ("S7_BlackSmoke", random [sfx] (-16, 16), random [sfx] (-16, 16), random [sfx] (8, 16), 0, 0, 1);
        TNT1 A                  0 A_SpawnItemEx ("S7_BlackSmoke", random [sfx] (-16, 16), random [sfx] (-16, 16), random [sfx] (8, 16), 0, 0, 1);
        PLAY NNNNNNNNNNNNNNNNNN 5 A_SpawnItemEx ("S7_BlackSmoke", random [sfx] (-16, 16), random [sfx] (-16, 16), random [sfx] (8, 16), 0, 0, 1);
        PLAY N                 -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Null weapon
//
//-------------------------------------------------------------------------------------------
class S7_NullWeapon : weapon {
    default {
        tag "Unarmed";

        +noInteraction
        +inventory.undroppable
        +weapon.wimpy_Weapon +weapon.cheatNotWeapon +weapon.noAlert
    }

    states {
    Spawn:
        TNT1 A 0;
        stop;
    Select:
        TNT1 A 1 A_Raise;
        TNT1 A 0 A_Raise;
        wait;
    Deselect:
        TNT1 A 0 A_Lower;
        wait;
    Ready:
        TNT1 A 1 A_WeaponReady (WRF_NoFire | WRF_NoBob | WRF_DisableSwitch);
        loop;
    Fire:
        TNT1 A 1;
        goto Ready;
    }
}

//-------------------------------------------------------------------------------------------
//
// Sprinting null weapon
//
//-------------------------------------------------------------------------------------------
class S7_Sprinting    : S7_Boolean { }
class S7_SprintWeapon : S7_NullWeapon {
    states {
    Ready:
        TNT1 A  1 GiveInventory ("S7_Sprinting", 1);
        TNT1 AA 1 A_WeaponReady (WRF_NoFire | WRF_NoBob | WRF_DisableSwitch);
    Ready2:
        TNT1 A 0 A_JumpIfInventory ("S7_Sprinting", 1, 1);
        goto Ready3;
        TNT1 A 1 A_WeaponReady (WRF_NoFire | WRF_NoBob | WRF_DisableSwitch);
        loop;
    Ready3:
        TNT1 A 0 GiveInventory ("S7_WeapReady", 1);
        TNT1 A 1 A_WeaponReady (WRF_NoFire | WRF_NoBob);
        loop;
    Deselect:
        TNT1 AA 1 TakeInventory ("S7_Sprinting", 0x7FFFFFFF);
        TNT1 A  1 A_Lower;
        TNT1 A  0 A_Lower;
        wait;
    }
}

//-------------------------------------------------------------------------------------------
//
// Quick melee key
//
//-------------------------------------------------------------------------------------------
class S7_DoMelee  : S7_Boolean { }
class S7_MeleeKey : S7_CustomKey {
    states {
    Use:
        TNT1 A 0 GiveInventory ("S7_DoMelee", 1);
        fail;
    }
}

//-------------------------------------------------------------------------------------------
//
// Reload key
//
//-------------------------------------------------------------------------------------------
class S7_Reloading : S7_Boolean { }
class S7_ReloadKey : S7_CustomKey {
    states {
    Use:
        TNT1 A 0 A_JumpIfInventory ("S7_Reloading", 1, "Take");
        TNT1 A 0 GiveInventory ("S7_Reloading", 1);
        fail;
    Take:
        TNT1 A 0 TakeInventory ("S7_Reloading", 1);
        fail;
    }
}

//-------------------------------------------------------------------------------------------
//
// Change firing mode key
//
//-------------------------------------------------------------------------------------------
class S7_ChangeFireMode : S7_Boolean { }
class S7_FiringModeKey  : S7_CustomKey {
    states {
    Use:
        TNT1 A 0 GiveInventory ("S7_ChangeFireMode", 1);
        fail;
    }
}

//-------------------------------------------------------------------------------------------
//
// Drop weapon key
//
//-------------------------------------------------------------------------------------------
class S7_DropDatWeapon : S7_Boolean { }
class S7_DropWeaponKey : S7_CustomKey {
    states {
    Use:
        TNT1 A 0 GiveInventory ("S7_DropDatWeapon", 1);
        fail;
    }
}

//-------------------------------------------------------------------------------------------
//
// Show popup 1 key (Full inventory list)
//
//-------------------------------------------------------------------------------------------
class S7_ShowPop1Key : S7_CustomKey {
    states {
    Use:
        TNT1 A 0 ACS_NamedExecuteAlways ("S7_ShowPop1", 0);
        fail;
    }
}

//-------------------------------------------------------------------------------------------
//
// Toggle shop key
//
//-------------------------------------------------------------------------------------------
class S7_ToggleShopToken : S7_Boolean { }
class S7_ToggleShopKey   : S7_CustomKey {
    states {
    Use:
        TNT1 A 0 GiveInventory ("S7_ToggleShopToken", 1);
        fail;
    }
}

//-------------------------------------------------------------------------------------------
//
// Toggle menu key
//
//-------------------------------------------------------------------------------------------
class S7_ToggleMenuToken : S7_Boolean { }
class S7_ToggleMenuKey   : S7_CustomKey {
    states {
    Use:
        TNT1 A 0 GiveInventory ("S7_ToggleMenuToken", 1);
        fail;
    }
}

//-------------------------------------------------------------------------------------------
//
// Stamina
//
//-------------------------------------------------------------------------------------------
class S7_StaminaRegen  : S7_Boolean { }
class S7_Stamina       : ammo       { default { inventory.maxAmount 150; +inventory.undroppable -inventory.invBar } }

//-------------------------------------------------------------------------------------------
//
// Mana
//
//-------------------------------------------------------------------------------------------
class S7_ManaRegen     : S7_Boolean { }
class S7_Mana          : ammo       { default { inventory.maxAmount 250; +inventory.undroppable -inventory.invBar } }

//-------------------------------------------------------------------------------------------
//
// Parkour
//
//-------------------------------------------------------------------------------------------
// Multijumping
class S7_MultiJump_Max : S7_Counter { default { inventory.maxAmount 200; } }

// Dodging
class S7_PowerDodgeInvuln : powerInvulnerable {
    default {
        powerup.duration -60;
        inventory.icon "";
    }
}
class S7_PowerDodgeTrail : powerSpeed {
    default {
        speed 1.0;
        powerup.duration 2;
        inventory.icon "";
    }
}

// Walljumping
// Based on code by Ijon Tichy
class S7_WallChecker : fastProjectile {
    default {
        radius 4;
        height 16;

        +thruActors +painless +bloodlessImpact +puffGetsOwner
        +cannotpush +noDamageThrust +noTimeFreeze +moveWithSector
        -activateImpact -activatePCross
    }

    states {
    Spawn:
    Death:
        TNT1 A 1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
//
//-------------------------------------------------------------------------------------------
class GETTHATSHITOUTTAHERE : actor {
    default {
        health -1;
        radius 20;
        height 56;
        mass 500;
        speed 10;
        painChance 100;
        monster;
        seeSound "skeleton/sight";
        painSound "skeleton/sight";
        deathSound "skeleton/sight";
        activeSound "skeleton/sight";

        +invulnerable +noDamage +noClip +missileMore
        +missileEvenMore +floorClip +lookAllAround
        -countKill -solid -shootable -isMonster
    }

    states {
    Spawn:
        SKEL AB 5 A_Look;
        loop;
    See:
        SKEL AABBCCDDEEFF 1 A_Chase;
        loop;
    Melee:
        TNT1 A 0 A_FaceTarget;
        SKEL G 1 A_SkelWhoosh;
        SKEL H 1 A_FaceTarget;
        TNT1 A 0 A_CustomMeleeAttack (0);
        SKEL I 1 A_PlaySound ("skeleton/melee");
        goto See;
    Missile:
        SKEL J 5 bright A_FaceTarget;
        SKEL K 5        A_SpawnProjectile ("GETTHATSHITOUTTAHERETRACER");
        SKEL K 5        A_FaceTarget;
        goto See;
    Pain:
        SKEL L 2;
        SKEL L 2 A_Pain;
        goto See;
    }
}

class GETTHATSHITOUTTAHERETRACER : fastProjectile {
    default {
        radius 11;
        height 8;
        damageFunction (1);
        speed 1000;
        renderStyle "add";
        projectile;
        seeSound "skeleton/attack";
        deathSound "skeleton/tracex";

        +seekerMissile +randomize
    }

    states {
    Spawn:
        FATB AB 1 bright A_Tracer;
        loop;
    Death:
        FBXP ABC 1 bright;
        stop;
    }
}