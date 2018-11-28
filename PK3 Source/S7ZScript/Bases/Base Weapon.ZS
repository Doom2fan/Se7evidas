/*
 *  Se7evidas - A GZDoom mod
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
// Melee type tokens
//
//-------------------------------------------------------------------------------------------
/* Credits:
** Sprites: Apocalyptic Studio, Captain J, Chronos "phantombeta" Ouroboros
** Animation: Chronos "phantombeta" Ouroboros
** Sounds: Credits in the SNDINFO file
*/
class S7_DaggerMelee : S7_Boolean { }

/* Credits:
** Sprites: Id Software, ???, Chronos "phantombeta" Ouroboros
** Animation: Chronos "phantombeta" Ouroboros
** Sounds: Credits in the SNDINFO file
*/
class S7_PunchMelee : S7_Boolean { }

/* Credits:
** Sprites: ???, Chronos "phantombeta" Ouroboros
** Animation: Chronos "phantombeta" Ouroboros
** Sounds: Credits in the SNDINFO file
*/
class S7_KickMelee : S7_Boolean { }

//-------------------------------------------------------------------------------------------
//
// Base weapon
//
//-------------------------------------------------------------------------------------------
class S7_BaseWeapon : Weapon {
    enum S7_WeaponReadyFlags {
        S7WRF_ChangeModeWhileSprinting = 1 << 0,
        S7WRF_MeleeWhileSprinting      = 1 << 1,
    };

    String weapIcon;
    String shortTag;
    S7_WeaponSlots bindSlot;
    bool usesMag;
    bool reloadWhileSprinting;

    property Icon: weapIcon;
    property ShortTag: shortTag;
    property BindSlot: bindSlot;
    property UsesMag: usesMag;
    property CanReloadWhileSprinting: reloadWhileSprinting;

    default {
        Inventory.PickupSound "misc/gunpickup";
        Weapon.BobRangeX 0.3;
        Weapon.BobRangeY 0.5;
        Weapon.BobSpeed 2.0;
        Weapon.BobStyle "inverseSmooth";
        Weapon.Kickback 100;

        S7_BaseWeapon.Icon "";
        S7_BaseWeapon.BindSlot -1;
        S7_BaseWeapon.UsesMag false;
        S7_BaseWeapon.CanReloadWhileSprinting false;

        +WEAPON.AMMO_OPTIONAL +WEAPON.NOAUTOFIRE +WEAPON.NOALERT +INVENTORY.RESTRICTABSOLUTELY
        +INVENTORY.TRANSFER
    }

    int fireModeIcon; // 0: none, 1: semi-auto, 2: burst-fire, 3: full-auto.

    override void AttachToOwner (Actor other) { // Override this so we can disable selection on pickup
        StateProvider.AttachToOwner (other);

        Ammo1 = AddAmmo (Owner, AmmoType1, AmmoGive1);
        Ammo2 = AddAmmo (Owner, AmmoType2, AmmoGive2);
        SisterWeapon = AddWeapon (SisterWeaponType);
        if (Owner.player != NULL) {
            if (Owner.player.mo == players [consoleplayer].camera)
                StatusBar.ReceivedWeapon (self);
        }
        GivenAsMorphWeapon = false; // will be set explicitly by morphing code
    }

    override void DetachFromOwner () {
        let weapBinds = S7_WeapBindsSystem (Owner.FindInventory ('S7_WeapBindsSystem'));
        if (!weapBinds)
            return;

        int slot, pos;

        [slot, pos] = weapBinds.LocateWeapon (self, false);
        if (slot > -1 && pos > -1)
            weapBinds.SetBind (slot, pos, NULL, false);

        [slot, pos] = weapBinds.LocateWeapon (self, true);
        if (slot > -1 && pos > -1)
            weapBinds.SetBind (slot, pos, NULL, true);
    }

    override bool Use (bool pickup) { // Override Use so it can't be used to bypass the weapon limits
        return false;
    }

