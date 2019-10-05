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
// Projectile bases
//
//-------------------------------------------------------------------------------------------
class S7_FireballBase : S7_Projectile {
    default {
        S7_Projectile.MovementMode Normal;
        Radius 6;
        Height 16;
        Speed 15;
        FastSpeed 20;
        Damage 8;
        RenderStyle "add";
        Alpha 1.0;
        SeeSound "Misc/Common/Fireball";
        Decal 'BaronScorch';

        +RANDOMIZE
    }
}

//-------------------------------------------------------------------------------------------
//
// Misc bases
//
//-------------------------------------------------------------------------------------------
/** Monster spawner base
*** Usage: Works exactly like RandomSpawner, except it does some changes to boss monster behaviour.
*** Virtuals:
***     void PostSpawn (Actor spawned): Called when the actor is finished spawning. (From RandomSpawner)
***     Name ChooseSpawn (): Called when getting the monster spawn list. (From RandomSpawner)
**/
class S7_MonsterSpawner : RandomSpawner {
    // This function is needed for handling boss replacers
    override void Tick () {
        Actor.Tick ();

        if (!tracer || (tracer.health <= 0 && tracer.tics == -1)) {
            A_BossDeath ();
            Destroy ();
        }
    }
}

class S7_MEvntNoMonster : Actor {
    default {
        Health 0x00FFFFFF;
        Radius 1;
        Height 10000;
        Mass Large_Mass;
        Speed 0;
        DamageFactor 0.0;
        DamageFactor "S7_ForceKillSpcDMG", 10.0;

        Monster;

        +DONTTHRUST +NOTELEPORT +DONTTHRUST +INVULNERABLE
        +VULNERABLE +NOBLOCKMAP +DONTMORPH
        -SHOOTABLE    -SOLID          -COUNTKILL   -CANPASS
        -CANPUSHWALLS -ACTIVATEMCROSS -CANUSEWALLS
    }

    states {
    Spawn:
        TNT1 A 0;
    Idle:
        TNT1 A 1;
        TNT1 A 0 A_CheckSight ("Idle");
        TNT1 A 1 A_Die ('S7_ForceKillSpcDMG');
        wait;

    Death:
        TNT1 A 35 A_NoBlocking;
        TNT1 A -1;
        stop;

    Raise:
        TNT1 A 0;
        goto Idle;
    }
}

class S7_Nothing : Actor {
    states {
    Spawn:
        TNT1 A 1;
        stop;
    }
}

/** FastProjectile trail base **/
class S7_FastProjTrailBase : S7_EffectsBase {
    default {
        +NOBLOCKMAP +NOGRAVITY     +NOTELEPORT     +THRUACTORS
        +CANNOTPUSH +NOINTERACTION +CLIENTSIDEONLY
        -SOLID
    }

    override void Tick () {
        if (isFrozen ())
            return;

        CheaperTick ();
    }
}

/** Trace test puffs **/
class S7_TraceTestPuff : Actor {
    default {
        Radius 1;
        Height 1;

        +NOBLOCKMAP      +ALLOWTHRUFLAGS +NOINTERACTION +NOTIMEFREEZE
        +BLOODLESSIMPACT +PAINLESS
    }

    states {
    Spawn:
    Death:
        TNT1 A 1;
        stop;
    }
}

class S7_WallCheckPuff : S7_TraceTestPuff {
    default {
        +THRUACTORS
    }
}