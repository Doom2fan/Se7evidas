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

class S7_Empress_FXBase : S7_EffectsBase {
    default {
        RenderStyle "add";

        +NOTELEPORT +NOINTERACTION  +NOBLOCKMAP +NOGRAVITY
        +THRUACTORS +CLIENTSIDEONLY
    }
}

//-------------------------------------------------------------------------------------------
//
// Blood
//
//-------------------------------------------------------------------------------------------
class S7_EmpressBlood : S7_Blood {
    override void PostBeginPlay () {
        let empress = S7_Empress (target);
        if (!empress) {
            Destroy ();
            return;
        }

        if (empress.shieldUp && abs (empress.AngleTo (self)) <= S7_Empress.InvulnShieldAngle) {
            Destroy ();
            return;
        }

        Super.PostBeginPlay ();
    }
}

class S7_EmpressBloodSplatter : S7_EmpressBlood {
    states {
    Spawn:
        TNT1 A 0 noDelay A_ChangeVelocity (0.0, 0.0, 0.0, CVF_Replace);
        goto Super::Spawn;
    }
}

//-------------------------------------------------------------------------------------------
//
// Spawner
//
//-------------------------------------------------------------------------------------------
/** Smoke **/
class S7_EmpressSmoke : S7_ShotSmoke_2 {
    default {
        RenderStyle "subtract";
        Alpha 0.6;
        Scale 0.8;

        +NOINTERACTION +FORCEXYBILLBOARD +CLIENTSIDEONLY
    }

    states {
    Spawn:
        ESPS ABCDEFGHIJKLMNOPQRSTUVW 1;
        stop;
    }
}

/** Sparkle **/
class S7_EmpressSparkle : S7_Empress_FXBase {
    default {
        RenderStyle "add";

        +FORCEXYBILLBOARD
    }

    int loopCount;

    states {
    Spawn:
        TNT1 A 0 noDelay {
            A_SetScale (fRandom [S7_MiscSFXRNG] (0.25, 0.4));
            loopCount = random [S7_MiscSFXRNG] (8, 14);
            return A_Jump (256, "SpawnA", "SpawnB", "SpawnC", "SpawnD", "SpawnE", "SpawnF", "SpawnG", "SpawnH");
        }

    SpawnA: HRSS A 0; goto FadeOut;
    SpawnB: HRSS B 0; goto FadeOut;
    SpawnC: HRSS C 0; goto FadeOut;
    SpawnD: HRSS D 0; goto FadeOut;
    SpawnE: HRSS E 0; goto FadeOut;
    SpawnF: HRSS F 0; goto FadeOut;
    SpawnG: HRSS G 0; goto FadeOut;
    SpawnH: HRSS H 0; goto FadeOut;

    FadeOut:
        "----" A 1 bright {
            return (loopCount-- < 1) ? ResolveState ("ReallyFadeOutNow") : ResolveState (null);
        }
        loop;
    ReallyFadeOutNow:
        "----" A 1 bright A_FadeOut (0.1);
        wait;
    }
}

/** Pentagram **/
// Corner
class S7_EmpressPentagramCorner : S7_Empress_FXBase {
    states {
    Spawn:
        TNT1 A 0 noDelay {
            Array<Actor> lines; lines.Clear ();
            lines.Push (A_SpawnProjectile ('S7_EmpressPentagramLine', 0.0, 0, -198, CMF_AimDirection));
            lines.Push (A_SpawnProjectile ('S7_EmpressPentagramLine', 0.0, 0,  198, CMF_AimDirection));

            for (int i = 0; i < lines.Size (); i++) {
                let line = lines [i];

                if (!line)
                    continue;

                line.SetOrigin (pos, false);
            }
        }
        stop;
    }
}

