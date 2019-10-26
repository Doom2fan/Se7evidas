/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) ????      MatthewTheGlutton
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
// Grenade
//
//-------------------------------------------------------------------------------------------
class S7_GrenadeCount : Ammo {
    default {
        //$Category "Se7evidas/Weapons"
        //$Color 14
        //$Title "Grenade"
        //$NotAngled

        Inventory.PickupMessage "$GRENADE_PICKUP";
        Inventory.PickupSound "Weapons/Grenade/Pickup";

        Inventory.Amount 1;
        Inventory.MaxAmount 15;
        Ammo.BackpackMaxAmount 15;
        Scale 0.3;

        +INVENTORY.IGNORESKILL
    }

    states {
    Spawn:
        HGRN Z -1;
        stop;
    }
}
class S7_GrenadeBox : S7_GrenadeCount {
    default {
        //$Category "Se7evidas/Weapons"
        //$Color 14
        //$Title "Box of Grenades"
        //$NotAngled

        Inventory.PickupMessage "$GRENADEBOX_PICKUP";
        Inventory.PickupSound "";

        Inventory.Amount 4;
        Scale 1.;
    }

    states {
    Spawn:
        GRNB A -1;
        stop;
    }
}

class S7_GrenadeWeap : S7_ThrowWeapon {
    default {
        Tag "$GRENADEWEAP";
        Inventory.PickupSound "Weapons/Grenade/Pickup";

        Weapon.AmmoType 'S7_GrenadeCount';
        Weapon.AmmoUse 0;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "HGRNZ0";
        S7_BaseWeapon.ShortTag "$GRENADEWEAP";
        S7_BaseWeapon.AmmoBuyData "HGRN", 1;
        S7_BaseWeapon.BindSlot S7_WpSlot_Special;
        S7_ThrowWeapon.MaxForce 30;
        S7_ThrowWeapon.CanCancelThrow true;
        S7_BaseWeapon.EnchantmentProperties false, 0.;
    }

    bool cooking;
    int fuse;
    int fuseLength;

    override void DoEffect () {
        Super.DoEffect ();

        if (cooking && ((fuse--) <= 0 || Owner.health <= 0 || Owner.bKilled)) {
            Throw ();

            throwForce = 0;
            A_ClearRefire ();
            if (Owner.player.ReadyWeapon == self)
                Owner.player.SetPSprite (PSP_Weapon, FindState ('Ready2'), false);
        }
    }

    override void Throw () {
        if (!cooking)
            Owner.TakeInventory ('S7_GrenadeCount', 1, TIF_NoTakeInfinite);

        let grenade = S7_ThrownHandGrenade (SpawnObject ('S7_ThrownHandGrenade'));

        if (cooking) {
            grenade.fuse = fuse;
            fuse = -1;

            cooking = false;
        }
    }

    const AnimLayer_ID = 2;

    action void S7_SetAnim (StateLabel animState) {
        S7_Internal_SetAnim (AnimLayer_ID, animState, 0, 0);
    }

    /** Animations **/
    states {
    Anim.Idle:
        TNT1 A 1;
        wait;
    Anim.PullPin: // 17 tics
        HGRN WXY    1;
        HGRN ABCDEF 1;
        HGRN G      1 A_PlaySound ("Weapons/Grenade/PinPull", CHAN_Weapon);
        HGRN HIJKLM 1;
        TNT1 A      1;
        goto Anim.Idle;
    Anim.ReinsertPin:
        HGRN MLKJIH 1;
        HGRN G      1 A_PlaySound ("Weapons/Grenade/PinPull", CHAN_Weapon);
        HGRN FEDCBA 1;
        HGRN YXW    1;
        goto Anim.Idle;
    }

    /** Actions **/
    states {
    Ready:
    Ready2:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");

            int wrFlags = 0;

            if (!invoker.cooking)
                invoker.fuse = -1;
            else
                wrFlags |= WRF_DisableSwitch;

            S7_WeaponReady (null, null, wrFlags: wrFlags);
        }
        loop;

    Fire:
        TNT1 A 0 {
            if (invoker.cooking)
                return ResolveState ("Hold");

            if (!CheckInventory ('S7_GrenadeCount', 1))
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        TNT1 A 17 S7_SetAnim ("Anim.PullPin");
        goto Hold;

    AltFire:
        TNT1 A 0 {
            if (!CheckInventory ('S7_GrenadeCount', 1) || invoker.cooking)
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        TNT1 A 16 S7_SetAnim ("Anim.PullPin");
        TNT1 A  1 {
            TakeInventory ('S7_GrenadeCount', 1, TIF_NoTakeInfinite);

            invoker.cooking = true;
            invoker.fuse = S7_ThrownHandGrenade.FuseTime;
            invoker.fuseLength = invoker.fuse;
        }
        goto Ready2;

    CancelThrow:
        TNT1 A 17 {
            TakeInventory ('S7_Reloading', 0x7FFFFFFF);
            invoker.throwForce = 0;
            A_ClearRefire ();

            if (invoker.cooking)
                return ResolveState ("Ready2");

            S7_SetAnim ("Anim.ReinsertPin");

            return ResolveState (null);
        }
        goto Ready2;
    }
}

//-------------------------------------------------------------------------------------------
//
// Thrown grenade
//
//-------------------------------------------------------------------------------------------
class S7_ThrownHandGrenade : S7_ThrownObject {
    const FuseTime = int (ceil (TicRate * 3.5));

