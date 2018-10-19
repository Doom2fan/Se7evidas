/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

class FleshSpawnGib1 : S7_GoreBase {
    default {
        +MOVEWITHSECTOR +THRUACTORS
        -SOLID
    }

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

            let stayTimeCVar = CVar.GetCVar ("S7_GibsStayTime", players [consolePlayer]);
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
            let fadeSpeedCVar = CVar.GetCVar ("S7_GibsFadeSpeed", players [consolePlayer]);
            A_FadeOut (fadeSpeedCVar.GetFloat ());
        }
        wait;
   }
}

class FleshSpawnGib2 : FleshSpawnGib1 {
    states {
    Spawn:
        FSGB FGHI 4 A_CheckFloor ("HitGround");
        loop;
    HitGround:
        FSGB J 0;
        goto Waiting;
    }
}

class FleshSpawnGib2B : FleshSpawnGib2 {
    default {
        XScale -1;
    }
}

class FleshSpawnGib3 : FleshSpawnGib1 {
    states {
    Spawn:
        FSGB KLMN 4 A_CheckFloor ("HitGround");
        loop;
    HitGround:
        FSGB O 0;
        goto Waiting;
    }
}

class FleshSpawnGib4 : FleshSpawnGib1 {
    states {
    Spawn:
        FSGB PQRS 4 A_CheckFloor ("HitGround");
        loop;
    HitGround:
        FSGB T 0;
        goto Waiting;
   }
}

class FleshSpawnGib4B : FleshSpawnGib4 {
    default {
        XScale -1;
    }
}

class FleshSpawnGib5 : FleshSpawnGib1 {
    states {
    Spawn:
        FSGB UVWX 4 A_CheckFloor ("HitGround");
        loop;
    HitGround:
        FSGB Y 0;
        goto Waiting;
    }
}

class FleshSpawnGib6 : FleshSpawnGib1 {
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