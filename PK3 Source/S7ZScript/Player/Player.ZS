/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2019 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// By Chronos "phantombeta" Ouroboros
//-------------------------------------------------------------------------------------------
//
// Inventory tokens
//
//-------------------------------------------------------------------------------------------
class S7_DisableHud            : S7_Boolean { }
class S7_SoulLance_BeamGrabbed : S7_Boolean { }
class S7_HoldingZoom           : S7_Boolean { }

struct S7_TransactionData {
    bool done;
    int result;
}
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
    // Ledge grabbing
    bool  lGrabGrabbed;
    Actor lGrabMarker;
    /** Misc **/
    // Shop menu
    S7_TransactionData transactData;
    // Stamina regen
    int staminaTics;
    // Berserk side-effects
    int bsrkMaxAddiction;
    int bsrkAddiction;
    int bsrkWithdrawalTics;
    // Canteen
    int milkUseRate, milkRegenRate;
    // Heartbeats thing.
    int heartbeatTics;
    // Hack for getting viewbob in morphed players
    double bob;

    override void AttachToOwner (Actor other) {
        Super.AttachToOwner (other);
        dying = false;
        dodgeCooldown = mjumpCount = wjumpJustJumped = staminaTics = heartbeatTics = 0;
        milkRegenRate = 2;
        milkUseRate = 20;
    }
}

//-------------------------------------------------------------------------------------------
//
// Base playerpawn
//
//-------------------------------------------------------------------------------------------
class S7_BasePlayer : PlayerPawn {
    // This class is split across this file and the PlayerE_*.ZS files for readability reasons

    string classDesc;
    property ClassDescription: classDesc;

    default {
        S7_BasePlayer.ClassDescription "";

        // Damage
        GibHealth -50;
        PainChance 255;
        PainChance "SoulLanceSelfDamage", 0.0;

        // Movement
        Player.ForwardMove 0.8, 0.8;
        Player.SideMove 0.8, 0.8;

        // Class stuff
        Player.DisplayName "Player";

        // Weapon Slots
        /*player.weaponSlot 1, 'S7_Raptor', 'S7_TEC9', 'S7_Revolver'
        player.weaponSlot 2, 'S7_Shotgun', 'S7_AMG', 'S7_ManxCarbine', 'S7_HitterSMG', 'S7_Fauchard', 'S7_SSG', 'S7_LaserPewPew', 'S7_ConquerorRifle', 'S7_AK47'
        player.weaponSlot 3, 'S7_HellwarriorBladeForm1'
        player.weaponSlot 4, 'S7_PrettyShootyIonCannonGun', 'S7_PlasmaGun', 'S7_Thumper', 'S7_AntimatterGun'
        player.weaponSlot 5, 'S7_GrenadeWeap'
        player.weaponSlot 6, 'S7_BerserkWeap'*/

        // Misc
        Radius 16;
        Height 56;
        Player.ViewHeight 48;
        Player.AttackZOffset 20;
        Player.InvulnerabilityMode "Reflective";
        Player.ColorRange 112, 127;

        +SOLID +NOSKIN
    }

    S7_PlayerXPSystem xpSys;
    S7_WeapBindsSystem weapBinds;
    S7_PlayerData playerData;
    S7_HealingSystem healSys;

    bool stepFrame;
    actor playerLineTarget;
    actor damageInflictor, damageSource;

    // Sprinting
    bool   sprint_Sprinting;
    int    sprint_Tics; // sprintTics: Used to remove stamina. If this is -1, stamina was depleted by sprinting.
    double sprint_OldAgility; // oldAgility: This is used for checking if the agility stat changed.
    double sprint_SpeedFactor, sprint_SpdFacPproc; // sprintSpdFacPproc: This is here to store the speed factor to avoid having to make lots of expensive log calls.

