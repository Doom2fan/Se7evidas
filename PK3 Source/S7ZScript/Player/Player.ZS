// By Chronos "phantombeta" Ouroboros
//-------------------------------------------------------------------------------------------
//
// Inventory tokens
//
//-------------------------------------------------------------------------------------------
class S7_Dying                 : S7_Boolean { }
class S7_DisableHud            : S7_Boolean { }
class S7_SoulLance_BeamGrabbed : S7_Boolean { }
class S7_HoldingZoom           : S7_Boolean { }

class S7_PlayerData : Inventory {
    /** Health **/
    bool dying;
    /** Movement **/
    // Dodging
    int dodgeCooldown;
    // Multijump
    int mJumpCount;
    // Walljump
    int wjumpJustJumped;
    // Sprinting
    bool   sprinting;
    int    sprintTics; // sprintTics: Used to remove stamina. If this is -1, stamina was depleted by sprinting.
    double oldAgility; // oldAgility: This is used for checking if the agility stat changed.
    double sprintSpeedFactor, sprintSpdFacPproc; // sprintSpdFacPproc: This is here to store the speed factor to avoid having to make lots of expensive log calls.
    /** Weapons **/
    double ammoMaxMult;
    /** Misc **/
    // Shop menu
    bool transactDone, transactSell;
    int transactResult;
    // Stamina regen
    int staminaTics;
    // Canteen
    int milkUseRate, milkRegenRate;
    // Heartbeats thing.
    int heartbeatTics;

    override double GetSpeedFactor () {
        return 1 + sprintSpeedFactor;
    }

    override void AttachToOwner (Actor other) {
        super.AttachToOwner (other);
        dying = sprinting = false;
        dodgeCooldown = mjumpCount = wjumpJustJumped = sprintTics = staminaTics = heartbeatTics = 0;
        sprintSpeedFactor = sprintSpdFacPproc = 0;
        oldAgility = double.NaN;
        milkRegenRate = 5;
        milkUseRate = 25;
    }
}

