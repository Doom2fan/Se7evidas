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
// M-400 Autogun
//
//-------------------------------------------------------------------------------------------
class S7_M400AutogunTracer : S7_BulletTracer {
    default {
        S7_BaseTracer.TrueSpeed 240;
        DamageFunction (8 + random [monsterDMG] (-1, 2));
        DamageType 'RifleTracer';
    }
}

class S7_M400AutogunStored : Inventory {
    int integrity;
    int ammo;
    int corruption;
    int scanAngle;
    property Integrity: integrity;
    property Ammo: ammo;
    property ScanAngle: scanAngle;

    default {
        Inventory.Amount 1;
        Inventory.MaxAmount 1;
        Inventory.Icon "graphics/Inventory/TurretIcon.png";
        Inventory.PickupMessage "$AUTOGUN";
        Tag "$AUTOGUN";

        S7_M400AutogunStored.Integrity 500;
        S7_M400AutogunStored.Ammo 1000;
        S7_M400AutogunStored.ScanAngle 90;

        +INVENTORY.INVBAR
    }

    override bool Use (bool pickup) {
        if (integrity <= 0 || ammo <= 0)
            return false;

        bool success; Actor act;
        [success, act] = owner.A_SpawnItemEx ('S7_M400Autogun', owner.radius + (25*2), flags: SXF_TransferTranslation | SXF_SetMaster);

        if (!success || !act)
            return false;

        if (!owner.CheckSight (act, SF_SeePastShootableLines)) {
            act.Destroy ();
            return false;
        }

        let autogun = S7_M400Autogun (act);

        if (autogun) {
            autogun.health = integrity;
            autogun.ammo = ammo;
            autogun.corruption = corruption;
            autogun.scanAngle = scanAngle;

            autogun.CopyFriendliness (owner, false, false);
            autogun.master = owner;
            autogun.SetFriendPlayer (owner.player);

            autogun.A_PlaySound ("Inventory/Turret/Place", CHAN_Voice);

            return true;
        }

        return false;
    }

    states {
    Spawn:
        TRT1 Z -1;
        stop;
    }
}

class S7_M400Autogun : S7_PlayerSummon {
    default {
        Radius 25;
        Height 50;
        Mass 750;
        Speed 0;

        Health 500;
        GibHealth -100;
        PainChance 0;

        Obituary "$OBM400AUTOGUN";
        Species 'M400Autogun';
        Tag "$AUTOGUN";

        DamageFactor "Plasma", 1.0;
        DamageFactor "LaserTracer", 1.0;
        DamageFactor "NerveGas", 0.0;

        +NOBLOOD
    }

    S7_XPSystem xpSys;
    int ammo;
    int corruption;
    int scanAngle;

    Vector2 initialAngles;
    double lookTime;
    bool turnCos;
    Actor aimMarkers [12];

    int useTimer;
    override bool Used (Actor user) {
        // Don't let anyone other than the owner pick it up, and don't let destroyed turrets be picked up
        if (user != master || useTimer == -1)
            return false;

        if (user.CheckInventory ('S7_M400AutogunStored', 1)) {
            useTimer = 0;
            return false;
        }

        if (useTimer > 0) {
            user.GiveInventory ('S7_M400AutogunStored', 1);
            let stored = S7_M400AutogunStored (user.FindInventory ('S7_M400AutogunStored'));

            stored.integrity = health;
            stored.ammo = ammo;
            stored.corruption = corruption;
            stored.scanAngle = scanAngle;

            Destroy ();

            return false;
        } else
            useTimer = 35 * 2;

        return false;
    }

    override void PostBeginPlay () {
        if (!xpSys) {
            GiveInventory ('S7_XPSystem', 1);
            xpSys = S7_XPSystem (FindInventory ('S7_XPSystem', true));
        }

        let serverData = S7_ServerData.Get ();
        xpSys.canLevelUp = true;

        // Vitality
        startHealth = int (health * (1.0 + (.05 * xpSys.GetStat (S7Stat_Vitality))));
        health = startHealth;

        ammo = 1000;

        initialAngles = (angle, pitch);
        lookTime = 0;
        turnCos = (random [monsterSpc] (0, 1) == 1);
    }

    override bool OkayToSwitchTarget (Actor other) {
        return false; // NO
    }

    override String GetObituary (Actor victim, Actor inflictor, Name mod, bool playerattack) {
        if (victim == master || victim.player == master.player)
            return "$OBM400AUTOGUNSELF";

        return Super.GetObituary (victim, inflictor, mod, playerattack);
    }