    void GiveBasics () {
        if (!player || player.mo != self)
            return;

        int giveCount = 0;

        if (!playerData) {
            if (!(playerData = S7_PlayerData (FindInventory ('S7_PlayerData')))) {
                GiveInventory ('S7_PlayerData', 1);
                playerData = S7_PlayerData (FindInventory ('S7_PlayerData'));
                giveCount++;
            }
        }
        if (!weapBinds) {
            if (!(weapBinds = S7_WeapBindsSystem (FindInventory ('S7_WeapBindsSystem')))) {
                GiveInventory ('S7_WeapBindsSystem', 1);
                weapBinds = S7_WeapBindsSystem (FindInventory ('S7_WeapBindsSystem'));
                giveCount++;
            }
        }
        if (!xpSys) {
            if (!(xpSys = S7_PlayerXPSystem (FindInventory ('S7_PlayerXPSystem')))) {
                GiveInventory ('S7_PlayerXPSystem', 1);
                xpSys = S7_PlayerXPSystem (FindInventory ('S7_PlayerXPSystem'));
                giveCount++;
            }
        }
        if (!healSys) {
            if (!(healSys = S7_HealingSystem (FindInventory ('S7_HealingSystem')))) {
                GiveInventory ('S7_HealingSystem', 1);
                healSys = S7_HealingSystem (FindInventory ('S7_HealingSystem'));
                giveCount++;
            }
        }
        if (!FindInventory ('S7_BasicArmor')) {
            let armor = S7_BasicArmor (Spawn ('S7_BasicArmor'));
            armor.BecomeItem ();
            AddInventory (armor);
            giveCount++;
        }

        if (giveCount >= 4) {
            Weapon_SetAmmoMax ();

            if (S7_InitialCashAmount > 0)
                GiveInventory ('S7_Cash', S7_InitialCashAmount);
            GiveInventory ('S7_BerserkWeap', 1);

            // Equipment
            GiveInventory ('S7_Canteen', 2000);
            GiveInventory ('S7_CCSecVest', 1);
            // Ammo and similars
            GiveInventory ('S7_Stamina', 0x7FFFFFFF);
            GiveInventory ('S7_Mana', 0x7FFFFFFF);
            // Tokens
            GiveInventory ('S7_StaminaRegen', 1);
            GiveInventory ('S7_ManaRegen', 1);

            GiveBasics_ClassSpecific ();

            if (self == player.mo)
                A_SetBlend ("000000", 1.0, 10, "000000", 0.0);
        }
    }

    virtual void GiveBasics_ClassSpecific () { }

    override void BeginPlay () {
        Super.BeginPlay ();

        sprint_OldAgility = double.NaN;
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        GiveBasics ();
    }

    override int DamageMobj (Actor inflictor, Actor source, int damage, Name mod, int flags, double angle) {
        damageInflictor = inflictor;
        damageSource = source;
        int ret = Super.DamageMobj (inflictor, source, damage, mod, flags, angle);
        damageInflictor = null;
        damageSource = null;

        return ret;
    }

    override void Tick () {
        Super.Tick ();

        if (!player || !player.mo || player.mo != self)
            return;

        FLineTraceData traceData; // Do a trace to get the actor under the crosshair
        LineTrace (angle, 8192, pitch, flags: TRF_ThruBlock | TRF_ThruHitscan, offsetz: (height / 2) + (AttackZOffset * player.crouchfactor), data: traceData);
        playerLineTarget = ((traceData.HitType == FLineTraceData.TRACE_HitActor) ? traceData.HitActor : null);
    }

    override void PlayerThink () {
        if (!(player.cheats & CF_PREDICTING))
            player.cheats |= CF_INTERPVIEW;

        Super.PlayerThink ();

        CustCalcHeight ();

        if (!player || !player.mo || player.mo != self)
            return;

        if (!(player.cheats & CF_PREDICTING)) {
            if (!playerData || !weapBinds || !xpSys || !healSys || !FindInventory ('S7_BasicArmor'))
                GiveBasics (); // We only check it in this function to avoid a function call.

            if (!(player.cmd.buttons & BT_RELOAD) && (player.oldbuttons & BT_RELOAD))
                SetInventory ('S7_Reloading', !CheckInventory ('S7_Reloading', 1));

            if (playerData)
                playerData.dying = health < (maxHealth * 0.2);
        }

        // Movement
        //Misc_Stealth (); // RIP stealth system, you will be missed
        Movement_Dodging ();
        Movement_LedgeGrabbing ();
        Movement_Sprinting ();
        Movement_WallJump ();
        Movement_MultiJump ();
        // Weapons
        Weapon_SetAmmoMax ();
        // Misc
        Misc_PermanentItems ();
        Misc_StaminaRegen ();
        Misc_BerserkSideEffects ();
        Misc_Heartbeats ();
        Misc_HellhunterBlade ();
        Misc_BlurCamera ();
    }

    override void OnRespawn () {
        Super.OnRespawn ();

        if (!player || !player.mo || player.mo != self)
            return;

        if (!(player.cheats & CF_PREDICTING)) {
            GiveBasics ();

            if (weapBinds) {
                player.PendingWeapon = weapBinds.LastWeapon;
            }
        }
    }

    override void DeathThink () {
        Super.DeathThink ();

        if (player.morphTics && (player.mo is 'S7_BasePlayer'))
            S7_BasePlayer (player.mo).CustCalcHeight ();
    }

