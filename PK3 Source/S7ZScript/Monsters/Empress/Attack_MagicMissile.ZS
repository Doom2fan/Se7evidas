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

extend class S7_Empress {
    int attackMagicMissile_Shots;

    states {
    Attack.MagicMissile:
        HRFR AAA  1 A_FaceTarget (24, 12);
        HRFR FFFF 2 bright A_FaceTarget (24, 12);
        HRFR FFFF 2 bright A_FaceTarget (24, 12);
        HRFR FFFF 2 bright A_FaceTarget (24, 12);
        HRFR FFFF 2 bright A_FaceTarget (24, 12);
        TNT1 A    0 {
            attackMagicMissile_Shots = random [monsterSpc] (5, 12);
            A_FaceTarget (0, 0);
        }
    Attack.MagicMissile.Loople:
        HRFR E    1 bright {
            let proj = S7_EmpressMissile2 (A_SpawnProjectile ('S7_EmpressMissile2', 50.,  16, angle: fRandom [monsterSpread] (-.5, .5), pitch: fRandom [monsterSpread] (-1.25, 1.25)));
            if (proj)
                proj.bonusDMGFactor = GetDamageBonus ();
        }
        HRFR EEEE 1 bright A_FaceTarget (90, 45);
        HRFR E    1 bright {
            let proj = S7_EmpressMissile2 (A_SpawnProjectile ('S7_EmpressMissile2', 50., -16, angle: fRandom [monsterSpread] (-.5, .5), pitch: fRandom [monsterSpread] (-1.25, 1.25)));
            if (proj)
                proj.bonusDMGFactor = GetDamageBonus ();
        }
        HRFR EEEE 1 bright A_FaceTarget (90, 45);
        HRFR E    1 bright {
            if ((attackMagicMissile_Shots--) <= 0) {
                attackMagicMissile_Shots = 0;

                return ResolveState ("See");
            }

            return A_MonsterRefire (40, "See");
        }
        loop;
    }
}

class S7_EmpressMissile2 : S7_Projectile {
    double bonusDMGFactor;

    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.FastProjCollision ColMode_Center | ColMode_Corners;

        Radius 9;
        Height 20;
        Speed 40;

        DamageFunction ((12. + fRandom [monsterDMG] (-2., 2.)) * (1. + bonusDMGFactor));
        MissileType 'S7_EmpressMissile2Trail';
        MissileHeight 8;

        RenderStyle "add";
        Scale .075;

        SeeSound "";
        DeathSound "Misc/Common/FireballHit";
        Obituary "$OB_EMPRESSFB";
        Species 'S7EmpressCrap';

        +FORCEXYBILLBOARD +SEEKERMISSILE +THRUSPECIES
    }

    states {
    Spawn:
        HRSF AAAAAAAA 1 noDelay bright A_SeekerMissile (4, 4);
        HRSF A 1 bright;
        wait;

    Death:
        TNT1 A 0 A_SetScale (1.);
        HRP1 ABCDE 2 bright;
        stop;
    }
}

class S7_EmpressMissile2Trail : S7_FastProjTrailBase {
    default {
        RenderStyle "add";
        Scale .075;

        +FORCEXYBILLBOARD
    }

    states {
    Spawn:
        HRSF AAA 1 bright A_FadeOut (.5);
        stop;
    }
}