    override void Tick () {
        if (useTimer > 0)
            useTimer--;

        if (!xpSys) {
            xpSys = S7_XPSystem (FindInventory ('S7_XPSystem', true));
            if (!xpSys) {
                GiveInventory ('S7_XPSystem', 1);
                xpSys = S7_XPSystem (FindInventory ('S7_XPSystem', true));
            }
        }

        // Strength
        damageMultiply = 1.0 + (0.02 * xpSys.GetStat (S7Stat_Strength / 2));
        // Defense
        damageFactor = clamp (1.0 - (0.01 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);

        Super.Tick ();
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source && source != master) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (80 * max (1, level / 3)));
            GiveCash (source, int (75 * max (1, level / 4)));
        }
    }

    void SpawnMarker (out Actor aimMarker, out FLineTraceData data, double pitchOffs = 0.) {
        bool markerHit = LineTrace (angle, (1 << 16), pitch + pitchOffs, flags: TRF_NoSky, offsetz: 38.5, data: data);

        if (aimMarker) {
            aimMarker.SetOrigin (data.HitLocation, !(aimMarker.alpha ~== 0.));
            aimMarker.alpha = (markerHit ? 1. : 0.);
        } else {
            aimMarker = Spawn ('S7_TurretRedDot', data.HitLocation);
            aimMarker.target = self;
            aimMarker.alpha = 0.;
        }
    }

    static const double HitLocations [] = {
        .650, .500, .750,
        .850, .250, .350,
        .150, .900, .000,
        .025, .050, .075,
        .100, .125, .175,
        .200, .225, .275,
        .300, .325, .375,
        .400, .425, .450,
        .475, .525, .550,
        .575, .600, .625,
        .675, .700, .725,
        .775, .800, .825,
        .875, .925, .950,
        .975, 1.0
    };

    void FindTarget () {
        static const double AimPitchOffsets [] = {
                0,
            -1, 1,
            -2, 2,
            -3, 3,
            -4, 4,
            -5, 5
        };

        if (target) {
            SetState (ResolveState ("Missile"));
            return;
        }

        Array<Actor> possibleTargets;
        possibleTargets.Clear ();

        for (int i = 0; i < AimPitchOffsets.Size (); i++) {
            FLineTraceData data;

            SpawnMarker (aimMarkers [i], data, AimPitchOffsets [i]);

            if (data.HitType == FLineTraceData.TRACE_HitActor)
                possibleTargets.Push (data.HitActor);
        }

        if (ammo <= 0)
            return;

        Actor newTarget = null;
        double closestDist = double.infinity;
        for (int i = 0; i < possibleTargets.Size (); i++) {
            let mo = possibleTargets [i];

            if (IsFriend (mo) || mo == master || mo.health <= 0 || mo.bInvulnerable || mo.bDormant)
                continue;

            double dist = Distance3D (mo);
            if (dist <= closestDist) {
                if (FindShootingPos (mo) != double.infinity) {
                    closestDist = dist;
                    newTarget = mo;
                }
            }
        }

        if (!target || (newTarget && (Distance3D (newTarget) < Distance3D (target))))
            target = newTarget;

        if (target)
            SetState (ResolveState ("Missile"));
    }

    double FindShootingPos (Actor mo) {
        for (int i = 0; i < HitLocations.Size (); i++) {
            FLineTraceData data;
            double traceAngle, tracePitch;
            {
                let vecDiff = level.Vec3Diff (pos + (0, 0, 38.5), mo.pos + (0, 0, height * HitLocations [i]));
                traceAngle = VectorAngle (vecDiff.X, vecDiff.Y);
                tracePitch = -asin (vecDiff.Z / vecDiff.Length ());
            }
            bool result = LineTrace (traceAngle, (1 << 16), tracePitch, flags: TRF_NoSky, offsetz: 38.5, data: data);

            if (result && data.HitType == FLineTraceData.TRACE_HitActor && data.HitActor == mo)
                return HitLocations [i];
        }

        return double.infinity;
    }

    void RemoveMarkers (bool destroy) {
        for (int i = 0; i < aimMarkers.Size (); i++) {
            if (aimMarkers [i]) {
                if (destroy)
                    aimMarkers [i].Destroy ();
                else
                    aimMarkers [i].alpha = 0.;
            }

            if (destroy)
                aimMarkers [i] = null;
        }
    }

    states {
    Spawn:
    Idle:
        TRT1 A 1 {
            if (ammo <= 0) {
                RemoveMarkers (false);
            }
            double speedScale = scanAngle / 90.0;
            double lookTimeSin = (turnCos ? cos ((lookTime * 1.5) / speedScale) : sin ((lookTime * 1.5) / speedScale));
            A_SetAngle (initialAngles.X + (scanAngle * lookTimeSin), SPF_Interpolate);
            A_SetPitch (initialAngles.Y, SPF_Interpolate);
            lookTime++;

            invoker.FindTarget ();
        }
        loop;

    Missile:
        TRT1 A 1 {
            RemoveMarkers (false);

            double heightMod;

            if (ammo <= 0 || target.health <= 0 || target.bInvulnerable || target.bDormant ||IsFriend (target) || 
                !CheckIfTargetInLOS (360, JLOSF_AllyNoJump | JLOSF_CombatantOnly) ||
                (heightMod = FindShootingPos (target)) == double.infinity) {
                target = null;
                return ResolveState ("Idle");
            }

            LeadTarget (target, 240, (0, 38.5), targHeightOff: heightMod, flags: S7_LTF_TargHeightMul);

            return ResolveState (null);
        }
        TRT1 B 1 {
            double heightMod = FindShootingPos (target);

            if (heightMod == double.infinity)
                heightMod = fRandom [monsterSpc] (0.25, 0.85);

            LeadTarget (target, 240, (0, 38.5), targHeightOff: heightMod, flags: S7_LTF_TargHeightMul);
            A_SpawnProjectile ('S7_M400AutogunTracer', 38.5, 0.0, fRandom [monsterSpread] (-1., 1.), 0, fRandom [monsterSpread] (-1., 1.));
            ammo--;

            A_PlaySound ("Inventory/Turret/Fire", CHAN_Weapon);
            A_AlertMonsters ();

            A_SetTics (random [monsterSpc] (1, 2));
        }
        TRT1 A 2;
        loop;

    Death:
        TRT1 A 15 {
            RemoveMarkers (true);
            useTimer = -1;

            A_PlaySound ("Explosions/Explosion1", CHAN_Body, 0.5);
            let expl = Spawn ('S7_TurretExplosion', pos + (0, 0, 42));
            if (expl)
                expl.scale = (0.2, 0.2);
        }
        TRT1 A -1 {
            useTimer = 0;
        }
        stop;
    XDeath:
        TRT1 A 20 {
            RemoveMarkers (true);
            useTimer = -1;

            let expl = Spawn ('S7_TurretExplosion', pos + (0, 0, 42));
            if (expl) {
                expl.A_PlaySound ("Explosions/Explosion1", CHAN_Body, .5);
                expl.A_SetScale (.2);
            }
        }
        TRT1 A 10 {
            let expl = Spawn ('S7_TurretExplosion', pos + (fRandom [S7_HitsparksRNG] (-10, 10), fRandom [S7_HitsparksRNG] (-10, 10), 42 + fRandom [S7_HitsparksRNG] (-6, 6)));
            if (expl) {
                expl.A_PlaySound ("Explosions/Explosion1", CHAN_Body, .5);
                expl.A_SetScale (.2);
            }
        }
        TRT1 AAAAAAA 1 {
            A_SetTics (random [monsterSpc] (4, 6));

            let expl = Spawn ('S7_TurretExplosion', pos + (fRandom [S7_HitsparksRNG] (-10, 10), fRandom [S7_HitsparksRNG] (-10, 10), 42 + fRandom [S7_HitsparksRNG] (-6, 6)));
            if (expl) {
                expl.A_PlaySound ("Explosions/Explosion1", CHAN_Body, fRandom [S7_HitsparksRNG] (.5, .65));
                expl.A_SetScale (fRandom [S7_HitsparksRNG] (.15, .3));
            }
        }
        TRT1 A 15;
        TRT1 A 70 {
            let expl = Spawn ('S7_TurretExplosion', pos + (0, 0, 42));
            if (expl) {
                expl.A_PlaySound ("Explosions/Explosion1", CHAN_Body);
                expl.A_SetScale (.25);
            }
        }
        TRT1 C -1 {
            A_PlaySound ("Explosions/Explosion2", CHAN_Body);
            let expl = Spawn ('S7_TurretExplosion', pos + (0, 0, 42));
            if (expl)
                expl.A_SetScale (.5);
        }
        stop;

        //firing height: 38.5
    }
}

class S7_TurretRedDot : S7_EffectsBase {
    default {
        RenderStyle "Add";
        Scale .25;

        +NOGRAVITY +NOINTERACTION
    }

    states {
    Spawn:
        BAL1 A 1 bright {
            if (!target || target.health <= 0)
                Destroy ();
        }
        loop;
    }
}

class S7_TurretExplosion : S7_EffectsBase {
    default {
        RenderStyle "Add";

        +NOGRAVITY +NOINTERACTION
    }

    states {
    Spawn:
        MISL BCD 2;
        stop;
    }
}