    const BASECROUCHSPEED = (1./8.);
    override void CrouchMove (int direction) {
        double defaultHeight = fullHeight;
        double savedHeight = height;
        double crouchSpeed = direction * BASECROUCHSPEED;
        double oldHeight = player.viewheight;

        player.crouchdir = direction;
        player.crouchfactor += crouchSpeed;

        // check whether the move is ok
        height = defaultHeight * player.crouchfactor;

        if (!TryMove (pos.XY, false, NULL)) {
            height = savedHeight;

            if (direction > 0) {
                // doesn't fit
                player.crouchfactor -= crouchSpeed;
                return;
            }
        }
        height = savedHeight;

        player.crouchfactor = clamp (player.crouchfactor, .5, 1.);
        player.viewheight = ViewHeight * player.crouchfactor;
        player.crouchviewdelta = player.viewheight - ViewHeight;

        // Check for eyes going above/below fake floor due to crouching motion.
        CheckFakeFloorTriggers (pos.Z + oldHeight, true);
    }

    const GZD_MAXBOB = 16.0;
    virtual void CustCalcHeight () {
        if (!player || !player.morphTics || !playerData)
            return;

        double bobAngle;
        double bob;
        bool   still = false;

        if (player.cheats & CF_NOCLIP2)
            playerData.bob = 0;
        else if (player.mo.bNoGravity && !player.onground)
            playerData.bob = 0.5;
        else {
            playerData.bob = vel dot vel;
            if (playerData.bob == 0)
                still = true;
            else {
                playerData.bob *= S7_PlayerCVar.GetFloat (player, "movebob");

                if (playerData.bob > GZD_MAXBOB)
                    playerData.bob = GZD_MAXBOB;
            }
        }

        double defaultviewheight = player.mo.ViewHeight + player.crouchviewdelta;

        if (player.cheats & CF_NOVELOCITY) {
            player.viewz = player.mo.pos.z + defaultviewheight;

            if (player.viewz > player.mo.ceilingz - 4)
                player.viewz = player.mo.ceilingz - 4;

            return;
        }

        if (still) {
            if (player.health > 0) {
                bobAngle = level.time / (120 * TICRATE / 35.) * 360.;
                bob = S7_PlayerCVar.GetFloat (player, "stillbob") * sin (bobAngle);
            }
            else
                bob = 0;
        }
        else {
            bobAngle = level.time / (20 * TICRATE / 35.) * 360.;
            bob = playerData.bob * sin (bobAngle) * (player.mo.waterlevel > 1 ? 0.25 : 0.5);
        }

        // move viewheight
        if (player.playerstate == PST_LIVE) {
            player.viewheight += player.deltaviewheight;

            if (player.viewheight > defaultviewheight) {
                player.viewheight = defaultviewheight;
                player.deltaviewheight = 0;
            } else if (player.viewheight < (defaultviewheight / 2)) {
                player.viewheight = defaultviewheight / 2;
                if (player.deltaviewheight <= 0)
                    player.deltaviewheight = 1 / 65536.;
            }

            if (player.deltaviewheight) {
                player.deltaviewheight += 0.25;

                if (!player.deltaviewheight)
                    player.deltaviewheight = 1 / 65536.;
            }
        }

        player.viewz = player.mo.pos.z + player.viewheight + (bob * player.mo.ViewBob); // [SP] Allow DECORATE changes to view bobbing speed.

        if (player.mo.Floorclip && player.playerstate != PST_DEAD && player.mo.pos.Z <= player.mo.floorz)
            player.viewz -= player.mo.Floorclip;

        if (player.viewz > player.mo.ceilingz - 4)
            player.viewz = player.mo.ceilingz - 4;

        if (player.viewz < player.mo.floorz + 4)
            player.viewz = player.mo.floorz + 4;
    }

    clearscope int S7_GetMaxHealth () { return ((xpSys) ? int (SpawnHealth () * (1. + (.06 * xpSys.GetStat (S7Stat_Vitality)))) : 0); }
    clearscope int GetMaxStamina   () { return ((xpSys) ? int (150 + (10 * xpSys.GetStat (S7Stat_Agility))) : 0); }
    clearscope int GetMaxMana      () { return ((xpSys) ? int (250 + (15 * xpSys.GetStat (S7Stat_Magic)))   : 0); }

    bool CanGiveHealing (bool checkMax = true) {
        if (!self || !healSys || !xpSys)
            return false; // Return false if anything is invalid
        else if (health <= 0 || (checkMax && health >= GetMaxHealth ()))
            return false; // Return false if the player is dead or at max health

        return true;
    }

