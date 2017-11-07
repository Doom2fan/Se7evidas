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
    int    sprintTics, oldAgility; // sprintTics: Used to remove stamina. If this is -1, stamina was depleted by sprinting.
                                   // oldAgility: This is used for checking if the agility stat changed.
    double sprintSpeedFactor, sprintSpdFacPproc; // sprintSpdFacPproc: This is here to store the speed factor to avoid having to make lots of expensive log calls.
    /** Misc **/
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
        oldAgility = -1;
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
        player.startItem "S7_ShowPop1Key";
        // Tokens
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

        FTranslatedLineTarget lTarget; // Do a trace to get the actor under the crosshair
        let puff = LineAttack (angle, 8192, pitch, 0, "None", "S7_TraceTestPuff", LAF_NoRandomPuffZ | LAF_NoImpactDecal, lTarget);
        if (puff) puff.Destroy ();
        playerLineTarget = lTarget.linetarget;

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

                if (!(player.cmd.buttons & BT_RELOAD) && (player.oldbuttons & BT_RELOAD))
                    SetInventory ("S7_Reloading", !CheckInventory ("S7_Reloading", 1));

                playerData.dying = health < (maxHealth * 0.2);

                // Movement
                Movement_Dodging ();
                Movement_WallJump ();
                Movement_MultiJump ();
                Movement_Sprinting ();
                // Misc
                Misc_StaminaRegen ();
                Misc_Heartbeats ();
                Misc_HellhunterBlade ();
            }
        }
    }

    /** Movement **/
    void Movement_Dodging () {
        if (health > 0) {
            // Dodging
            if (playerData.dodgeCooldown <= 0) { // If dodgeCooldown is less than or equal to 0...
                // If the player tapped user2, isn't sprinting, didn't have his Soul Lance beam grabbed and has at least S7C_DodgeStamina stamina...
                if ((player.cmd.buttons & BT_USER2) && !(player.oldbuttons & BT_USER2) &&
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

    void Movement_MultiJump () {
        if (!level.IsJumpingAllowed () || health <= 0 || playerData.wjumpJustJumped || CheckInventory ("S7_SoulLance_BeamGrabbed", 1))
            return;

        if (player.onground || bOnMobj) {
            playerData.mjumpCount = 0;
            return;
        }

        int mJumpMax = CountInv ("S7_MultiJump_Max");
        if (mJumpMax < 1 || playerData.mjumpCount >= mJumpMax)
            return;

        double force = (JumpZ * 35 / TICRATE) * S7_MultiJumpZMul;
        if (force <= 0.0)
            return;

        if ((player.cmd.buttons & BT_JUMP) && !(player.oldbuttons & BT_JUMP) && abs (pos.Z - GetZAt ()) >= S7C_MJumpMinDiff && vel.Z <= 16.0) {
            let marker = Spawn ("S7_MultiJump_Marker", pos); // Spawn the multijump effect
            marker.angle = angle;
            vel.Z = force;
            playerData.mjumpCount++; // Increment the jump counter by 1
        }
    }

    const WallJumpHitCount = 12.0;
    const WallJumpHitInterval = 45.0 / WallJumpHitCount;
    const WallJumpZVel = 10.0;
    void Movement_WallJump () {
        if (playerData.wjumpJustJumped)
            playerData.wjumpJustJumped--;

        if (health <= 0 || playerData.wjumpJustJumped || CheckInventory ("S7_SoulLance_BeamGrabbed", 1))
            return;

        Actor marker, puff;
        if (player.cmd.forwardmove < 0 && (player.cmd.buttons & BT_JUMP) && !(player.oldbuttons & BT_JUMP) && (pos.Z - GetZAt ()) >= 16.0) {
            Vector3 normal, randomVec;
            double xyLen = cos (-pitch);
            normal.x = xyLen * cos (-angle);
            normal.y = xyLen * sin (angle);
            normal.z = sin (-pitch);
            normal = normal.Unit ();
            do {
                randomVec = (frandom (-1, 1), frandom (-1, 1), frandom (-1, 1)).Unit();
            } while (randomVec == normal);
            Vector3 normalPerp1 = (normal cross randomVec).Unit ();
            Vector3 normalPerp2 = (normal cross normalPerp1).Unit ();
            Vector3 center = pos + (0, 0, (height / 2) + attackZOffset);
            Vector3 point1, point2;
            point1 = center + cos (45) * normalPerp1 + sin (45) * normalPerp2;
            point2 = center + cos (-90) * normalPerp1 + sin (-90) * normalPerp2;

            for (int i = 0; i < WallJumpHitCount + 1; i++) {
                double hitAngle = angle + (WallJumpHitInterval * ((-1) ^ ((i+1) & 1) * ((i+1) >> 1)));

                for (int j = 0; j < WallJumpHitCount + 1; j++) {
                    double hitPitch = pitch + (WallJumpHitInterval * ((-1) ^ ((j+1) & 1) * ((j+1) >> 1)));
                    puff = LineAttack (hitAngle, 24, hitPitch, 0, "None", "S7_WallCheckPuff", LAF_NoRandomPuffZ | LAF_NoImpactDecal, null);
                    if (puff && (puff.pos.Z - puff.GetZAt ()) >= 0.5) {
                        Vector3 hitPos1, hitPos2, hitPos3;
                        // Get hit position 1
                        hitPos1 = puff.pos;
                        puff.Destroy ();

                        // Get hit position 2
                        marker = Spawn ("S7_WalljumpMarker", point1);
                        puff = marker.LineAttack (hitAngle, 32, hitPitch, 0, "None", "S7_WallCheckPuff", LAF_NoRandomPuffZ | LAF_NoImpactDecal, null);
                        if (!puff) { marker.Destroy (); continue; }
                        hitPos2 = puff.pos; puff.Destroy ();
                        marker.Destroy ();

                        // Get hit position 3
                        marker = Spawn ("S7_WalljumpMarker", point2);
                        puff = marker.LineAttack (hitAngle, 32, hitPitch, 0, "None", "S7_WallCheckPuff", LAF_NoRandomPuffZ | LAF_NoImpactDecal, null);
                        if (!puff) { marker.Destroy (); continue; }
                        hitPos3 = puff.pos; puff.Destroy ();
                        marker.Destroy ();

                        Vector3 wallNormal = ((hitPos3 - hitPos2) cross (hitPos1 - hitPos2)).Unit ();
                        if (wallNormal dot normal > 0) wallNormal = -wallNormal;
                        Vector3 velChange = wallNormal;
                        velChange.X *= 10; velChange.Y *= 10;

                        if (velChange.Z == 0.0)     velChange.Z  =  WallJumpZVel;
                        else if (velChange.Z < 0.0) velChange.Z *= -WallJumpZVel;
                        else                        velChange.Z *=  WallJumpZVel;

                        playerData.wjumpJustJumped = S7C_WJumpDelay;
                        vel = velChange;
                        A_SetPitch (VectorAngle (wallNormal.XY.Length (), wallNormal.Z), SPF_ForceClamp | SPF_Interpolate);
                        A_SetAngle (VectorAngle (wallNormal.X, wallNormal.Y), SPF_ForceClamp | SPF_Interpolate);
                        return;
                    }
                }
            }
        }
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

    /** Misc **/
    void Misc_StaminaRegen () {
        int curStamina = CountInv ("S7_Stamina");
        int maxStamina = GetMaxStamina ();

        if (health <= 0 || curStamina == maxStamina || playerData.sprinting) {
            playerData.staminaTics = 0;
            return;
        }

        bool berserkActive = CheckInventory ("S7_BerserkToken", 1);
        int count = 1, interval = 1;

        if (berserkActive)
            count = (!playerData.dying) ? 4 : 2;
        if (playerData.dying)
            interval = berserkActive ? 2 : 3;

        if (playerData.staminaTics >= interval) {
            GiveInventory ("S7_Stamina", count);
            playerData.staminaTics = 0;
        }

        if (curStamina != maxStamina)
            playerData.staminaTics++;
    }

    void Misc_Heartbeats () {
        if (health <= 0)
            return;

        CVar heartbeats = CVar.GetCVar ("S7_HeartbeatsOn", players [consoleplayer]);
        if (heartbeats && heartbeats.GetInt ()) {
            if ((health <= 25 && health > 15 && playerData.heartbeatTics >= 89) || // I couldn't find a better way to do this... >.>
                (health <= 15 && health > 10 && playerData.heartbeatTics >= 71) ||
                (health <= 10 && health > 5  && playerData.heartbeatTics >= 53) ||
                (health <= 5  && health > 2  && playerData.heartbeatTics >= 35) ||
                (health <= 2  &&                playerData.heartbeatTics >= 18)
            ) {
                A_PlaySound ("Player/Heartbeat", CHAN_Body, 1.0, false, ATTN_NONE, true);
                playerData.heartbeatTics = 0;
            } else if (health > 25) // If health is greater than 25...
                playerData.heartbeatTics = 0; // Set heartbeatTics to 0
            else // if neither...
                playerData.heartbeatTics++; // Add one to heartbeatTics
        }
    }

    void Misc_HellhunterBlade () {
        int curLvl = CountInv ("S7_HellhunterBladeAffinity");
        int curExp = CountInv ("S7_HellhunterBladeExperience");
        int nxtLvl = 2500 + curLvl * 1250;
        if (curLvl < 10 && curExp >= nxtLvl) {
            GiveInventory ("S7_HellhunterBladeAffinity", 1);
            TakeInventory ("S7_HellhunterBladeExperience", nxtLvl);
        }
    }

    clearscope int GetStrengthStat () { return ((xpSys) ? xpSys.strengthStat : 0); }
    clearscope int GetAgilityStat  () { return ((xpSys) ? xpSys.agilityStat  : 0); }
    clearscope int GetVitalityStat () { return ((xpSys) ? xpSys.vitalityStat : 0); }
    clearscope int GetDefenseStat  () { return ((xpSys) ? xpSys.defenseStat  : 0); }
    clearscope int GetWillStat     () { return ((xpSys) ? xpSys.willStat     : 0); }
    clearscope int GetMagicStat    () { return ((xpSys) ? xpSys.magicStat    : 0); }
    clearscope int GetTechStat     () { return ((xpSys) ? xpSys.techStat     : 0); }
    clearscope int GetMaxStamina   () { return ((xpSys) ? (150 + 10 * xpSys.agilityStat) : 0); }
    clearscope int GetMaxMana      () { return ((xpSys) ? (250 + 15 * xpSys.magicStat)   : 0); }

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