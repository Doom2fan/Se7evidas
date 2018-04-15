//-------------------------------------------------------------------------------------------
//
// Grenade
//
//-------------------------------------------------------------------------------------------
class S7_GrenadeCount : Ammo {
    default {
        Inventory.MaxAmount 15;
        Ammo.BackpackMaxAmount 15;

        +INVENTORY.IGNORESKILL
    }
}

class S7_GrenadeWeap : S7_ThrowWeapon {
    default {
        Tag "$GRENADEWEAP";
        Weapon.AmmoType "S7_GrenadeCount";
        Weapon.AmmoUse 0;
        Weapon.AmmoGive 0;
        S7_BaseWeapon.Icon "TGRNZ0";
        S7_BaseWeapon.ShortTag "$GRENADEWEAP";
        S7_BaseWeapon.BindSlot WpSlot_Special;
        S7_ThrowWeapon.MaxForce 30;
    }

    override void Throw () {
        Owner.TakeInventory ("S7_GrenadeCount", 1, TIF_NoTakeInfinite);
        SpawnObject ("S7_ThrownHandGrenade");
    }

    states {
    Ready:
    Ready2:
        TNT1 A 1 {
            TakeInventory ("S7_Reloading", 0x7FFFFFFF);
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");

            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Fire:
        TNT1 A      0 A_JumpIfInventory ("S7_GrenadeCount", 1, 1);
        goto Ready2;
        TGRN WXY    1;
        TGRN ABCDEF 1;
        TGRN G      1 A_PlaySound ("Weapons/GrenadePinPull", CHAN_Weapon);
        TGRN HIJKLM 1;
        TNT1 A      1;
        goto Hold;

    CancelThrow:
        TNT1 A      1 {
            TakeInventory ("S7_Reloading", 0x7FFFFFFF);
            invoker.throwForce = 0;
            A_ClearRefire ();
        }
        TGRN MLKJIH 1;
        TGRN G      1 A_PlaySound ("Weapons/GrenadePinPull", CHAN_Weapon);
        TGRN FEDCBA 1;
        TGRN YXW    1;
        goto Ready2;
    }
}

//-------------------------------------------------------------------------------------------
//
// Thrown grenade
//
//-------------------------------------------------------------------------------------------
class S7_ThrownHandGrenade : S7_ThrownObject {
    default {
        Radius 5;
        Height 5;
        Speed 5;
        Mass 30;
        DamageFunction (0);
        PushFactor 3;
        BounceType "Hexen";
        /*WallBounceFactor 0.25;
        BounceFactor 0.1;*/
        Scale 0.3;

        +CANBOUNCEWATER +USEBOUNCESTATE   +SKYEXPLODE +NOBLOOD
        +NOEXPLODEFLOOR +FORCEXYBILLBOARD
        -NOTELEPORT -NOGRAVITY -FLOORCLIP
    }

    enum GrenadeState {
        GS_Still,
        GS_Moving,
        GS_Exploded = -1,
    }

    GrenadeState grenState;
    Vector3 oldVel;
    float fuse;

    int frameNum;

    override void PostBeginPlay () {
        super.PostBeginPlay ();

        fuse = 35 * 3.5;

        A_ChangeVelocity (cos (pitch) * throwForce, 0, -sin (pitch) * throwForce, CVF_Relative);

        SetState (GS_Moving);
    }

    protected void SetState (GrenadeState newState) {
        grenState = newState;

        switch (grenState) {
            case GS_Still:
                bSolid = true;
                bPushable = true;
                bSolid = true;
                bMissile = false;

                A_ChangeLinkFlags (false);
            break;

            case GS_Exploded:
                bUseBounceState = false;
            case GS_Moving:
                bSolid = false;
                bPushable = false;
                bMissile = true;

                A_ChangeLinkFlags (true);
            break;
        }
    }

    const FrameTime = 2;
    static const string [] GrenSprites = {
        "TGRPA", "TGRPB", "TGRPC", "TGRPD", "TGRPE", "TGRPF", "TGRPG", "TGRPH"
    };

    states {
    Spawn:
        goto Flight;

    Flight:
        TGRP # 1 {
            oldVel = vel;

            if (fuse <= 0)
                return ResolveState ("KABOOM");

            double velSqr = (vel dot vel);
            if (grenState && velSqr ~== 0)
                SetState (GS_Still);
            else if (!grenState && !(velSqr ~== 0))
                SetState (GS_Moving);

            string curFrame = GrenSprites [int (frameNum / FrameTime)];

            if (bMissile && pos.z <= floorz) {
                bMissile = false; // Just to make sure.
                double f = GetFriction ();
                bMissile = true;

                vel.XY *= f;
                if (vel.XY.Length () <= 0.5)
                    vel.XY = (0, 0);
            }

            sprite = GetSpriteIndex (curFrame.Left (4));
            frame = curFrame.CharCodeAt (4) - 65; // 65 == 'A'

            fuse--;

            if (grenState == GS_Moving)
                frameNum = (frameNum + 1) % (GrenSprites.Size () * FrameTime);

            return ResolveState (null);
        }
        goto Spawn;

    Bounce.Floor:
        #### # 0 {
            vel.Z = 0;
        }
        goto Flight;
    Death:
        #### # 0 {
            bUseBounceState = false;
            vel = oldVel;
            oldVel = vel;
        }
        goto Flight;

    KABOOM:
        XPL1 A    3 bright {
            SetState (GS_Exploded);

            A_Stop ();

            scale = (1.0, 1.0);
            A_PlaySound ("Explosions/Explosion1");

            S7_ActorExtensions.A_S7SpawnShrapnel (self, 100, 0.0, 0.0, 2.0, SXF_TransferPointers);
            A_SetDamageType ("ExplosionSplashDMG");
            A_Explode (fRandom [weaponDamage] (192.0, 256.0), fRandom [weaponSpread] (192.0, 256.0));
        }
        XPL1 BCDE 3 bright;
        stop;
    }
}