    override Inventory CreateTossable (int amt) {
        // If self actor lacks a SpawnState, don't drop it. (e.g. A base weapon
        // like the fist can't be dropped because you'll never see it.)
        if (SpawnState == GetDefaultByType ('Actor').SpawnState || SpawnState == NULL)
            return NULL;
        if (bUndroppable || bUntossable || Owner == NULL || Amount <= 0)
            return NULL;

        // Will pretty much always be true, but ehhh...
        if (Owner && Owner.player && Owner.player.ReadyWeapon == self) {
            int weapState = Owner.player.WeaponState;

            if (!(weapState & WF_WeaponSwitchOK))
                return NULL;
            if (weapState & WF_DisableSwitch)
                return NULL;
        }

        amt = 1; // Never drop more than one instance of a weapon

        if (Amount == 1 && !bKeepDepleted) {
            let ammo1Act = Ammo1;

            BecomePickup ();
            DropTime = 30;
            bSpecial = bSolid = false;

            if (usesMag) {
                ammo1Act.BecomePickup ();
                self.AddInventory (ammo1Act);
            }

            return self;
        }

        let copy = Inventory (Spawn (GetClass (), Owner.Pos, NO_REPLACE));
        if (copy != NULL) {
            copy.MaxAmount = MaxAmount;
            copy.Amount = amt;
            copy.DropTime = 30;
            copy.bSpecial = copy.bSolid = false;
            Amount -= amt;
        }

        return copy;
    }

    Inventory DropAmmo (class<Inventory> itemClass, Actor act, int amt, Vector3 offs = (0, 0, 0), double angleOffs = 0) {
        let drop = Inventory (Spawn (itemClass, act.Vec3Offset (0 + offs.X, 0 + offs.Y, 10. + offs.Z)));

        if (drop) {
            drop.amount = amt;

            drop.angle = act.angle + angleOffs;
            drop.VelFromAngle (5.);
            drop.vel.Z = 1.;
            drop.vel += act.vel;
        }

        return drop;
    }

    action int S7_GetMeleeDamage (double baseDamage, double mul) {
        double baseMul  = 1.0;
        double mulBonus = 0.0;

        let pPawn = S7_BasePlayer (invoker.Owner);
        if (pPawn && pPawn.xpSys)
            baseMul += pPawn.xpSys.GetStat (S7Stat_Strength, false) * 0.025;

        if (CheckInventory ('S7_BerserkToken', 1)) {
            baseMul *= 3.0;
            mulBonus = fRandom [weaponDamage] (0.0, 2.0);
        }

        return int (ceil ((baseDamage * baseMul + 0.5) * (mul + mulBonus)));
    }

    double ConvWeapRecoil (double amount, double strengthStat) const {
        return amount * (1 - clamp ((log10 (strengthStat) / 5) + (.000035 * (strengthStat**2)), 0., .75));
    }

    bool CanReload () {
        let pPawn = S7_BasePlayer (Owner);
        bool sprinting = pPawn ? pPawn.sprint_Sprinting : false;

        return (!sprinting || reloadWhileSprinting);
    }

    action int InterpolateWeaponSwitch () {
        CVar iws = CVar.GetCVar ("S7_InterpolateWeaponSwitch", player);

        return ((iws && iws.GetInt ()) ? WOF_Interpolate : 0);
    }

    virtual Vector2 DoSelectOffset_InitialOffset () {
        return (0, 0);
    }

    action void DoSelectOffset (Vector2 offs, int overlay = int.min, bool forceNoInterpolate = false) {
        let initOffs = invoker.DoSelectOffset_InitialOffset ();

        CVar iws = CVar.GetCVar ("S7_InterpolateWeaponSwitch", player);
        int doInterpolate = ((!forceNoInterpolate && iws && iws.GetInt ()) ? WOF_Interpolate : 0);

        offs = (initOffs.X + offs.X, 32 + initOffs.Y + offs.Y);

        if (overlay == int.min)
            A_WeaponOffset (offs.X, offs.Y, doInterpolate);
        else
            A_OverlayOffset (overlay, offs.X, offs.Y, doInterpolate);
    }

    S7_XPSystem GetOwnerXPSystem () {
        if (!Owner || !(Owner is 'S7_BasePlayer'))
            return null;

        let xpSystem = S7_XPSystem (Owner.FindInventory ('S7_XPSystem', true));

        if (!xpSystem)
            return null;

        return xpSystem;
    }

