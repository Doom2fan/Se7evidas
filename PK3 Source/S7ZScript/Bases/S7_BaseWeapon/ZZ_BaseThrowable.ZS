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
// Base throwable
//
//-------------------------------------------------------------------------------------------
class S7_ThrowWeapon : S7_BaseWeapon {
    int throwForce;
    int maxForce;
    bool canCancelThrow;

    property MaxForce: maxForce;
    property CanCancelThrow: canCancelThrow;

    default {
        S7_ThrowWeapon.MaxForce 30;
    }

    virtual S7_ThrownObject SpawnObject (Class<S7_ThrownObject> thrownAct) {
        double pAngle = Owner.angle;
        double pPitch = Owner.pitch;
        Vector3 pVel = Owner.vel;

        bool MUDA; Actor act;
        [MUDA, act] = Owner.A_SpawnItemEx (thrownAct,
            zofs: Owner.height - 12,
            xvel: cos (pPitch) * cos (pAngle) * 4 + pVel.X,
            yvel: cos (pPitch) * sin (pAngle) * 4 + pVel.Y,
            zvel: -sin (pPitch) * 4 + pVel.Z,
            flags: SXF_AbsoluteMomentum | SXF_NoCheckPosition | SXF_TransferPitch
        );

        let ret = S7_ThrownObject (act);
        ret.throwForce = throwForce;

        return ret;
    }

    virtual void Throw () { }

    states {
    Hold:
        TNT1 A 1 {
            if (invoker.canCancelThrow && CheckInventory ('S7_Reloading', 1))
                return ResolveState ("CancelThrow");
            else
                TakeInventory ('S7_Reloading', 0x7FFFFFFF);

            invoker.throwForce = clamp (invoker.throwForce + 1, 0, invoker.maxForce);
            return ResolveState (null);
        }
        TNT1 A 1 A_Refire ("Hold");
        TNT1 A 8 {
            A_ClearRefire ();
            invoker.Throw ();
            invoker.throwForce = 0;

            return ResolveState ("Ready2");
        }
    }
}

class S7_ThrownObject : S7_Projectile {
    int throwForce;
}