//-------------------------------------------------------------------------------------------
//
// Projectile bases
//
//-------------------------------------------------------------------------------------------
class S7_FireballBase : actor {
    default {
        radius 6;
        height 16;
        speed 15;
        fastSpeed 20;
        damage 8;
        projectile;
        renderStyle "add";
        alpha 1.0;
        seeSound "baron/attack";
        deathSound "baron/shotx";
        decal "BaronScorch";

        +randomize
    }
}

//-------------------------------------------------------------------------------------------
//
// Misc bases
//
//-------------------------------------------------------------------------------------------
/** Monster spawner base
*** Usage: Works exactly like RandomSpawner, except you can override MS_GetMonsterSpawnList to change the spawner's behaviour.
*** Virtuals:
***     void PostSpawn (Actor spawned): Called when the actor is finished spawning. (From RandomSpawner)
***     DropItem MS_GetMonsterSpawnList (): called when getting the monster spawn list. (From S7_MonsterSpawner)
**/
// 99% of this is taken from the normal RandomSpawner code. I wouldn't need to do this if GetDropItems was a virtual function :V
class S7_MonsterSpawner : RandomSpawner {
    virtual DropItem MS_GetMonsterSpawnList () { return GetDropItems (); }

    // Literally the only reason we're even overriding this is because we can't override GetDropItems.
    override void BeginPlay () {
        DropItem di;   // di will be our drop item list iterator
        DropItem drop; // while drop stays as the reference point.
        int n = 0;
        bool nomonsters = sv_nomonsters || level.nomonsters;

        drop = di = MS_GetMonsterSpawnList ();
        if (di != null) {
            while (di != null) {
                if (di.Name != 'None') {
                    if (!nomonsters || !IsMonster (di)) {
                        int amt = di.Amount;
                        if (amt < 0) amt = 1; // default value is -1, we need a positive value.
                        n += amt; // this is how we can weight the list.
                    }
                    di = di.Next;
                }
            }
            if (n == 0) { // Nothing left to spawn. They must have all been monsters, and monsters are disabled.
                Destroy ();
                return;
            }
            // Then we reset the iterator to the start position...
            di = drop;
            // Take a random number...
            n = random [randomspawn] (0, n - 1);
            // And iterate in the array up to the random number chosen.
            while (n > -1 && di != null) {
                if (di.Name != 'None' && (!nomonsters || !IsMonster (di))) {
                    int amt = di.Amount;
                    if (amt < 0) amt = 1;
                    n -= amt;
                    if ((di.Next != null) && (n > -1))
                        di = di.Next;
                    else
                        n = -1;
                }
                else
                    di = di.Next;
            }
            // So now we can spawn the dropped item.
            if (di == null || bouncecount >= MAX_RANDOMSPAWNERS_RECURSION) { // Prevents infinite recursions
                Spawn ("Unknown", Pos, NO_REPLACE); // Show that there's a problem.
                Destroy ();
                return;
            }
            else if (random [randomspawn] () <= di.Probability) { // prob 255 = always spawn, prob 0 = almost never spawn.
                // Handle replacement here so as to get the proper speed and flags for missiles
                Class<Actor> cls = di.Name;
                if (cls != null) {
                    Class<Actor> rep = GetReplacement (cls);
                    if (rep != null)
                        cls = rep;
                }
                if (cls != null) {
                    Species = Name (cls);
                    readonly<Actor> defmobj = GetDefaultByType (cls);
                    Speed = defmobj.Speed;
                    bMissile |= defmobj.bMissile;
                    bSeekerMissile |= defmobj.bSeekerMissile;
                    bSpectral |= defmobj.bSpectral;
                }
                else {
                    A_Log (TEXTCOLOR_RED .. "Unknown item class ".. di.Name .." to drop from a random spawner (Custom Se7evidas monster spawner)\n");
                    Species = 'None';
                }
            }
        }
    }
}

class S7_MEvntNoMonster : actor {
    default {
        health 0x00FFFFFF;
        radius 1;
        height 10000;
        mass 0x7FFFFFFF;
        speed 0;
        damageFactor 0.0;
        damageFactor "S7_ForceKillSpcDMG", 10.0;

        monster;

        +invulnerable +noTeleport +dontMorph +noTarget
        +vulnerable
        -shootable -solid -countKill -canPass
        -canPushWalls -activateMCross -canUseWalls
    }

    states {
    Spawn:
        TNT1 A 0;
    Idle:
        TNT1 A 1;
        TNT1 A 0 A_CheckSight ("Idle");
        TNT1 A 1 A_Die ("S7_ForceKillSpcDMG");
        wait;

    Death:
        TNT1 A 0 A_NoBlocking;
        TNT1 A -1;
        stop;

    Raise:
        TNT1 A 0;
        goto Idle;
    }
}

/** FastProjectile trail base **/
class S7_FastProjTrailBase : S7_EffectsBase {
    default {
        +noBlockmap +noGravity +noTeleport +thruActors
        +cannotPush +noInteraction +clientsideOnly -solid
    }
}

/** Trace test puffs **/
class S7_TraceTestPuff : actor {
    default {
        radius 1;
        height 1;

        +noBlockmap +allowThruFlags +noInteraction +noTimeFreeze
        +bloodlessImpact +painless
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
        +thruActors
    }
}