    /* Summary:
    **  Called before an item is sold. Return value indicates whether to continue the transaction.
    **
    ** Returns:
    **  Returns a bool indicating whether or not to continue selling the weapon.
    */
    virtual bool SS_PreSell (int amount) {
        if (usesMag && Ammo1 && Ammo2) {
            int count = Ammo1.Amount;
            int excess = max ((Ammo2.Amount + count) - Ammo2.MaxAmount, 0);

            if ((count - excess) > 0)
                Owner.GiveInventory (Ammo2.GetClass (), count - excess);

            if (excess > 0) {
                let drop = Ammo (Spawn (Ammo2.GetClass (), Owner.Vec3Offset (0, 0, 10.)));

                if (drop) {
                    drop.amount = excess;

                    drop.angle = Owner.angle;
                    drop.VelFromAngle (5.);
                    drop.vel.Z = 1.;
                    drop.vel += Owner.vel;
                }
            }

            Owner.TakeInventory (Ammo1.GetClass (), count);
        }

        return true;
    }

    /* Summary:
    **  Called after the weapon has been successfully sold.
    */
    virtual void SS_OnSell (int amount) { }

    virtual void V_S7_Recoil (double amount) {
        if (S7_Debug_NoRecoil)
            return;

        let xpSys = GetOwnerXPSystem ();

        if (xpSys)
            amount = ConvWeapRecoil (amount, xpSys.GetStat (S7Stat_Strength / 3));

        Owner.A_SetPitch (Owner.pitch + amount, SPF_Interpolate);
    }

    action void S7_Recoil (double amount) {
        invoker.V_S7_Recoil (amount);
    }

    action void S7_WeaponReady (StateLabel reloadState, StateLabel fireModeState, StateLabel quickMeleeState = "QuickMelee", int flags = 0, int wrFlags = 0) {
        let pPawn = S7_BasePlayer (self);
        bool sprinting = pPawn ? pPawn.sprint_Sprinting : false;

        if (reloadState && CheckInventory ('S7_Reloading', 1) && invoker.CanReload ())
            player.SetPSprite (PSP_Weapon, ResolveState (reloadState));
        else
            TakeInventory ('S7_Reloading', 0x7FFFFFFF);

        if (fireModeState && CheckInventory ('S7_ChangeFireMode', 1) && (!sprinting || (flags & S7WRF_ChangeModeWhileSprinting)))
            player.SetPSprite (PSP_Weapon, ResolveState (fireModeState));
        else
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

        if (quickMeleeState && CheckInventory ('S7_DoMelee', 1) && (!sprinting || (flags & S7WRF_MeleeWhileSprinting)))
            player.SetPSprite (PSP_Weapon, ResolveState (quickMeleeState));
        else
            TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

        A_WeaponReady (wrFlags);
    }

