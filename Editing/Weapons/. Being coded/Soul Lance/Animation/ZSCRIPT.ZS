version "3.3"

class S7_SLance_BeamHeld_Fire : S7_Boolean { }
class S7_SoulLance : S7_BaseWeapon {
    default {
        weapon.AmmoUse 0;
        weapon.AmmoGive 0;
        weapon.SlotNumber 0;

        -weapon.noAlert
    }

    S7_SoulLance_Beam beamActor;
    Actor beamHit;

    action void S7_A_MaintainBeam () {
        let pPawn = PlayerPawn (self);
        if (!invoker.beamActor || !pPawn)
            return;

        double cospitch = cos (pitch), maxDist = radius * radius;
        double spawnOff = 20.0;
        FTranslatedLineTarget lTarget;
        let puff = LineAttack (angle, 8192.0, pitch, 0, "None", "S7_SoulLancePuff", LAF_NoRandomPuffZ | LAF_NoImpactDecal, lTarget);
        invoker.beamHit = lTarget.linetarget;
        let tmpPoint = (spawnOff * cospitch * cos (angle), spawnOff * cospitch * sin (angle), spawnOff * -sin (pitch));

        do {
            tmpPoint *= 0.5;
        } while ((tmpPoint.XY dot tmpPoint.XY) >= maxDist);

        let posOff = (0.0, 2.25, ((height / 2.0) + pPawn.attackZOffset) - 2.25);
        invoker.beamActor.Warp (self, posOff.X, posOff.Y, posOff.Z, flags: WARPF_NoCheckPosition | WARPF_CopyInterpolation);
        invoker.beamActor.SetOrigin (invoker.beamActor.Vec3Offset (tmpPoint.X, tmpPoint.Y, tmpPoint.Z), false);

        invoker.beamActor.scale.Y = -invoker.beamActor.Distance3D (puff);
        invoker.beamActor.A_Face (puff, 0, 0);
        invoker.beamActor.pitch += 90.0;
    }

    action void S7_A_BeamDamage () {
        if (!invoker.beamHit)
            return;

        invoker.beamHit.DamageMobj (self, self, random (1, 2) * 5, "S7_SoulLance_Beam", DMG_No_Armor | DMG_Thrustless | DMG_PlayerAttack);
    }

    states {
    Ready:
        SLNC ABCD     1;
        SLNC E        5;
        SLNC FGHIJKLM 1;
    Ready2:
        SLNC M 1 {
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            TakeInventory ("S7_Reloading", 0x7FFFFFFF);
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;
    Fire:
        SLNC NOPQRS 1;
        SLNC TU     2;
        TNT1 A      0 {
            invoker.beamActor = S7_SoulLance_Beam (Spawn ("S7_SoulLance_Beam"));
            if (invoker.beamActor) {
                invoker.beamActor.target = self;
                invoker.beamActor.goAway = false; // Just to make sure
            }
        }
    Hold:
        SLNC V       1 { // Effects and damage here
            A_DamageSelf (2, "SoulLanceSelfDamage");
            S7_A_MaintainBeam ();
            S7_A_BeamDamage ();
        }
        SLNC VWW     1 S7_A_MaintainBeam ();
        SLNC X       1 { // Effects and damage here
            S7_A_MaintainBeam ();
            S7_A_BeamDamage ();
        }
        SLNC XYY     1 S7_A_MaintainBeam ();
        SLNC U       2 {
            S7_A_MaintainBeam ();

            A_Refire ();

            return ResolveState (null);
        }
        SLNC T        1 {
            if (invoker.beamActor)
                invoker.beamActor.goAway = true;
            invoker.beamActor = null;
        }
        SLNC TSRQPONM 1;
        goto Ready2;

    Select:
        TNT1 A 0 A_Raise;
        wait;
    Deselect:
        TNT1 A 0 {
            if (invoker.Owner.health < 1)
                return ResolveState ("TrueDeselect");
            if (CheckInventory ("S7_SoulLance_BeamGrabbed", 1))
                return ResolveState ("Deselect.BeamGrab");

            return ResolveState (null);
        }
    TrueDeselect:
        SLNC MMMMLKJIHGFEDCBA 1;

        TNT1 A 0 A_Lower;
        wait;
    Deselect.BeamGrab:
        TNT1 AAAAAAAAAAAAAAAA 0 A_WeaponReady (WRF_NoFire | WRF_NoSwitch | WRF_DisableSwitch | WRF_NoBob);
        goto Fire.Grabbed;
    }
}

class S7_SoulLancePuff : S7_TraceTestPuff {
    default {
        +alwaysPuff +puffOnActors +skyExplode
    }

