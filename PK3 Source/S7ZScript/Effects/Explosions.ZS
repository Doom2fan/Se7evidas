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

class S7_ExplosionSound : S7_EffectsBase {
    default {
        Radius 0;
        Height 0;

        RenderStyle "None";

        +INVISIBLE
    }

    const Attenuation_Close = 0.5;
    const Attenuation_Distant = 0.125;

    const AttnDist_Close = ((512. * 3.) / Attenuation_Close) * 1.5;
    const Dist_MinVol = 0.00000001;

    const Channel_Close = CHAN_5;
    const Channel_Distant = CHAN_6;
    int duration;

    static void CreateExplosion1 (Vector3 pos) {
        int soundNum = random [S7_RandomSound] (1, 4);

        Sound closeSound = String.Format ("Explosions/Explosion1_%d", soundNum);
        Sound distantSound = String.Format ("Explosions/MuffledExplosion1_%d", soundNum);

        CreateExplosionSound (pos, closeSound, distantSound);
    }

    static void CreateExplosion2 (Vector3 pos) {
        int soundNum = random [S7_RandomSound] (1, 3);

        Sound closeSound = String.Format ("Explosions/Explosion2_%d", soundNum);
        Sound distantSound = String.Format ("Explosions/MuffledExplosion2_%d", soundNum);

        CreateExplosionSound (pos, closeSound, distantSound);
    }

    static void CreateExplosionSound (Vector3 pos, Sound closeSound, Sound distantSound) {
        int duration = int ((TicRate * ceil (max (S_GetLength (closeSound), S_GetLength (distantSound)))) + 5);

        let act = S7_ExplosionSound (Spawn ('S7_ExplosionSound', pos, ALLOW_REPLACE));

        if (!act)
            return;

        act.duration = duration;
        act.A_StartSound (closeSound, slot: Channel_Close, volume: 1., attenuation: Attenuation_Close);
        act.A_StartSound (distantSound, slot: Channel_Distant, volume: Dist_MinVol, attenuation: Attenuation_Distant);
    }

    override void Tick () {
        if (--duration < 1) {
            A_StopSound (Channel_Close);
            A_StopSound (Channel_Distant);

            Destroy ();
            return;
        }

        let cam = players [consoleplayer].camera;
        // If the camera is null, try the PlayerPawn.
        if (!cam)
            cam = players [consoleplayer].mo;
        // If the PlayerPawn is null too, abort!
        if (!cam)
            return;

        double dist = cam.Distance3D (self);
        A_SoundVolume (Channel_Distant, clamp (dist / AttnDist_Close, Dist_MinVol, 1.));
    }

    states {
    Spawn:
        TNT1 A -1;
        stop;
    }
}

class S7_GenericExplosion : S7_EffectsBase {
    default {
        RenderStyle "add";
        scale -1;

        +NOBLOCKMAP +NOINTERACTION +FORCEXYBILLBOARD
    }

    bool noSmoke;

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        if (!target)
            return;

        if (scale.X ~== -1)
            scale = target.scale;
        A_SetSize (target.radius, target.height);
    }

    override void Tick () {
        if (isFrozen ())
            return;

        CheaperTick ();
    }

    states {
    Spawn:
        XPL1 A 3 noDelay bright {
            if (!noSmoke) {
                for (int i = random [sfx] (2, 4); i > 0; i--) {
                    let act = S7_Smoke3 (Spawn ("S7_Smoke3", pos + (fRandom [sfx] (-15, 15), fRandom [sfx] (-15, 15), 0), ALLOW_REPLACE));

                    act.scale = (0.25 * scale.X, 0.25 * scale.Y);
                    act.vel = (
                        fRandom [sfx] (-.15, .15),
                        fRandom [sfx] (.1, .5) * fRandomPick [sfx] (-1, 1),
                        fRandom [sfx] (-.5, .5)
                    );
                    act.fadeInTime = 0;
                    act.stayTime = 15;
                    act.fadeOutTime = 10;
                    act.targetAlpha = .5;
                }
            }

            let prevInterp = Prev;
            SetPosition (pos);
            ClearInterpolation ();
            Prev = prevInterp;

            {
                let vert = Spawn ("S7_GenericExplosion_Shockwave", pos, ALLOW_REPLACE);
                vert.scale.X = scale.X;
                vert.angle = angle;
                vert.pitch = 90;
            }

            for (int i = 0; i < 3; i++) {
                let act = Spawn ("S7_GenericExplosion_Shockwave", pos, ALLOW_REPLACE);
                act.scale.X = scale.X;
                act.angle = fRandom [sfx] (-90, 90);
                act.pitch = 45 + fRandom [sfx] (0, 45);
            }
        }
        XPL1 BCDE 2 bright;
        stop;
    }
}

class S7_GenericExplosion_Shockwave : S7_EffectsBase {
    default {
        Radius 10;
        Height 10;

        RenderStyle "AddStencil";
        StencilColor "CB5707";
        Alpha .5;

        +NOGRAVITY +FORCEXYBILLBOARD +NOINTERACTION +NOBLOCKMAP
    }

    override void Tick () {
        if (isFrozen ())
            return;

        CheaperTick ();
    }

    double effectScale;

    states {
    Spawn:
        TNT1 A 0 noDelay {
            effectScale = scale.X;
            scale.X = 12 * effectScale;
        }

        SHCK AAAAA 1 bright { scale.X += 12 * effectScale; }
        SHCK A     1 bright {
            scale.X += 12 * effectScale;
            A_FadeOut (0.2);
        }
        wait;
    }
}