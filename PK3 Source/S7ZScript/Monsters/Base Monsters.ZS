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
// Monster bases
//
//-------------------------------------------------------------------------------------------
class S7_MonsterBase : Actor {
    default {
        Health 60;
        Radius 20;
        Height 56;
        Mass 100;
        Speed 8;

        /** Damage factors **/
        // Plasma/Laser damage bonus
        DamageFactor "Plasma", 1.5;
        DamageFactor "LaserTracer", 1.25;

        Monster;

        +FLOORCLIP +DONTHARMCLASS +SLIDESONWALLS
    }

    int monsDeathType;
    Actor grabbedShooter;

    S7_XPSystem xpSys;
    bool setStats;

    void SetPosition (Vector3 newPos) {
        S7_ActorExtensions.SetActorPosition (self, newPos);
    }

    override String GetObituary (Actor victim, Actor inflictor, Name mod, bool playerattack) {
        if (inflictor && inflictor.Obituary)
            return inflictor.Obituary;

        return Super.GetObituary (victim, inflictor, mod, playerattack);
    }

    override void BeginPlay () {
        Super.BeginPlay ();

        aiCountdown = -1;
        aiLastTargetPos = (double.NaN, double.NaN, double.NaN);
    }

    protected bool SetXPSys () {
        if (!xpSys && !(xpSys = S7_XPSystem (FindInventory ('S7_XPSystem', true)))) {
            GiveInventory ('S7_XPSystem', 1);
            xpSys = S7_XPSystem (FindInventory ('S7_XPSystem', true));
        }

        return !!xpSys;
    }

    protected virtual void InitializeXPSystem () { }

    virtual void UpdateStats () { }

    void CallInitializeXPSystem () {
        if (!SetXPSys () || setStats)
            return;

        InitializeXPSystem ();
        UpdateStats ();

        setStats = true;
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        SetXPSys ();

        if (S7_DelayedMonsterStats == S7_DelaySpawns_Off ||
            (S7_DelayedMonsterStats == S7_DelaySpawns_MapStart && GetLevelSpawnTime () > 1)
        ) {
            CallInitializeXPSystem ();
        }
    }

    override void Tick () {
        if (!xpSys && !(xpSys = S7_XPSystem (FindInventory ('S7_XPSystem', true)))) {
            GiveInventory ('S7_XPSystem', 1);
            xpSys = S7_XPSystem (FindInventory ('S7_XPSystem', true));
        }

        Super.Tick ();

        if (!self || bDestroyed)
            return;

        S7_DoTickSteering (Speed);

        if (target && !setStats)
            CallInitializeXPSystem ();

        if (xpSys)
            UpdateStats ();

        if (health > 0 && !bKilled)
            SearchBehavior ();
    }

    override int DamageMobj (Actor inflictor, Actor source, int damage, Name mod, int flags, double angle) {
        if (!setStats)
            CallInitializeXPSystem ();

        return Super.DamageMobj (inflictor, source, damage, mod, flags, angle);
    }

    override void Die (Actor source, Actor inflictor, int dmgflags) {
        Super.Die (source, inflictor, dmgflags);

        if (source is 'S7_PlayerSummon') {
            if (source.master && source.master.player && multiplayer)
                source.player.killcount++;
        }

        OnDeath (source, inflictor, dmgflags);
    }
    virtual void OnDeath (Actor source, Actor inflictor, int dmgflags) { }

    action void S7_SpawnGibs () {
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

    S7_XPSystem GetXPSystem () {
        return S7_XPSystem (FindInventory ('S7_XPSystem', true));
    }

    void GiveXP (Actor act, int amount) {
        if (!act || amount <= 0)
            return;

        S7_XPSystem xpSys = S7_XPSystem (act.FindInventory ('S7_XPSystem', true));

        if (!xpSys && act is 'S7_PlayerSummon' && act.master)
            xpSys = S7_XPSystem (act.master.FindInventory ('S7_XPSystem', true));

        if (!xpSys)
            return;

        xpSys.GiveXP (amount);
    }

    void GiveCash (Actor act, int amount, Class<Inventory> cashItem = 'S7_Cash') {
        if (!act || amount <= 0)
            return;

        if (act is 'S7_PlayerSummon') {
            if (!act.master)
                return;

            act = act.master;
        }

        act.GiveInventory (cashItem, amount);
    }
}

class S7_DemonBase : S7_MonsterBase {
    default {
        // Demon flesh damage reduction
        DamageFactor "PistolTracer", 0.7;
        DamageFactor "RevolverTracer", 0.8;
        DamageFactor "ShotgunTracer", 0.86;
        DamageFactor "RifleTracer", 0.9;
    }
}

class S7_HellNobleBase : S7_DemonBase {
    default {
        Health 1000;
        Radius 24;
        Height 64;
        Mass 1000;
        PainChance 50;

        /** Damage factors **/
        // Demon flesh damage reduction
        DamageFactor "PistolTracer", 0.7;
        DamageFactor "RevolverTracer", 0.8;
        DamageFactor "RifleTracer", 0.9;
        // Hell Noble buckshot damage bonus
        DamageFactor "ShotgunTracer", 1.2;
    }
}

class S7_SuccubusBase : S7_DemonBase {
    default {
        Health 400;
        Radius 18;
        Height 50;
        Mass 200;
        PainChance 90;

        /** Damage factors **/
        // Demon flesh damage reduction
        // Succubi get lower reduction because they're mostly human
        DamageFactor "PistolTracer", 0.75;
        DamageFactor "RevolverTracer", 0.85;
        DamageFactor "ShotgunTracer", 0.91;
        DamageFactor "RifleTracer", 0.95;
    }
}

class S7_ScorpBase : S7_MonsterBase {
    default {
        Radius 16;
        Height 56;
        ActiveSound "Monsters/Nova/RadioChatter";

        /** Damage factors **/
        // Reanimated flesh damage reduction
        DamageFactor "PistolTracer", 0.75;
        DamageFactor "RevolverTracer", 0.85;
        DamageFactor "ShotgunTracer", 0.91;
        DamageFactor "RifleTracer", 0.95;
        // Plasma/Laser damage bonus
        DamageFactor "Plasma", 1.6;
        DamageFactor "LaserTracer", 1.35;
    }

    action void S7_DoScorpsChase () {
        /*bool canPlayActive = (
            target &&
            CheckSight (target, SF_SeePastBlockEverything | SF_SeePastShootableLines) &&
            (random [SCorpsSeeSound] (0, 255) < 96)
        );

        if (canPlayActive) {
            int speciesCount = CountProximity (self.GetClassName (), radius * 6, CPXF_Ancestor);

            if (speciesCount > 0) {
                int randomNumber = random [SCorpsSeeSound] (0, 255);
                int chance = int (floor ((255. / speciesCount)));

                canPlayActive &= (randomNumber < chance);
            }
        }

        A_S7Chase ("Melee", "Missile", flags: !canPlayActive ? S7CHF_NoPlayActive : 0);*/
        A_S7Chase ("Melee", "Missile");
    }

    // Default variables
    int fireMode, ammo;
    double turn, spreadX, spreadY;
}