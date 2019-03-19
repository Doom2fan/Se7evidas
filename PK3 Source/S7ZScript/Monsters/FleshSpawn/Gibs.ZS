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

class S7_FleshSpawnGib1 : S7_GoreBase {
    default {
        +MOVEWITHSECTOR +THRUACTORS
        -SOLID
    }

    transient CVar stayTimeCVar, fadeSpeedCVar;
    int timer;

    states {
    Spawn:
        FSGB ABCD 4 A_CheckFloor ("HitGround");
        loop;
    HitGround:
        FSGB E 0;
        goto Waiting;

    Waiting:
        #### # 1 {
            vel = (0, 0, 0);
            A_Stop ();
            bNoInteraction = true;

            if (!stayTimeCVar)
                stayTimeCVar = CVar.GetCVar ("S7_GibsStayTime", players [consolePlayer]);

            int stayTime = stayTimeCVar.GetInt ();

            if (stayTime > -1) {
                if (timer >= stayTime)
                    return ResolveState ("Fade");

                timer++;
            }

            return ResolveState (null);
        }
        wait;
    Fade:
        #### # 1 {
            if (!fadeSpeedCVar)
                fadeSpeedCVar = CVar.GetCVar ("S7_GibsFadeSpeed", players [consolePlayer]);

            A_FadeOut (fadeSpeedCVar.GetFloat ());
        }
        wait;
   }
}

class S7_FleshSpawnGib2 : S7_FleshSpawnGib1 {
    states {
    Spawn:
        FSGB FGHI 4 A_CheckFloor ("HitGround");
        loop;
    HitGround:
        FSGB J 0;
        goto Waiting;
    }
}

class S7_FleshSpawnGib2B : S7_FleshSpawnGib2 {
    default {
        XScale -1;
    }
}

class S7_FleshSpawnGib3 : S7_FleshSpawnGib1 {
    states {
    Spawn:
        FSGB KLMN 4 A_CheckFloor ("HitGround");
        loop;
    HitGround:
        FSGB O 0;
        goto Waiting;
    }
}

class S7_FleshSpawnGib4 : S7_FleshSpawnGib1 {
    states {
    Spawn:
        FSGB PQRS 4 A_CheckFloor ("HitGround");
        loop;
    HitGround:
        FSGB T 0;
        goto Waiting;
   }
}

class S7_FleshSpawnGib4B : S7_FleshSpawnGib4 {
    default {
        XScale -1;
    }
}

class S7_FleshSpawnGib5 : S7_FleshSpawnGib1 {
    states {
    Spawn:
        FSGB UVWX 4 A_CheckFloor ("HitGround");
        loop;
    HitGround:
        FSGB Y 0;
        goto Waiting;
    }
}

class S7_FleshSpawnGib6 : S7_FleshSpawnGib1 {
    states {
    Spawn:
        FLSP V 4 A_CheckFloor ("HitGround");
        loop;
    HitGround:
        FLSP WX 4;
        FLSP Y 0;
        goto Waiting;
    }
}