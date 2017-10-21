// By Chronos "phantombeta" Ouroboros
//-------------------------------------------------------------------------------------------
//
// Inventory tokens
//
//-------------------------------------------------------------------------------------------
class S7_Dying                 : S7_Boolean { }
class S7_AutoReloading         : S7_Boolean { }
class S7_DisableHud            : S7_Boolean { }
class S7_SoulLance_BeamGrabbed : S7_Boolean { }
class S7_HoldingZoom           : S7_Boolean { }

extend class S7_ActorExtensions {
    static bool KeyPressed (Actor act, int key) {
        if (!act.player)
            return false;

        int newbuttons = (act.player.cmd.buttons ^ act.player.oldbuttons & act.player.cmd.buttons);

        return (newbuttons & key) == key;
    }
}

class S7_PlayerData : Inventory {
    /** Movement **/
    // Dodging
    int dodgeCooldown;
    // Sprinting
    bool   sprinting;
    int    sprintTics, oldAgility; // sprintTics: Used to remove stamina. If this is -1, stamina was depleted by sprinting.
                                   // oldAgility: This is used for checking if the agility stat changed.
    double sprintSpeedFactor, sprintSpdFacPproc; // sprintSpdFacPproc: This is here to store the speed factor to avoid having to make lots of expensive log calls.

    override double GetSpeedFactor () {
        return 1 + sprintSpeedFactor;
    }