    states {
    Spawn:
    Death:
        TNT1 A 1;
        stop;
    }
}

class S7_SoulLance_Beam : Actor {
    default {
        radius 8;
        height 8;
        renderStyle "add";
        //decal "Scorch";
        alpha 1.0;
        renderRadius 8200;

        +noGravity +noInteraction
    }

    bool goAway;

    states {
    Spawn:
        SLCF A 1 bright {
            if (!target || target.health <= 0)
                return ResolveState ("Null");
            if (goAway)
                return ResolveState ("Death");

            return ResolveState (null);
        }
        loop;
    Death:
        SLCF A 1 {
            A_FadeOut (0.06);
            scale.X *= 0.65;
        }
        loop;
    }
}

class S7_SoulLance_Beam_Explosion : S7_SoulLance_Beam {
    default {
        scale 1.0;
        translation "192:207=24:39", "224:224=16:16", "240:247=40:47";

        +forceXYBillboard
    }

    states {
    Spawn:
        PLSE A 2 bright {
            for (int i = 0; i < 4; i++) {
                A_SpawnItemEx ("S7_SoulLance_Sparks",  0.0, 0.0, 0.0, frandom [sfx] (-2.5, 2.5), frandom [sfx] (-2.5, 2.5), frandom [sfx] (-0.5, 3.5), 0, SXF_Clientside);
                A_SpawnItemEx ("S7_SoulLance_Sparks2", 0.0, 0.0, 0.0, frandom [sfx] (-2.5, 2.5), frandom [sfx] (-2.5, 2.5), frandom [sfx] (-0.5, 3.5), 0, SXF_Clientside);
                A_SpawnItemEx ("S7_SoulLance_Sparks3", 0.0, 0.0, 0.0, frandom [sfx] (-2.5, 2.5), frandom [sfx] (-2.5, 2.5), frandom [sfx] (-0.5, 3.5), 0, SXF_Clientside);
                A_SpawnItemEx ("S7_SoulLance_Sparks4", 0.0, 0.0, 0.0, frandom [sfx] (-2.5, 2.5), frandom [sfx] (-2.5, 2.5), frandom [sfx] (-0.5, 3.5), 0, SXF_Clientside);
            }
        }
        PLSE BCDE 2 bright;
        stop;
    }
}


class S7_SoulLance_Sparks : S7_TracerEffectsBase {
    default {
        gravity 0.38;
        scale 0.03;

        -noGravity -noInteraction
    }

    states {
    Spawn:
        SLCF A 1 bright;
        SLCF A 1 bright A_FadeOut (0.05);
        wait;
    }
}

class S7_SoulLance_Sparks2 : S7_SoulLance_Sparks {
    default {
        translation "192:207=24:39", "224:224=16:16", "240:247=40:47";
        scale 0.1;
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_Jump (256, "Spawn1", "Spawn2");
    Spawn1:
        PLSS A 1 bright;
        goto Fade;
    Spawn2:
        PLSS B 1 bright;
        goto Fade;
    Fade:
        ---- A 1 bright A_FadeOut (0.05);
        wait;
    }
}
class S7_SoulLance_Sparks3 : S7_SoulLance_Sparks2 {
    default {
        translation "192:207=168:183", "240:247=184:191";
    }
}
class S7_SoulLance_Sparks4 : S7_SoulLance_Sparks2 {
    default {
        translation "193:194=250:250", "195:196=251:251", "197:198=252:252", "199:199=253:253", "205:205=253:253", "202:202=253:253", "241:241=254:254";
    }

    states {
    Spawn2:
        goto Spawn1;
    }
}

class S7_SoulLance_Beam_Trail : S7_FastProjTrailBase {
    default {
        renderStyle "add";
        scale 0.060;
        alpha 1.0;
    }

    states {
    Spawn:
        SLCF A 1 bright;
        ---- A 1 bright A_FadeOut (0.065);
        wait;
    }
}