    default {
        Radius 5;
        Height 5;
        Speed 5;
        Mass 30;
        DamageFunction (0);
        PushFactor 3;
        BounceType "Hexen";
        BounceSound "Weapons/Grenade/Bounce";
        Scale 0.3;

        +CANBOUNCEWATER +USEBOUNCESTATE   +BOUNCEONACTORS +NOBLOOD
        +NOEXPLODEFLOOR +FORCEXYBILLBOARD +SKYEXPLODE
        -NOTELEPORT -NOGRAVITY -FLOORCLIP
    }

    enum GrenadeState {
        GS_Still,
        GS_Moving,
        GS_Exploded = -1,
    }

    Vector3 prevVel;
    GrenadeState grenState;
    Vector3 oldVel;
    int fuse;

    int frameNum;

    override void BeginPlay () {
        Super.BeginPlay ();

        fuse = FuseTime;
        SetState (GS_Moving);
    }

    override void PostBeginPlay () {
        super.PostBeginPlay ();

        bNoTeleport = !S7_GrenadeTeleport;

        A_ChangeVelocity (cos (pitch) * throwForce, 0, -sin (pitch) * throwForce, CVF_Relative);

        SetState (GS_Moving);
    }

    override bool CanCollideWith (Actor other, bool passive) {
        if (other is 'S7_ThrownHandGrenade')
            return false;

        return Super.CanCollideWith (other, passive);
    }

    override void Tick () {
        prevVel = vel;
        Super.Tick ();
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
                bNoGravity = true;
            case GS_Moving:
                bSolid = false;
                bPushable = false;
                bMissile = true;

                A_ChangeLinkFlags (true);
            break;
        }
    }

    const FrameTime = 2;
    static const string GrenSprites [] = {
        "TGRPA", "TGRPB", "TGRPC", "TGRPD", "TGRPE", "TGRPF", "TGRPG", "TGRPH"
    };

    action void S7_HandleBounce (Vector3 prevVel, Vector3 surfaceNormal) {
        if (surfaceNormal dot prevVel.Unit () > 0)
            surfaceNormal = -surfaceNormal;

        vel = (prevVel - 2 * surfaceNormal * (prevVel dot surfaceNormal)) * .5;
    }

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
            frame = curFrame.ByteAt (4) - 65; // 65 == 'A'

            fuse--;

            if (grenState == GS_Moving)
                frameNum = (frameNum + 1) % (GrenSprites.Size () * FrameTime);

            return ResolveState (null);
        }
        goto Spawn;

    Bounce.Ceiling:
        #### # 0 {
            if (!BlockingCeiling)
                return;

            S7_HandleBounce (prevVel, BlockingCeiling.ceilingPlane.Normal.Unit ());
            bHitOwner = true;
        }
        goto Flight;
    Bounce.Wall:
        #### # 0 {
            if (!BlockingLine)
                return;

            let wallNormal = (AngleToVector (VectorAngle (BlockingLine.delta.X, BlockingLine.delta.Y) - 90., 1.), 0).Unit ();
            S7_HandleBounce (prevVel, wallNormal);
            bHitOwner = true;
        }
        goto Flight;
    Bounce.Floor:
        #### # 0 {
            vel.Z = 0;
            bHitOwner = true;
        }
        goto Flight;
    Bounce.Actor:
        #### # 0 {
            vel *= .035;
            vel.Z = -abs (vel.Z);
            bHitOwner = true;
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
        TNT1 A 3 {
            SetState (GS_Exploded);

            A_Stop ();

            A_QuakeEx (3, 3, 3, 17, 0, 224 * 2, "", falloff: 1, rollIntensity: 2.);

            S7_ExplosionSound.CreateExplosion2 (pos);
            let expl = Spawn ('S7_GenericExplosion', pos);
            if (expl) {
                expl.target = self;
                expl.scale = (1., 1.);
            }

            S7_ActorExtensions.A_S7SpawnShrapnel (
                self, 100,
                minVel: 250, maxVel: 500,
                minMass: 10, maxMass: 25,
                keScale: 150,
                zOff: 2.0, flags: SXF_TransferPointers
            );
            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (224, 256);
        }
        stop;
    }
}