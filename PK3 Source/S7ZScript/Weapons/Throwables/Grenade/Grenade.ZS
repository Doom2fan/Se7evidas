/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) ???? MatthewTheGlutton
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

//-------------------------------------------------------------------------------------------
//
// Grenade
//
//-------------------------------------------------------------------------------------------
class S7_GrenadeCount : Ammo {
    default {
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
        TGRN Z -1;
        stop;
    }
}
class S7_GrenadeBox : S7_GrenadeCount {
    default {
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

        S7_BaseWeapon.Icon "TGRNZ0";
        S7_BaseWeapon.ShortTag "$GRENADEWEAP";
        S7_BaseWeapon.AmmoBuyData "HGRN", 1;
        S7_BaseWeapon.BindSlot WpSlot_Special;
        S7_ThrowWeapon.MaxForce 30;
        S7_ThrowWeapon.CanCancelThrow true;
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

    states {
    Ready:
    Ready2:
        TNT1 A 1 {
            if (!invoker.cooking)
                invoker.fuse = -1;

            S7_WeaponReady (null, null);
        }
        loop;

    Fire:
        TNT1 A      0 {
            if (invoker.cooking)
                return ResolveState ("Hold");

            if (!CheckInventory ('S7_GrenadeCount', 1))
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        TGRN WXY    1;
        TGRN ABCDEF 1;
        TGRN G      1 A_PlaySound ("Weapons/Grenade/PinPull", CHAN_Weapon);
        TGRN HIJKLM 1;
        TNT1 A      1;
        goto Hold;

    AltFire:
        TNT1 A      0 {
            if (!CheckInventory ('S7_GrenadeCount', 1) || invoker.cooking)
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        TGRN WXY    1;
        TGRN ABCDEF 1;
        TGRN G      1 A_PlaySound ("Weapons/Grenade/PinPull", CHAN_Weapon);
        TGRN HIJKLM 1;
        TNT1 A      1 {
            TakeInventory ('S7_GrenadeCount', 1, TIF_NoTakeInfinite);

            invoker.cooking = true;
            invoker.fuse = S7_ThrownHandGrenade.FuseTime;
            invoker.fuseLength = invoker.fuse;
        }
        goto Ready2;

    CancelThrow:
        TNT1 A      1 {
            TakeInventory ('S7_Reloading', 0x7FFFFFFF);
            invoker.throwForce = 0;
            A_ClearRefire ();

            if (invoker.cooking)
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        TGRN MLKJIH 1;
        TGRN G      1 A_PlaySound ("Weapons/Grenade/PinPull", CHAN_Weapon);
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
    const FuseTime = int (ceil (35 * 3.5));

    default {
        Radius 5;
        Height 5;
        Speed 5;
        Mass 30;
        DamageFunction (0);
        PushFactor 3;
        BounceType "Hexen";
        BounceSound "Weapons/Grenade/Bounce";
        /*WallBounceFactor 0.25;
        BounceFactor 0.1;*/
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

    GrenadeState grenState;
    Vector3 oldVel;
    int fuse;

    int frameNum;

    override void BeginPlay () {
        Super.BeginPlay ();

        fuse = FuseTime;
    }

    override void PostBeginPlay () {
        super.PostBeginPlay ();

        bNoTeleport = !S7_GrenadeTeleport;

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
        XPL1 BCDE 3 bright;
        stop;
    }
}