// Line
class S7_EmpressPentagramLine : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.FastProjCollision 0;
        S7_Projectile.InterpMove false;

        Radius 1;
        Height 1;
        DamageFunction (0);
        Speed 18;

        MissileType "S7_EmpressPentagramFire";

        +NOTARGET +NOBLOOD +NOCLIP +THRUACTORS
        +PAINLESS +RIPPER  +BLOODLESSIMPACT
    }

    override Actor StepEffects (Vector3 initialPos, Vector3 stepDiff, Vector3 realVel) {
        class<Actor> trail = MissileName;

        if (trail != null) {
            Vector3 finalPos = level.Vec3Offset (initialPos, stepDiff);

            Actor act = Spawn (trail, initialPos, ALLOW_REPLACE);
            act.SetOrigin (finalPos, false);

            if (act != null) {
                act.angle = angle;
                act.pitch = pitch;
            }

            return act;
        }

        return NULL;
    }

    states {
    Spawn:
        TNT1 AAAAAAAAAA 1;// A_SpawnItemEx ('S7_EmpressPentagramFire', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
        stop;
    Death:
        TNT1 A 1;
        stop;
    }
}

// Fire
class S7_EmpressPentagramFire : S7_Empress_FXBase {
    default {
        Radius 1;
        Height 1;
        ReactionTime 4;
        Scale 0.1;

        +FORCEXYBILLBOARD
    }

    states {
    Spawn:
        HRSF AAAAAAAAAAAAA 3 bright;
        //EPTF ABCDEFGHIJKLM 3 bright;
        TNT1 A             0 A_Countdown;
        loop;

    Death:
        /*EPTF NOP 3 bright;
        stop;*/
        HRSF A 1 A_FadeOut (0.1);
        loop;
    }
}



//-------------------------------------------------------------------------------------------
//
// Invuln orbiters
//
//-------------------------------------------------------------------------------------------
class S7_EmpressShieldSparkle : S7_EmpressSparkle {
    default {
        Scale 0.2;
    }

    double rotAngle;
    double zOffs;
    Vector3 offs;

    states {
    Spawn:
        TNT1 A 0 noDelay {
            loopCount = 2;
            return A_Jump (256, "SpawnA", "SpawnB", "SpawnC", "SpawnD", "SpawnE", "SpawnF", "SpawnG", "SpawnH");
        }
    ReallyFadeOutNow:
        "----" A 1 bright {
            if (!self)
                return;

            offs += vel;
            if (target)
                Warp (target, xofs: 64 + offs.X, yofs: offs.Y, zofs: zOffs + offs.Z, angle: rotAngle, flags: WARPF_NoCheckPosition | WARPF_Interpolate);
            A_FadeOut (0.15);
        }
        wait;
    }
}
class S7_EmpressShieldFlare : S7_Empress_FXBase {
    default {
        Scale 0.1;
        Alpha 0.5;

        +FORCEXYBILLBOARD
    }

    double rotAngle;
    double zOffs;

    override void Tick () {
        if (self && target)
            Warp (target, xofs: 64, zofs: zOffs, angle: rotAngle, flags: WARPF_NoCheckPosition | WARPF_Interpolate);

        Super.Tick ();
    }

    states {
    Spawn:
        HRSF A 3 bright;
        HRSF A 1 bright A_FadeOut (0.03);
        wait;
    }
}

//-------------------------------------------------------------------------------------------
//
// Invuln hitspark
//
//-------------------------------------------------------------------------------------------
class S7_EmpressShieldHitspark : S7_Empress_FXBase {
    states {
    Spawn:
        TNT1 A 0 noDelay {
            for (int i = random [S7_HitsparksRNG] (4, 6); i > 0; i--) {
                A_SpawnItemEx ('S7_EmpressShieldHitsparkSparkle',
                    xvel: fRandom [S7_HitsparksRNG] (2, 8), zvel: fRandom [S7_HitsparksRNG] (-6, 6), angle: fRandom [S7_HitsparksRNG] (0, 360),
                    flags: SXF_NoCheckPosition | SXF_Clientside
                );
            }
        }
        stop;
    }
}

class S7_EmpressShieldHitsparkSparkle : S7_EmpressSparkle {
    default {
        Scale 0.1;
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            loopCount = random [S7_HitsparksRNG] (1, 2);
            return A_Jump (256, "SpawnA", "SpawnB", "SpawnC", "SpawnD", "SpawnE", "SpawnF", "SpawnG", "SpawnH");
        }
    ReallyFadeOutNow:
        "----" A 1 bright A_FadeOut (0.25);
        wait;
    }
}