    states {
    DryFire:
        TNT1 A 0 {
            A_PlaySound ("Weapons/DryFire", CHAN_Weapon);

            if (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload ())
                return ResolveState ("Reload");

            return ResolveState (null);
        }
        TNT1 A 0 A_Jump (256, "Ready2");
        wait;

    Ready:
        TNT1 A 0 A_Jump (256, "Ready2");
        wait;
    Fire:
        TNT1 A 1;
        goto Ready;

    Select:
    TrueSelect:
        TNT1 A 0 A_Raise ();
        loop;
    Deselect:
    TrueDeselect:
        TNT1 A 0 {
            TakeInventory ('S7_HoldingZoom', 0x7FFFFFFF);
            TakeInventory ('S7_Weap_ReadyFrame', 0x7FFFFFFF);
            A_ZoomFactor (1.0);
            A_WeaponOffset (0, 32);

            if (!health)
                return ResolveState ("Deselect.DEAD");

            return ResolveState (null);
        }
        TNT1 A 0 A_Lower ();
        wait;
    Deselect.DEAD:
        TNT1 A 1 A_Lower;
        wait;

    QuickMelee:
        TNT1 A 0 {
            TakeInventory ('S7_DoMelee', 0x7FFFFFFF);
            if (CheckInventory ('S7_DaggerMelee', 1))
                return ResolveState ("DaggerMelee");
            if (CheckInventory ('S7_PunchMelee', 1))
                return ResolveState ("PunchMelee");
            if (CheckInventory ('S7_KickMelee', 1))
                return ResolveState ("KickMelee");

            return ResolveState ("KickMelee");
        }

    DaggerMelee:
        TNT1 A 0 A_Jump (256, "DaggerMelee1", "DaggerMelee2");
        wait;
    DaggerMelee1:
        DAG1 ABCD 1;
        DAG1 E    1 A_CustomPunch (S7_GetMeleeDamage (3, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, 'S7_DaggerPuff');
        DAG1 F    1 A_CustomPunch (S7_GetMeleeDamage (3, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, 'S7_DaggerPuffSilent');
        DAG1 G    1 A_CustomPunch (S7_GetMeleeDamage (3, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, 'S7_DaggerPuffSilent');
        DAG1 H    1;
        TNT1 A    5;
        TNT1 A    0 A_Jump (256, "MeleeDone");
        wait;
    DaggerMelee2:
        DAG2 AB  1;
        DAG2 C   1 A_CustomPunch (S7_GetMeleeDamage (2, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, 'S7_DaggerPuff');
        DAG2 D   1 A_CustomPunch (S7_GetMeleeDamage (2, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, 'S7_DaggerPuffSilent');
        DAG2 EF  1 A_CustomPunch (S7_GetMeleeDamage (2, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, 'S7_DaggerPuffSilent');
        DAG2 GH  1;
        TNT1 A   5;
        TNT1 A   0 A_Jump (256, "MeleeDone");
        wait;

    PunchMelee:
        TNT1 A 0 A_Jump (256, "MeleeDone");
        wait;

    KickMelee:
        KICK BCD   1;
        KICK H     1 A_CustomPunch (S7_GetMeleeDamage (13, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, 'S7_MeleePuff');
        KICK HHHIG 1;
        KICK FEDCB 1;
        KICK A     1;

        TNT1 A 0 A_Jump (256, "MeleeDone");
        wait;

    MeleeDone:
        TNT1 A 0 A_JumpIfInventory ('S7_DoMelee', 1, "QuickMelee");
        TNT1 A 0 A_Jump (256, "Ready");
        wait;
    }
}

//-------------------------------------------------------------------------------------------
//
// Base Draco weapon
//
//-------------------------------------------------------------------------------------------
class S7_DracoWeapon : S7_BaseWeapon {
    // Currently has no actual differences...
    // Maybe make the bobbing different or something
}

//-------------------------------------------------------------------------------------------
//
// Base throwable
//
//-------------------------------------------------------------------------------------------
class S7_ThrowWeapon : S7_BaseWeapon {
    int throwForce;
    int maxForce;
    int canCancelThrow;

    property MaxForce: maxForce;
    property CanCancelThrow: canCancelThrow;

    default {
        S7_ThrowWeapon.MaxForce 30;
    }

    virtual S7_ThrownObject SpawnObject (class<S7_ThrownObject> thrownAct) {
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

//-------------------------------------------------------------------------------------------
//
// Melee puffs
//
//-------------------------------------------------------------------------------------------
class S7_MeleePuff : S7_EffectsBase {
    default {
        DamageType 'Kick';
        AttackSound "Weapons/Kick/HitWall";
        ActiveSound "Weapons/Kick/Swing";

        +NOBLOCKMAP +NOGRAVITY +PUFFONACTORS +NOEXTREMEDEATH
    }

    states {
    Spawn:
        TNT1 A 1;
        stop;
    }
}

class S7_MeleePuffStrong : S7_MeleePuff {
    default {
        Decal 'FistScorch';
        AttackSound "Weapons/Kick/Strong";
        ActiveSound "Weapons/Kick/Swing";

        +EXTREMEDEATH
        -NOEXTREMEDEATH
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnItem ('S7_ShotSmoke');
        stop;
    }
}

class S7_DaggerPuff : S7_MeleePuff {
    default {
        DamageType 'Blade';
        ActiveSound "Weapons/Tridagger/Swing";
        AttackSound "Weapons/Tridagger/HitWall";
        SeeSound "Weapons/Tridagger/HitFlesh";
    }
}
class S7_DaggerPuffSilent : S7_DaggerPuff {
    default {
        ActiveSound "";
        AttackSound "";
        SeeSound "";
    }
}

//-------------------------------------------------------------------------------------------
//
// Misc crap
//
//-------------------------------------------------------------------------------------------
class S7_Unarmed : S7_BaseWeapon { default { Tag "$UNARMED"; } }