    bool GiveHealing (int healAmount) {
        if (!self || !healSys || !xpSys)
            return false; // Return false if anything is invalid
        else if (health <= 0 || health >= GetMaxHealth ())
            return false; // Return false if the player is dead or at max health

        healSys.regenPoints += int (healAmount * (1. + (.045 * xpSys.GetStat (S7Stat_Vitality))));

        return true;
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
        PLAY H 1;
        PLAY H 2 {
            A_XScream ();
            A_NoBlocking ();
        }
        goto XDeath.Finish;
    XDeath.Finish:
        TNT1 A 0 {
            double defHeight = default.height / 2;

            for (int i = random [S7_GoreRNG] (8, 16); i >= 0; i--) {
                double xo = fRandom [S7_GoreRNG] (-2, 2), yo = fRandom [S7_GoreRNG] (-2, 2), zo = fRandom [S7_GoreRNG] (-2, 2);
                double xvel = fRandom [S7_GoreRNG] (0,  6),
                       zvel = fRandom [S7_GoreRNG] (4, 12);

                bool success; Actor act;
                [success, act] = A_SpawnItemEx ('S7_GibbingBlood',
                    xofs: xo, yofs: yo, zofs: defHeight + zo,
                    xvel: xvel, zvel: zvel,
                    angle: fRandom [S7_GoreRNG] (0, 360),
                    flags: SXF_UseBloodColor | SXF_NoCheckPosition
                );

                if (success && act)
                    act.vel = vel + act.vel;
            }

            for (int i = random [S7_GoreRNG] (6, 8); i >= 0; i--) {
                bool success; Actor act;
                [success, act] = A_SpawnItemEx ('S7_GoreBloodCloud',
                    xofs: fRandom [S7_GoreRNG] (-14., 14.),
                    yofs: fRandom [S7_GoreRNG] (-14., 14.),
                    zofs: defHeight + fRandom [S7_GoreRNG] (-18., 24.),
                    flags: SXF_UseBloodColor | SXF_NoCheckPosition | SXF_Clientside
                );
            }

            for (int i = random [S7_GoreRNG] (8, 15); i >= 0; i--) {
                bool success; Actor act;
                [success, act] = A_SpawnItemEx ('S7_GenericGoreBits', zofs: defHeight + fRandom [S7_GoreRNG] (-7, 7),
                    xvel: fRandom [S7_GoreRNG] (2.5, 4.5) * randomPick [S7_GoreRNG] (-1, 1),
                    yvel: fRandom [S7_GoreRNG] (2.5, 4.5) * randomPick [S7_GoreRNG] (-1, 1),
                    zvel: fRandom [S7_GoreRNG] (3.5, 12.),
                    flags: SXF_UseBloodColor | SXF_NoCheckPosition | SXF_Clientside
                );

                if (success && act)
                    act.vel = vel + act.vel;
            }
        }
        CRSH A -1 { translation = bloodTranslation; }
        stop;
    /*XDeath:
        PLAY O     5;
        PLAY P     5 A_XScream;
        PLAY Q     5 A_NoBlocking;
        PLAY RSTUV 5;
        PLAY W    -1;
        stop;*/

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
        TNT1 A                  0 A_SpawnItemEx ('S7_BlackSmoke', fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (8, 16), zVel: 1);
        PLAY H                 10 A_PlayerScream;
        PLAY I                 10 A_SpawnItemEx ('S7_BlackSmoke', fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (8, 16), zVel: 1);
        TNT1 A                  0 A_SpawnItemEx ('S7_BlackSmoke', fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (8, 16), zVel: 1);
        PLAY J                 10 A_NoBlocking;
        PLAY K                 10 A_SpawnItemEx ('S7_BlackSmoke', fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (8, 16), zVel: 1);
        TNT1 A                  0 A_SpawnItemEx ('S7_BlackSmoke', fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (8, 16), zVel: 1);
        PLAY L                 10 A_PlaySound ("Misc/Body", CHAN_Body);
        PLAY M                 10 A_SpawnItemEx ('S7_BlackSmoke', fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (8, 16), zVel: 1);
        TNT1 A                  0 A_SpawnItemEx ('S7_BlackSmoke', fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (8, 16), zVel: 1);
        PLAY NNNNNNNNNNNNNNNNNN 5 A_SpawnItemEx ('S7_BlackSmoke', fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (-16, 16), fRandom [S7_SmokeRNG] (8, 16), zVel: 1);
        PLAY N                 -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Summoned monster stuff
//
//-------------------------------------------------------------------------------------------
class S7_PlayerSummon : S7_MonsterBase {
    default {
        +FRIENDLY
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
        TNT1 A 0; // Currently does nothing.
        fail;
    }
}

//-------------------------------------------------------------------------------------------
//
// Stamina
//
//-------------------------------------------------------------------------------------------
class S7_StaminaRegen : S7_Boolean { }
class S7_Stamina : Ammo {
    default {
        Inventory.MaxAmount 150;

        +INVENTORY.IGNORESKILL +INVENTORY.UNDROPPABLE
        -INVENTORY.INVBAR
    }
}

//-------------------------------------------------------------------------------------------
//
// Mana
//
//-------------------------------------------------------------------------------------------
class S7_ManaRegen : S7_Boolean { }
class S7_Mana : Ammo {
    default {
        Inventory.MaxAmount 250;

        +INVENTORY.IGNORESKILL +INVENTORY.UNDROPPABLE
        -INVENTORY.INVBAR
    }
}

//-------------------------------------------------------------------------------------------
//
// Parkour
//
//-------------------------------------------------------------------------------------------
// Multijumping
class S7_MultiJump_Max : S7_Counter { default { Inventory.MaxAmount 200; } }

// Dodging
class S7_DodgeTrail : PlayerSpeedTrail { default { RenderStyle "Shadow"; } }
class S7_PowerDodgeEffects : Powerup {
    default {
        inventory.interHubAmount 0; // I dunno, just in case...
        Inventory.Icon "";
        Powerup.Duration 24;

        +INVENTORY.NOTELEPORTFREEZE
    }

    override void InitEffect () {
        Super.InitEffect ();

        if (!Owner)
            return;

        bNonShootable = Owner.bNonShootable;
        Owner.bNonShootable = true;
    }

    override void DoEffect () {
        if (!Owner || !Owner.player) // Return if it doesn't have an owner
            return;

        if (Owner.player.cheats & CF_PREDICTING) // Return if running player prediction
            return;

        if (level.time & 1)
            return;

        Actor speedMo = Spawn ('S7_DodgeTrail', Owner.Pos, NO_REPLACE);
        if (speedMo) {
            speedMo.Angle = Owner.Angle;
            speedMo.Translation = Owner.Translation;
            speedMo.target = Owner;
            speedMo.sprite = Owner.sprite;
            speedMo.frame = Owner.frame;
            speedMo.Floorclip = Owner.Floorclip;

            // [BC] Also get the scale from the owner.
            speedMo.Scale = Owner.Scale;

            if (Owner == players [consoleplayer].camera &&
                !(Owner.player.cheats & CF_CHASECAM)) {
                speedMo.bInvisible = true;
            }
        }
    }

    override void EndEffect () {
        Super.EndEffect ();

        if (!Owner)
            return;

        Owner.bNonShootable = bNonShootable;
    }
}

//-------------------------------------------------------------------------------------------
//
// Blur effect
//
//-------------------------------------------------------------------------------------------
class S7_BlurCamera : Actor {
    Vector3 realPos;

    default {
        Radius 0;
        Height 0;

        +NOINTERACTION +NOBLOCKMAP +NOCLIP +INVISIBLE
        +NOGRAVITY
    }

    states {
    Spawn:
        TNT1 A 1;
        wait;
    }
}

//-------------------------------------------------------------------------------------------
//
// AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
//
//-------------------------------------------------------------------------------------------
class GETTHATSHITOUTTAHERE : Actor {
    default {
        Health -1;
        Radius 20;
        Height 56;
        Mass 500;
        Speed 10;
        PainChance 100;
        monster;
        SeeSound "skeleton/sight";
        PainSound "skeleton/sight";
        DeathSound "skeleton/sight";
        ActiveSound "skeleton/sight";

        +INVULNERABLE +LOOKALLAROUND   +NODAMAGE +FLOORCLIP
        +MISSILEMORE  +MISSILEEVENMORE +NOCLIP
        -COUNTKILL -SOLID -SHOOTABLE -ISMONSTER
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
        SKEL K 5        A_SpawnProjectile ('GETTHATSHITOUTTAHERETRACER');
        SKEL K 5        A_FaceTarget;
        goto See;
    Pain:
        SKEL L 2;
        SKEL L 2 A_Pain;
        goto See;
    }
}

class GETTHATSHITOUTTAHERETRACER : FastProjectile {
    default {
        Radius 11;
        Height 8;
        DamageFunction (1);
        Speed 1000;
        RenderStyle "add";
        SeeSound "skeleton/attack";
        DeathSound "skeleton/tracex";

        Projectile;

        +SEEKERMISSILE +RANDOMIZE
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