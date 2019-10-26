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

//-------------------------------------------------------------------------------------------
//
// Empress (Female Heresiarch)
//
//-------------------------------------------------------------------------------------------
/** Constants **/
const S7_EmpressMass = 12000;

/** Main actor **/
class S7_Empress : S7_DemonBase {
    default {
        Health 4500;
        Radius 40;
        Height 100;
        Speed 18;
        Mass S7_EmpressMass;
        PainChance 15;
        PainChance "Empress_BallExploded", 256;
        PainChance "S7_SoulLance_Beam", 256;
        MinMissileChance 160;
        BloodType 'S7_EmpressBlood', 'S7_EmpressBloodSplatter';
        BloodColor "B2 11 DE";
        SeeSound "cyber/sight";
        PainSound "cyber/pain";
        DeathSound "cyber/death";
        ActiveSound "cyber/active";
        Species 'S7Empress';
        Tag "$EMPRESSTAG";

        // Demon/Reanimated flesh damage reduction
        DamageFactor "PistolTracer", .7;
        DamageFactor "RevolverTracer", .8;
        DamageFactor "RifleTracer", .9;
        // Plasma/Laser damage bonus
        DamageFactor "Plasma", 1.5;
        DamageFactor "LaserTracer", 1.25;
        // Boss damage reduction
        DamageFactor "ExplosionSplashDMG", .25;
        DamageFactor "Shrapnel", .35;

        Monster;

        +FLOORCLIP +NOTARGET    +BOSS +BOSSDEATH
        +DONTMORPH +MISSILEMORE
    }

    const InvulnDelayTime = TicRate * 12;
    const InvulnLimit = 2500;
    const InvulnShieldAngle = 152.5;

    bool initialized;
    bool shieldUp; // The shield is active
    Array<S7_EmpressInvulnOrbiterCW> ballsList; // Pointers to the invulnerability thingies
    int invulnDelay; // How much time left until we can raise the shield
    bool canCastInvuln; // Whether shields can be cast
    bool castingInvuln;

    bool canDieNow;
    Actor deathSource, deathInflictor;
    int deathDMGFlags;

    override void InitializeXPSystem () {
        let serverData = S7_ServerData.Get ();
        xpSys.level = int (max (1.0, (double (serverData.avgLevel) / 7.5) + fRandom [monsterStats] (-1.5, 2.5)));
        int attrPts = xpSys.level * 4;

        while (attrPts > 0) {
            int rnd = random [monsterStats] (0, 3);

            switch (rnd) {
            case 0: xpSys.SetStat (S7Stat_Strength, 1); break;
            case 1: xpSys.SetStat (S7Stat_Defense, 1); break;
            case 2: xpSys.SetStat (S7Stat_Vitality, 1); break;
            case 3: xpSys.SetStat (S7Stat_Agility, 1); break;
            }

            attrPts--;
        }

        // Vitality
        startHealth = int (health * (1.0 + (.1 * xpSys.GetStat (S7Stat_Vitality))));
        health = startHealth;
    }

