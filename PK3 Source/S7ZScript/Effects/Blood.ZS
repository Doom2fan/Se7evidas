const S7_BloodSXFFlags = SXF_TransferTranslation | SXF_NoCheckPosition;

//-------------------------------------------------------------------------------------------
//
// Blood actors
//
//-------------------------------------------------------------------------------------------
class S7_Blood : Blood replaces Blood {
    default {
        +PUFFGETSOWNER +NOBLOCKMAP +NOTELEPORT
    }

    states {
    Spawn:
        BLD1 C  1 noDelay { //A_SpawnDebris ("S7_Flying_Blood", true);
            A_FaceTarget ();
            angle = -angle;

            double xo = fRandom [sfx] (-2, 2),
                   yo = fRandom [sfx] (-2, 2),
                   zo = fRandom [sfx] (-2, 2);

            double xvel = fRandom [sfx] (0, 6),
                   zvel = fRandom [sfx] (4, 7);

            A_SpawnItemEx ("S7_Flying_Blood", xofs: xo, yofs: yo, zofs: zo, xvel: xvel, zvel: zvel, angle: fRandom [sfx] (0, 360), flags: S7_BloodSXFFlags);
        }
        BLD1 BA 1;
        stop;
    }
}

class S7_BloodSplatter : S7_Blood replaces BloodSplatter {
    states {
    Spawn:
        TNT1 A 0 noDelay A_ChangeVelocity (0.0, 0.0, 0.0, CVF_Replace);
        goto Super::Spawn;
    }
}

//-------------------------------------------------------------------------------------------
//
// Flying blood actors
//
//-------------------------------------------------------------------------------------------
class S7_Flying_Blood : S7_EffectsBase {
    default {
        Radius 8;
        Height 1;

        +NOTELEPORT +NOBLOCKMAP +THRUSPECIES +THRUACTORS
        +CLIENTSIDEONLY
    }

    states {
    Spawn:
        TNT1 A 0 noDelay { bMissile = true; }
        BLD1 CCCBBBAAA 1 A_SpawnItemEx ("S7_Flying_Blood_Trail", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, S7_BloodSXFFlags);
        loop;

    Death:
        TNT1 A 1 {
            if (BlockingMobj || BlockingLine || pos.Z > (floorZ + 1))
                return ResolveState ("Crash");

            A_SpawnItemEx ("S7_BloodSpot", flags: S7_BloodSXFFlags);

            return ResolveState ("Null");
        }
        stop;

    Crush:
    XDeath:
    Crash:
        TNT1 A 1;
        stop;
    }
}

class S7_Flying_Blood_Trail : S7_EffectsBase {
    default {
        Gravity 0.25;

        +NOTELEPORT +NOBLOCKMAP +CLIENTSIDEONLY +NOINTERACTION
    }

    states {
    Spawn:
        BLD1 CCBBAA 1;
        stop;
    }
}

class S7_BloodSpot : S7_EffectsBase {
    default {
        +NOTELEPORT    +NOBLOCKMAP     +THRUSPECIES    +THRUACTORS
        +NOINTERACTION +MOVEWITHSECTOR +CLIENTSIDEONLY
    }

    int timer;

    states {
    Spawn:
        BLD2 ABCDEF 2;
    Waiting:
        BLD2 G 1 {
            let stayTimeCVar = CVar.GetCVar ("S7_BloodSpotsStayTime", players [consolePlayer]);
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
        BLD2 G 1 {
            let fadeSpeedCVar = CVar.GetCVar ("S7_BloodSpotsFadeSpeed", players [consolePlayer]);
            A_FadeOut (fadeSpeedCVar.GetFloat ());
        }
        wait;
    }
}