    override void AttachToOwner (Actor other) {
        super.AttachToOwner (other);
        oldAgility = -1;
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
    S7_XPSystemWorker xpSys;
    S7_WeapBindsSystem weapBinds;
    S7_PlayerData playerData;

    override void PostBeginPlay () {
        super.PostBeginPlay ();

        if (player && player.mo) {
            let pPawn = player.mo;

            xpSys = S7_XPSystemWorker (pPawn.FindInventory ("S7_XPSystemWorker"));
            weapBinds = S7_WeapBindsSystem (pPawn.FindInventory ("S7_WeapBindsSystem"));
            playerData = S7_PlayerData (pPawn.FindInventory ("S7_PlayerData"));

            if (self == player.mo) {
                if (!xpSys) {
                    pPawn.GiveInventory ("S7_XPSystemWorker", 1);
                    xpSys = S7_XPSystemWorker (pPawn.FindInventory ("S7_XPSystemWorker"));
                }
                if (!weapBinds) {
                    pPawn.GiveInventory ("S7_WeapBindsSystem", 1);
                    weapBinds = S7_WeapBindsSystem (pPawn.FindInventory ("S7_WeapBindsSystem"));
                }
                if (!playerData) {
                    pPawn.GiveInventory ("S7_PlayerData", 1);
                    playerData = S7_PlayerData (pPawn.FindInventory ("S7_PlayerData"));
                }
            }
        }
    }

    override void Tick () {
        super.Tick ();

        playerLineTarget = AimTarget ();
        if (player && player.mo) {
            let pPawn = player.mo;

            if (self == player.mo) {
                if (!xpSys) {
                    if (!(xpSys = S7_XPSystemWorker (pPawn.FindInventory ("S7_XPSystemWorker")))) {
                        pPawn.GiveInventory ("S7_XPSystemWorker", 1);
                        xpSys = S7_XPSystemWorker (pPawn.FindInventory ("S7_XPSystemWorker"));
                    }
                }
                if (!weapBinds) {
                    if (!(weapBinds = S7_WeapBindsSystem (pPawn.FindInventory ("S7_WeapBindsSystem")))) {
                        pPawn.GiveInventory ("S7_WeapBindsSystem", 1);
                        weapBinds = S7_WeapBindsSystem (pPawn.FindInventory ("S7_WeapBindsSystem"));
                    }
                }
                if (!playerData) {
                    if (!(playerData = S7_PlayerData (pPawn.FindInventory ("S7_PlayerData")))) {
                        pPawn.GiveInventory ("S7_PlayerData", 1);
                        playerData = S7_PlayerData (pPawn.FindInventory ("S7_PlayerData"));
                    }
                }

                Movement_Dodging ();
                Movement_Sprinting ();
            }
        }
    }

    void Movement_Dodging () {
        if (health > 0) {
            // Dodging
            if (playerData.dodgeCooldown <= 0) { // If dodgeCooldown is less than or equal to 0...
                // If the player tapped user2, isn't sprinting, didn't have his Soul Lance beam grabbed and has at least S7C_DodgeStamina stamina...
                if (!(player.cmd.buttons & BT_USER2) && (player.oldbuttons & BT_USER2) &&
                    !playerData.sprinting && !CheckInventory ("S7_SoulLance_BeamGrabbed", 1) && CheckInventory ("S7_Stamina", S7C_DodgeStamina)) {
                    int forwardMove = Clamp (player.cmd.forwardmove / 12800, -1.0, 1.0);
                    int sideMove = Clamp (player.cmd.sidemove / 10240, -1.0, 1.0);

                    if (forwardMove != 0 || sideMove != 0) { // If the player is trying to move
                        TakeInventory ("S7_Stamina", S7C_DodgeStamina); // Take S7C_DodgeStamina stamina

                        A_PlaySound ("Player/Dodge", CHAN_Body); // Play the dodge sound

                        GiveInventory ("S7_PowerDodgeEffects", 1);
                        Thrust (18, (angle - 90) + atan2 (forwardMove, sideMove));
                        vel.Z += -85;

                        playerData.dodgeCooldown = S7_DodgeCooldown;
                    }
                }
            } else
                playerData.dodgeCooldown--;
        } else
            TakeInventory ("S7_PowerDodgeEffects", 0x7FFFFFFF);
    }

    void Movement_Sprinting () {
        double forwardMove = abs (player.cmd.forwardmove) / 12800;
        double sideMove = abs (player.cmd.sidemove) / 10240;

        if (health > 0) {
            // This is here just in case something fucks up and the player keeps the sprint "weapon" for some reason.
            if (player.ReadyWeapon is "S7_SprintWeapon" && !playerData.sprinting)
                player.PendingWeapon = weapBinds.LastWeapon;
            else if (!playerData.sprinting && CheckInventory ("S7_SprintWeapon", 1))
                TakeInventory ("S7_SprintWeapon", 0x7FFFFFFF);

            if (playerData.sprintTics == -1 && CheckInventory ("S7_Stamina", 75))
                playerData.sprintTics = 0;

            // Start/stop sprinting
            if (!playerData.sprinting && playerData.sprintTics != -1 && (player.cmd.buttons & BT_USER1) && !CheckInventory ("S7_SoulLance_BeamGrabbed", 1) && CheckInventory ("S7_Stamina", S7C_SprintStamina)) {
                playerData.sprinting = true;
                playerData.sprintSpeedFactor = playerData.sprintSpdFacPproc = 0.0;
                playerData.sprintTics = 0;
                playerData.oldAgility = -1;

                GiveInventory ("S7_SprintWeapon", 1);
                player.PendingWeapon = Weapon (FindInventory ("S7_SprintWeapon"));
            } else if (playerData.sprinting && (!(player.cmd.buttons & BT_USER1) || CheckInventory ("S7_SoulLance_BeamGrabbed", 1) || CountInv ("S7_Stamina") < S7C_SprintStamina)) {
                if (playerData.sprintTics < 5)
                    TakeInventory ("S7_Stamina", playerData.sprintTics);

                playerData.sprinting = false;
                playerData.sprintSpeedFactor = playerData.sprintSpdFacPproc = 0.0;
                playerData.sprintTics = (!CheckInventory ("S7_Stamina", 5)) ? -1 : 0;

                player.PendingWeapon = weapBinds.LastWeapon;
            }
            if (playerData.sprinting && player.ReadyWeapon is "S7_SprintWeapon") {
                if (playerData.sprintTics++ >= 5 && (forwardMove != 0.0 || sideMove != 0.0)) {
                    playerData.sprintTics = 0;
                    TakeInventory ("S7_Stamina", S7C_SprintStamina);
                } else if ((forwardMove != 0.0 || sideMove != 0.0) && (vel.X != 0.0 || vel.Y != 0.0))
                    playerData.sprintTics++;

                int newAgility = GetAgilityStat ();
                if (newAgility != playerData.oldAgility) {
                    if (newAgility > 0) // Just so it doesn't explode
                        playerData.sprintSpdFacPproc = 0.1 * log (newAgility);
                    else
                        playerData.sprintSpdFacPproc = 0;
                    playerData.oldAgility = newAgility;
                }

                if (forwardMove > 0.5 || sideMove > 0.5)
                    playerData.sprintSpeedFactor = Clamp (0.5 + playerData.sprintSpdFacPproc, 0.0, 2.5);
                else
                    playerData.sprintSpeedFactor = Clamp (0.5 + (0.5 + playerData.sprintSpdFacPproc) * 2, 0.0, 2.5);
            }
        }
    }

    clearscope int GetStrengthStat () { return ((xpSys) ? xpSys.strengthStat : 0); }
    clearscope int GetAgilityStat  () { return ((xpSys) ? xpSys.agilityStat  : 0); }
    clearscope int GetVitalityStat () { return ((xpSys) ? xpSys.vitalityStat : 0); }
    clearscope int GetDefenseStat  () { return ((xpSys) ? xpSys.defenseStat  : 0); }
    clearscope int GetWillStat     () { return ((xpSys) ? xpSys.willStat     : 0); }
    clearscope int GetMagicStat    () { return ((xpSys) ? xpSys.magicStat    : 0); }
    clearscope int GetTechStat     () { return ((xpSys) ? xpSys.techStat     : 0); }

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
// Null weapon(s)
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
        stop;

    Select:
        TNT1 A 0 A_Raise;
        wait;
    Deselect:
        TNT1 A 0 A_Lower;
        wait;
    Ready:
        TNT1 A 1 A_WeaponReady (WRF_NoFire | WRF_NoBob);// | WRF_DisableSwitch);
        loop;
    Fire:
        TNT1 A 1;
        goto Ready;
    }
}
class S7_SprintWeapon : S7_NullWeapon { }

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