//-------------------------------------------------------------------------------------------
//
// Base playerpawn
//
//-------------------------------------------------------------------------------------------
class S7_BasePlayer : playerPawn {
    // This class is split across this file and the PlayerE_*.ZS files for readability reasons
    default {
        // Damage
        gibHealth -50;
        painChance 255;
        painChance "SoulLanceSelfDamage", 0.0;

        // Movement
        player.forwardMove 0.8, 0.8;
        player.sideMove 0.8, 0.8;

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
    S7_PlayerXPSystem xpSys;
    S7_WeapBindsSystem weapBinds;
    S7_PlayerData playerData;

    void GiveBasics () {
        if (!player || player.mo != self)
            return;

        bool doGive = !playerData && !weapBinds && !xpSys;

        if (!playerData) {
            if (!(playerData = S7_PlayerData (FindInventory ("S7_PlayerData")))) {
                GiveInventory ("S7_PlayerData", 1);
                playerData = S7_PlayerData (FindInventory ("S7_PlayerData"));
            }
        }
        if (!weapBinds) {
            if (!(weapBinds = S7_WeapBindsSystem (FindInventory ("S7_WeapBindsSystem")))) {
                GiveInventory ("S7_WeapBindsSystem", 1);
                weapBinds = S7_WeapBindsSystem (FindInventory ("S7_WeapBindsSystem"));
            }
        }
        if (!xpSys) {
            if (!(xpSys = S7_PlayerXPSystem (FindInventory ("S7_PlayerXPSystem")))) {
                GiveInventory ("S7_PlayerXPSystem", 1);
                xpSys = S7_PlayerXPSystem (FindInventory ("S7_PlayerXPSystem"));
            }
        }

        if (doGive) {
            Weapon_SetAmmoMax ();

            if (S7_InitialCashAmount > 0)
                GiveInventory ("S7_Cash", S7_InitialCashAmount);
            GiveInventory ("S7_BerserkWeap", 1);

            // Equipment
            GiveInventory ("S7_Canteen", 2000);
            // Ammo and similars
            GiveInventory ("S7_Stamina", 0x7FFFFFFF);
            GiveInventory ("S7_Mana", 0x7FFFFFFF);
            // Tokens
            GiveInventory ("S7_StaminaRegen", 1);
            GiveInventory ("S7_ManaRegen", 1);
            
            GiveBasics_ClassSpecific ();
        }
    }

    virtual void GiveBasics_ClassSpecific () {
        GiveInventory ("S7_KickMelee", 1); // Default to kick melee
    }

    override void PostBeginPlay () {
        super.PostBeginPlay ();

        if (!playerData || !weapBinds || !xpSys)
            GiveBasics ();
    }

    override void Tick () {
        super.Tick ();

        FTranslatedLineTarget lTarget; // Do a trace to get the actor under the crosshair
        let puff = LineAttack (angle, 8192, pitch, 0, "None", "S7_TraceTestPuff", LAF_NoRandomPuffZ | LAF_NoImpactDecal, lTarget);
        if (puff) puff.Destroy ();
        playerLineTarget = lTarget.linetarget;

        if (!player || !player.mo || player.mo != self)
            return;

        if (!playerData || !weapBinds || !xpSys)
                GiveBasics ();

        if (!(player.cmd.buttons & BT_RELOAD) && (player.oldbuttons & BT_RELOAD))
            SetInventory ("S7_Reloading", !CheckInventory ("S7_Reloading", 1));

        playerData.dying = health < (maxHealth * 0.2);

        // Movement
        Movement_Dodging ();
        Movement_WallJump ();
        Movement_MultiJump ();
        Movement_Sprinting ();
        // Weapons
        Weapon_SetAmmoMax ();
        // Misc
        Misc_StaminaRegen ();
        Misc_Heartbeats ();
        Misc_HellhunterBlade ();
    }

    clearscope int S7_GetMaxHealth () { return ((xpSys) ? (SpawnHealth () * (1.0 + 0.06 * xpSys.GetStat (S7Stat_Vitality))) : 0); }
    clearscope int GetMaxStamina   () { return ((xpSys) ? (150 + 10 * xpSys.GetStat (S7Stat_Agility)) : 0); }
    clearscope int GetMaxMana      () { return ((xpSys) ? (250 + 15 * xpSys.GetStat (S7Stat_Magic))   : 0); }

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
        PLAY G 4;
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
// Keys
//
//-------------------------------------------------------------------------------------------
class S7_Reloading : S7_Boolean { }
class S7_DoMelee  : S7_Boolean { }
class S7_ChangeFireMode : S7_Boolean { }
class S7_DropDatWeapon : S7_Boolean { }

class S7_ShowPop1Key : S7_CustomKey {
    states {
    Use:
        TNT1 A 0 ACS_NamedExecuteAlways ("S7_ShowPop1", 0);
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
class S7_DodgeTrail : PlayerSpeedTrail { default { renderStyle "Shadow"; } }
class S7_PowerDodgeEffects : powerInvulnerable {
    default {
        inventory.interHubAmount 0; // I dunno, just in case...
        inventory.icon "";
        powerup.duration 24;

        +inventory.noTeleportFreeze
    }

    override void DoEffect () {
        Super.DoEffect ();

        if (!Owner || !Owner.player) // Return if it doesn't have an owner
            return;

        if (Owner.player.cheats & CF_PREDICTING) // Return if running player prediction
            return;

        if (level.time & 1)
            return;

        Actor speedMo = Spawn ("S7_DodgeTrail", Owner.Pos, NO_REPLACE);
        if (speedMo) {
            speedMo.Angle = Owner.Angle;
            speedMo.Translation = Owner.Translation;
            speedMo.target = Owner;
            speedMo.sprite = Owner.sprite;
            speedMo.frame = Owner.frame;
            speedMo.Floorclip = Owner.Floorclip;

            // [BC] Also get the scale from the owner.
            speedMo.Scale = Owner.Scale;

            if (Owner == players[consoleplayer].camera &&
                !(Owner.player.cheats & CF_CHASECAM)) {
                speedMo.bInvisible = true;
            }
        }
    }
}

// Walljumping
class S7_WalljumpMarker : actor {
    default {
        radius 0;
        height 0;

         +thruActors +noTimeFreeze +noBlockmap +allowThruFlags
        +noInteraction
        -solid -shootable
    }

    states {
    Spawn:
    Death:
        TNT1 A 1;
        stop;
    }
}
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