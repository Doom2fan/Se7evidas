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

extend class S7_BaseWeapon {
    //-------------------------------------------------------------------------------------------
    //
    // S7_Recoil
    //
    //-------------------------------------------------------------------------------------------
    double ConvWeapRecoil (double amount, double strengthStat, double berserkMod) const {
        return amount * (1 - clamp ((log10 (strengthStat) / 5.) + (.000035 * (strengthStat**2)), 0., .75)) * (1. - berserkMod);
    }

    virtual void V_S7_Recoil (double amount) {
        if (S7_Debug_NoRecoil)
            return;

        let xpSys = GetOwnerXPSystem ();
        double strengthStat = (xpSys ? xpSys.GetStat (S7Stat_Strength) / 3. : 0);

        double berserkMod = clamp (Owner.CountInv ("S7_BerserkToken") * .15, 0., 1.);

        let pPawn = S7_BasePlayer (Owner);
        if (pPawn && pPawn.playerData && !Owner.CheckInventory ("S7_BerserkToken", 1))
            berserkMod = clamp (-(.2 * pPawn.playerData.bsrkAddiction), -1., 0.);

        amount = ConvWeapRecoil (amount, strengthStat, berserkMod);

        Owner.A_SetPitch (Owner.pitch + amount, SPF_Interpolate);
    }

    action void S7_Recoil (double amount) {
        invoker.V_S7_Recoil (amount);
    }

    //-------------------------------------------------------------------------------------------
    //
    // S7_GetMeleeDamage
    //
    //-------------------------------------------------------------------------------------------
    action int S7_GetMeleeDamage (double baseDamage) {
        double dmgMul = 1.0;

        let pPawn = S7_BasePlayer (invoker.Owner);
        if (pPawn && pPawn.xpSys)
            dmgMul += pPawn.xpSys.GetStat (S7Stat_Strength, false) * .025;

        if (CheckInventory ('S7_BerserkToken', 1))
            dmgMul *= 3.0;

        return int (ceil (baseDamage * dmgMul + .5));
    }

    //-------------------------------------------------------------------------------------------
    //
    // S7_CustomPunch
    //
    //-------------------------------------------------------------------------------------------
    action Actor S7_CustomPunch (
        int damage, int flags = CPF_UseAmmo, Class<Actor> puffType = "BulletPuff", double range = 0,
        name damageType = 'Melee', double lifesteal = 0, int lifestealmax = 0,
        Class<BasicArmorBonus> armorBonusType = "ArmorBonus", sound MeleeSound = 0, sound MissSound = ""
    ) {
        if (!player)
            return null;

        let weapon = player.ReadyWeapon;
        double angle, pitch;
        FTranslatedLineTarget t;
        int actualdamage;

        if (range == 0)
            range = DefMeleeRange;

        angle = self.Angle + random2 [cwpunch] () * (5.625 / 256);
        pitch = AimLineAttack (angle, range, t, 0., ALF_Check3D);

        // Only use ammo when actually hitting something!
        if ((flags & CPF_UseAmmo) && t.linetarget && weapon && stateinfo != null && stateinfo.mStateType == STATE_PSprite) {
            if (!weapon.DepleteAmmo (weapon.bAltFire, true))
                return null; // Out of ammo
        }

        if (puffType == null)
            puffType = 'BulletPuff';
        int puffFlags = LAF_IsMeleeAttack | ((flags & CPF_NoRandomPuffZ) ? LAF_NoRandomPuffZ : 0);

        Actor puff;
        [puff, actualdamage] = LineAttack (angle, range, pitch, damage, damageType, puffType, puffFlags, t);

        if (!t.linetarget) {
            if (MissSound)
                A_PlaySound (MissSound, CHAN_Weapon);
        } else {
            if (lifesteal > 0 && !(t.linetarget.bDontDrain)) {
                if (flags & CPF_StealArmor) {
                    if (armorBonusType == null)
                        armorBonusType = 'ArmorBonus';

                    if (armorBonusType != null) {
                        let armorbonus = ArmorBonus (Spawn (armorBonusType));
                        armorbonus.SaveAmount *= int (actualdamage * lifesteal);
                        if (lifestealmax > 0) armorbonus.MaxSaveAmount = lifestealmax;
                        armorbonus.bDropped = true;
                        armorbonus.ClearCounters ();

                        if (!armorbonus.CallTryPickup (self))
                            armorbonus.Destroy ();
                    }
                } else
                    GiveBody (int (actualdamage * lifesteal), lifestealmax);
            }
            if (weapon != null) {
                if (MeleeSound) A_PlaySound ( MeleeSound, CHAN_Weapon);
                else            A_PlaySound (AttackSound, CHAN_Weapon);
            }

            // Turn to face target
            if (!(flags & CPF_NoTurn))
                self.Angle = t.angleFromSource;

            if (flags & CPF_PullIn)
                self.bJustAttacked = true;
            if (flags & CPF_Dagger)
                t.linetarget.DaggerAlert (self);
        }

        return puff;
    }


    //-------------------------------------------------------------------------------------------
    //
    // S7_A_FireBullets & S7_A_SpawnSFX
    //
    //-------------------------------------------------------------------------------------------
    // Note: DO NOT USE THIS FUNCTION FOR ANYTHING THAT AFFECTS THE PLAYSIM, OR IT CAN AND *WILL* CAUSE DESYNCS.
    action Actor, S7_TZK_ArrayObj S7_A_SpawnSFX (Class<Actor> sfxType, Vector3 offs = (0, 0, 0), double angleOffs = 0, double pitchOffs = 0, int amount = 1, int flags = 0) {
        flags |= S7_FB_NoRandomSpread;
        return S7_A_FireBullets (sfxType, offs: offs, angleOffs: angleOffs, pitchOffs: pitchOffs, amount: amount, flags: flags | S7_FB_SpeedOffs);
    }

    action Actor, S7_TZK_ArrayObj S7_A_FireBullets (
        Class<Actor> projType,
        Vector2 spread = (0, 0), Vector3 offs = (0, 0, 0),
        double angleOffs = 0, double pitchOffs = 0,
        int amount = 1,
        double bonusDMGFactor = 0.,
        int flags = 0
    ) {
        if (!projType)
            ThrowAbortException ("S7_A_FireBullets: Projectile class \"%s\" does not exist.", projType);
        if (amount < 1)
            ThrowAbortException ("S7_A_FireBullets: Amount must be greater than 0.");

        if (flags & S7_FB_UseAmmo) {
            let weapon = player.ReadyWeapon;

            // Only use ammo if called from a weapon
            if (weapon && stateinfo != null && stateinfo.mStateType == STATE_Psprite) {
                if (!weapon.DepleteAmmo (weapon.bAltFire, true))
                    return null, null; // Out of ammo
            }
        }

        Vector3 origin; {
            let qRot = S7_GM_Quaternion.CreateFromAngles (angle, pitch, roll);
            origin = level.Vec3Offset (Vec2OffsetZ (0, 0, player.viewZ),
                qRot.RotateVector3 ((offs.X, -offs.Y, -offs.Z))
            );
        }

        let arr = new ('S7_TZK_ArrayObj');
        arr.Clear ();

        let projBaseRot = S7_GM_Quaternion.CreateFromAngles (angleOffs, pitchOffs, 0);
        if ((flags & (S7_FB_AbsoluteAngle | S7_FB_AbsolutePitch)) != (S7_FB_AbsoluteAngle | S7_FB_AbsolutePitch)) {
            let shooterAngles = S7_GM_Quaternion.CreateFromAngles (
                !(flags & S7_FB_AbsoluteAngle) ? angle : 0,
                !(flags & S7_FB_AbsolutePitch) ? pitch : 0,
                roll
            );
            projBaseRot = shooterAngles.MultiplyQuat (projBaseRot);
        }

        for (int i = 0; i < amount; i++) {
            let proj = Spawn (projType, origin, ALLOW_REPLACE);
            proj.target = self;

            if (!(flags & S7_FB_NoRandomSpread)) {
                spread.X = fRandom [weaponSpread] (-spread.X, spread.X);
                spread.Y = fRandom [weaponSpread] (-spread.Y, spread.Y);
            }

            let projRot = S7_GM_Quaternion.CreateFromAngles (spread.X, spread.Y, 0);
            projRot = projBaseRot.MultiplyQuat (projRot);

            Vector3 forwards = S7_Math.GetAxesFromQuat (projRot);

            proj.vel += (forwards.Unit () * proj.Speed);
            [proj.angle, proj.pitch, proj.roll] = projRot.ToAngles ();

            if (flags & S7_FB_PhysRelVelocity)
                proj.vel = vel + proj.vel;

            if ((projType is 'S7_Projectile'))
                S7_Projectile (proj).bonusDMGFactor = bonusDMGFactor;

            if ((flags & S7_FB_SpeedOffs) && radius > 0) {
                // Move a little forward so an angle can be computed if it immediately explodes
                Vector3 newPos = (0, 0, 0);

                Vector3 advance = proj.vel;
                double maxsquared = radius * radius;

                // Keep halving the advance vector until we get something less than maxdist
                // units away, since we still want to spawn the missile inside the shooter.
                do {
                    advance *= .5;
                } while ((advance.XY dot advance.XY) >= maxsquared);
                newpos += advance;

                newPos = level.Vec3Offset (proj.pos, newPos);
                proj.SetOrigin (newPos, false);
            }

            arr.Values.Push (proj);
        }

        return Actor (arr.Values [0]), arr;
    }

    //-------------------------------------------------------------------------------------------
    //
    // S7_A_SpawnCasing
    //
    //-------------------------------------------------------------------------------------------
    action void S7_A_SpawnCasing (Class<S7_CasingBase> casingType, Vector3 offs, double angleOffs = 0, double pitchOffs = 0, Vector2 spread = (10, -35), double horzMul = 1., double vertMul = 1.) {
        let shooterAngles = S7_GM_Quaternion.CreateFromAngles (angle, pitch, roll);

        Vector3 origin = level.Vec3Offset (
            Vec2OffsetZ (0, 0, player.viewZ),
            shooterAngles.RotateVector3 ((offs.X, -offs.Y, -offs.Z))
        );

        let casing = Spawn (casingType, origin, ALLOW_REPLACE);
        casing.target = self;

        Vector3 forwards, sideways, vertical; {
            let projRot = S7_GM_Quaternion.CreateFromAngles (angleOffs, 0, 0);

            projRot = shooterAngles.MultiplyQuat (projRot);
            projRot = shooterAngles.MultiplyQuat (S7_GM_Quaternion.CreateFromAngles (fRandom [casingStuff] (-spread.X, spread.X), 0, 0));

            [forwards, sideways, vertical] = S7_Math.GetAxesFromQuat (projRot);
        }

        double casingPitch = pitchOffs + fRandom [casingStuff] (-spread.Y, spread.Y);
        casing.vel = (
            (-sideways.Unit () * horzMul * casing.Speed) +
            (sin (-casingPitch) * vertical.Unit () * vertMul * casing.Speed)
        );

        let dir = casing.vel.Unit ();
        casing.angle = atan2 (dir.Y, dir.X);
        casing.pitch = -asin (dir.Z);

        if (casing.pos.Z >= casing.ceilingZ) {
            let newPos = level.Vec3Offset ((casing.pos.XY, casing.ceilingZ), (0, 0, -casing.height));
            casing.SetOrigin (newPos, false);
        }
    }
}