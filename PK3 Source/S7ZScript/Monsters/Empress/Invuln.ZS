/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
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
// Empress' invulnerability orbiter
//
//-------------------------------------------------------------------------------------------
class S7_EmpressInvulnOrbiterCW : Actor {
    double rotAmount;
    property RotAmount: rotAmount;
    bool useCos;
    property UseCos: useCos;

    default {
        Health 75;
        Radius 25;
        Height 25;
        RenderStyle "add";
        DamageFactor "EmpressDeath", 1.0;
        DamageFactor "NerveGas", 0.0;
        Species 'S7EmpressCrap';
        Scale 0.1;
        Alpha 1.0;

        S7_EmpressInvulnOrbiterCW.RotAmount 10.0;
        S7_EmpressInvulnOrbiterCW.UseCos false;

        +NOGRAVITY +NOTELEPORT +NOTARGETSWITCH +FORCEXYBILLBOARD
        +SHOOTABLE +FORCEPAIN  +THRUSPECIES    +FOILINVUL
        +NOBLOOD
    }

    double rotAngle;
    int countdown;
    S7_Empress owner;

    void OrbitMaster (bool initWarp = false) {
        double zOffs = 50.0 + 40 * (useCos ? cos (40 + rotAngle) : sin (40 + rotAngle));

        if (!initWarp) {
            for (int i = 0; i < 4; i++) {
                let offs = (fRandom [sfx] (-0.5, 0.5), fRandom [sfx] (-0.5, 0.5), fRandom [sfx] (-0.5, 0.5));

                let act = S7_EmpressShieldSparkle (Spawn ('S7_EmpressShieldSparkle', Vec3Offset (offs.X, offs.Y, offs.Z)));
                if (act) {
                    act.vel = (fRandom [sfx] (-3.0, 3.0), fRandom [sfx] (-3.0, 3.0), fRandom [sfx] (-1.0, 1.0));
                    act.target = owner;
                    act.rotAngle = rotAngle;
                    act.zOffs = zOffs;
                    act.offs = offs;
                }
            }

            let flare = S7_EmpressShieldFlare (Spawn ('S7_EmpressShieldFlare', pos));
            if (flare) {
                flare.target = owner;
                flare.rotAngle = rotAngle;
                flare.zOffs = zOffs;
            }
        }

        int flags = WARPF_NoCheckPosition;

        if (!initWarp)
            flags |= WARPF_Interpolate;

        Warp (master, xofs: 64.0, zofs: zOffs, angle: rotAngle, flags: flags);
    }

    override void PostBeginPlay () {
        A_RearrangePointers (AAPTR_Master, AAPTR_Default, AAPTR_Master);

        if (!master || master.health < 1 || !(master is 'S7_Empress'))
            Destroy ();

        owner = S7_Empress (master);

        rotAngle = 270;
        countdown = 35 * 12;

        owner.ballsCount++;

        OrbitMaster (true);
        ClearInterpolation ();
    }

    void WasDestroyed () {
        if (!owner)
            return;

        owner.ballsCount--; // Ouch.
        if (owner.ballsCount < 0)
            owner.ballsCount = 0;

        if (!owner.ballsCount)
            owner.shieldUp = false;
    }

    states {
    Spawn:
        HRSF A 1 bright {
            OrbitMaster ();

            if (!owner.castingInvuln)
                countdown--;

            rotAngle += rotAmount;

            if (countdown < 1) {
                A_Die ('NonKilledDeath');
                return ResolveState ("Death.NonKilledDeath");
            }

            return ResolveState (null);
        }
        loop;

    Death:
        TNT1 A 1 {
            WasDestroyed ();
            A_DamageMaster (random [miscDamage] (1, 8) * 8, 'Empress_BallExploded', DMSS_FoilInvul); // That's gotta hurt.
        }
        // Explosion here
        stop;
    Death.NonKilledDeath:
        HRSF A 1 {
            OrbitMaster ();

            rotAngle += rotAmount;

            A_FadeOut (0.03, 0);

            return (alpha <= 0) ? ResolveState ("KILLKILLKILL") : ResolveState (null);
        }
        loop;
    Death.EmpressDeath:
        HRSF A 1 bright {
            A_Stop ();
            A_FadeOut (0.03, 0);
            return (alpha <= 0) ? ResolveState ("KILLKILLKILL") : ResolveState (null);
        }
        loop;
    KILLKILLKILL:
        TNT1 A 1 WasDestroyed ();
        stop;
    }
}

class S7_EmpressInvulnOrbiterCCW : S7_EmpressInvulnOrbiterCW {
    default {
        S7_EmpressInvulnOrbiterCW.RotAmount -10.0;
        S7_EmpressInvulnOrbiterCW.UseCos true;
    }
}