    override void UpdateStats () {
        // Strength
        damageMultiply = 1.0 + (0.025 * xpSys.GetStat (S7Stat_Strength));
        // Defense
        damageFactor = clamp (1.0 - (0.015 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);
        // Agility
        speed = default.Speed + clamp (xpSys.GetStat (S7Stat_Agility) * 0.1, -default.Speed * .75, default.Speed);
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        TakeInventory ('S7_IsDead', 0x7FFFFFFF);
    }

    override int DamageMobj (Actor inflictor, Actor source, int damage, Name mod, int flags, double angle) {
        if (!setStats)
            CallInitializeXPSystem ();

        bool hitShield = false;

        if (shieldUp) {
            let angTo = inflictor ? AngleTo (inflictor) : double.NaN;
            if (flags & DMG_UseAngle && !inflictor)
                angTo = DeltaAngle (self.angle, angle);

            if (abs (angTo) <= InvulnShieldAngle)
                hitShield = true;
        }

        bool origInv = bInvulnerable, origPain = bNoPain, origBlood = bNoBlood;

        if (hitShield) { // Max hax
            bInvulnerable = true;
            bNoPain = !(random [monsterSpc] () < 48);
            bNoBlood = true;

            Spawn ('S7_EmpressShieldHitspark', inflictor.pos);
        } else if (shieldUp) {
            if (damage < Telefrag_Damage)
                damage /= 2;
        }

        int ret = Super.DamageMobj (inflictor, source, damage, mod, flags, angle);

        bInvulnerable = origInv;
        bNoPain = origPain;
        bNoBlood = origBlood;

        return ret;
    }

    override void Die (Actor source, Actor inflictor, int dmgflags) {
        if (canDieNow) {
            Super.Die (source, inflictor, dmgflags);
            return;
        } else {
            deathSource = source;
            deathInflictor = inflictor;
            deathDMGFlags = dmgflags;
        }
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (2250 * max (1, level / 2.)));
            GiveCash (source, int (clamp (2340 * (level / 10.), 2340, 2340 * 2)));
        }
    }

    override void Tick () {
        if (!initialized) {
            Super.Tick ();
            return;
        }

        if (health > InvulnLimit || shieldUp)
            canCastInvuln = false;
        else if (invulnDelay >= 0 && !shieldUp) {
            canCastInvuln = false;
            invulnDelay--;
        } else if (health <= InvulnLimit && !shieldUp && invulnDelay < 1)
            canCastInvuln = true;

        for (int i = ballsList.Size ()-1; i >= 0; i--) {
            if (ballsList [i] == null)
                ballsList.Delete (i, 1);
        }

        int ballsCount = ballsList.Size ();
        if (ballsCount < 1 && shieldUp)
            shieldUp = false;
        if (ballsCount < 0)
            ballsCount = 0;

        Super.Tick ();
    }

    double GetDamageBonus () {
        if (!xpSys)
            return 0.;

        return xpSys.GetStat (S7Stat_Strength, false) * 0.075;
    }

    int spawnLoopCount;

    action void S7_PreSpawnSmoke (int count) {
        for (int i = 0; i < count; i++) {
            A_SpawnItemEx ('S7_EmpressSmoke',
                fRandom [S7_SmokeRNG] (-23., 23.),
                fRandom [S7_SmokeRNG] (-23., 23.),
                15. + fRandom [S7_SmokeRNG] (-0., 32.),
                flags: SXF_Clientside | SXF_NoCheckPosition
            );
        }
    }

    /** "Spawner" **/
    states {
    Spawn:
        TNT1 A 0 noDelay {
            A_ChangeLinkFlags (blockmap: false);
            A_SetSize (0, 0, false);
            spawnLoopCount = random [monsterSpc] (4, 7);
        }
        TNT1 A 1 {
            if (spawnLoopCount < 1)
                return ResolveState ("PreSpawnIdle");

            S7_PreSpawnSmoke (2);
            spawnLoopCount--;

            return ResolveState (null);
        }
        wait;
    PreSpawnIdle:
        TNT1 A 1 {
            S7_PreSpawnSmoke (2);
            A_S7LookEx (flags: LOF_NoSeeSound, fov: 360., seeStateLabel: "Spawn.Spawned");
        }
        loop;
    Spawn.Spawned:
        TNT1 A            0 {
            for (int i = 0; i < (5*2); i++)
                A_SpawnItemEx ('S7_EmpressPentagramCorner', 180., 0, 0, 0, 0, 0, (72/2.) * i, SXF_Clientside | SXF_NoCheckPosition);
        }
        TNT1 AAAAAAAAAAAA 1 S7_PreSpawnSmoke (1);
        TNT1 A            5;
        TNT1 A            0 {
            A_SetSize (default.Radius, default.Height, false);
            TeleportMove (pos, true);

            for (int i = 0; i < 48; i++) {
                A_SpawnItemEx ('S7_EmpressSparkle', fRandom [S7_MiscSFXRNG] (-2.5, 2.5), fRandom [S7_MiscSFXRNG] (-2.5, 2.5), 50. + fRandom [S7_MiscSFXRNG] (0., 2.5),
                    fRandom [S7_MiscSFXRNG] (-8., 8.), fRandom [S7_MiscSFXRNG] (-8., 8.), fRandom [S7_MiscSFXRNG] (-8., 8.), 0, SXF_Clientside | SXF_NoCheckPosition);
            }
        }
        goto Idle;
    }

    /** Idle, chasing enemy, initiating attack **/
    states {
    Idle:
        HRFR A   1 {
            TakeInventory ('S7_IsDead', 0x7FFFFFFF);
            ResetAttacks ();

            if (health < 1)
                return ResolveState ("RunAway");

            A_S7Look ();

            return ResolveState (null);
        }
        HRFR AAAAAAAAA 1 A_JumpIf (health < 1, "RunAway");
        loop;

    See:
        TNT1 A    0 {
            TakeInventory ('S7_IsDead', 0x7FFFFFFF);
            ResetAttacks ();
            A_PlaySound ("Footsteps/Large", CHAN_5);
        }
        HRFR AABB 4 {
            if (health < 1)
                return ResolveState ("RunAway");

            A_S7ChaseDef ();
            return ResolveState (null);
        }
        TNT1 A    0 A_PlaySound ("Footsteps/Large", CHAN_6);
        HRFR CCDD 4 {
            if (health < 1)
                return ResolveState ("RunAway");

            A_S7ChaseDef ();

            return ResolveState (null);
        }
        loop;

    Missile:
        TNT1 A 0 {
            if (!shieldUp && canCastInvuln && random [monsterSpc] () < 64)
                return ResolveState ("ShieldsUp");

            return A_Jump (256, "Attack.Fireball", "Attack.MagicMissile", "Attack.DanmakuFireballs");
        }
        goto Attack.Fireball;
    }

    /** Shields **/
    states {
    ShieldsUp:
        HRFR A  5 { bNoPain = true; }
        HRFR FF 5;
        HRFR F  9 {
            shieldUp = true;
            invulnDelay = InvulnDelayTime;
            bool success; Actor act;
            [success, act] = A_SpawnItemEx ('S7_EmpressInvulnOrbiterCW',  64., 0, 50., 0, 0, 0, 0, SXF_NoCheckPosition | SXF_SetMaster);
            if (success && act) {
                let ball = S7_EmpressInvulnOrbiterCW (act);
                if (ball)
                    invoker.ballsList.Push (ball);
            }

        }
        HRFR F  9 {
            bool success; Actor act;
            [success, act] = A_SpawnItemEx ('S7_EmpressInvulnOrbiterCCW', 64., 0, 50., 0, 0, 0, 0, SXF_NoCheckPosition | SXF_SetMaster);
            if (success && act) {
                let ball = S7_EmpressInvulnOrbiterCW (act);
                if (ball)
                    invoker.ballsList.Push (ball);
            }
        }
        HRFR F  9 {
            bool success; Actor act;
            [success, act] = A_SpawnItemEx ('S7_EmpressInvulnOrbiterCW',  64., 0, 50., 0, 0, 0, 0, SXF_NoCheckPosition | SXF_SetMaster);
            if (success && act) {
                let ball = S7_EmpressInvulnOrbiterCW (act);
                if (ball)
                    invoker.ballsList.Push (ball);
            }
        }
        HRFR F  9 {
            bool success; Actor act;
            [success, act] = A_SpawnItemEx ('S7_EmpressInvulnOrbiterCCW', 64., 0, 50., 0, 0, 0, 0, SXF_NoCheckPosition | SXF_SetMaster);
            if (success && act) {
                let ball = S7_EmpressInvulnOrbiterCW (act);
                if (ball)
                    invoker.ballsList.Push (ball);
            }
        }
        TNT1 A  0 { castingInvuln = false; }
        goto See;
    }

    action void ResetAttacks () {
        invoker.midAttack_Fireball = false;
        invoker.attackDanmakuFireballs_Time = false;
        invoker.attackMagicMissile_Shots = 0;

        invoker.castingInvuln = false;
    }

    /** Pain and death **/
    states {
    Pain:
        HRFR G 8 {
            ResetAttacks ();

            A_Pain ();
        }
        goto See;
    Pain.Empress_BallExploded:
        HRFR G 13 {
            ResetAttacks ();

            A_Pain ();
        }
        goto See;

    /** Death stuff **/
    RunAway:
        TNT1 A 0 {
            canDieNow = true;
            Die (deathSource, deathInflictor, deathDMGFlags);
        }
        goto Death;
    Death:
        TNT1 A 0 { GiveInventory ('S7_IsDead', 1); }
        HRFR GGG    13 A_Pain;
        HRFR FFFFFF  1 A_SpawnItemEx ('S7_EmpressDeathSmokeSpawner', 0, 0, 0, 0, 0, 0, 0, SXF_Clientside | SXF_NoCheckPosition);
        HRFR F       2;
        TNT1 A      35 {
            for (int i = 0; i < 48; i++) {
                A_SpawnItemEx ('S7_EmpressSparkle', fRandom [S7_MiscSFXRNG] (-2.5, 2.5), fRandom [S7_MiscSFXRNG] (-2.5, 2.5), 50. + fRandom [S7_MiscSFXRNG] (0., 2.5),
                    fRandom [S7_MiscSFXRNG] (-8., 8.), fRandom [S7_MiscSFXRNG] (-8., 8.), fRandom [S7_MiscSFXRNG] (-8., 8.), 0, SXF_Clientside | SXF_NoCheckPosition);
            }
            A_NoBlocking ();
            A_DamageChildren (0x7FFFFFFF, 'EmpressDeath');
            A_KillChildren ();
        }
        TNT1 A      -1;
        stop;
    }
}

class S7_EmpressDeathSmokeSpawner : Actor {
    default {
        +NOINTERACTION  +NOGRAVITY +NOTELEPORT +NOBLOCKMAP
        +CLIENTSIDEONLY
    }

    states {
    Spawn:
        TNT1 AAAAAAAA 0 {
            A_SpawnItemEx ('S7_EmpressSmoke',
                fRandom [S7_SmokeRNG] (-23., 23.),
                fRandom [S7_SmokeRNG] (-23., 23.),
                15. + fRandom [S7_SmokeRNG] (-0., 85.),
                flags: SXF_Clientside | SXF_NoCheckPosition
            );
        }
        stop;
    }
}