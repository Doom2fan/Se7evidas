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
** Sprites: Captain J, Chronos "phantombeta" Ouroboros
** Animation: Chronos "phantombeta" Ouroboros
** Sounds: Credits in the SNDINFO file
*/
class S7_MacheteMelee : S7_Boolean { }

/* Credits:
** Sprites: ???, Chronos "phantombeta" Ouroboros
** Animation: Chronos "phantombeta" Ouroboros
** Sounds: Credits in the SNDINFO file
*/
//class S7_KickMelee : S7_Boolean { }

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
    String ammoBuyShopItem;
    int ammoBuyAmount;
    S7_WeaponSlots bindSlot;
    bool usesMag;
    bool reloadWhileSprinting;

    property Icon: weapIcon;
    property ShortTag: shortTag;
    property AmmoBuyData: ammoBuyShopItem, ammoBuyAmount;
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
        S7_BaseWeapon.AmmoBuyData "", 1;
        S7_BaseWeapon.BindSlot -1;
        S7_BaseWeapon.UsesMag false;
        S7_BaseWeapon.CanReloadWhileSprinting false;

        +WEAPON.AMMO_OPTIONAL +WEAPON.NOAUTOFIRE +WEAPON.NOALERT +INVENTORY.RESTRICTABSOLUTELY
        +INVENTORY.TRANSFER
    }

    int fireModeIcon; // 0: none, 1: semi-auto, 2: burst-fire, 3: full-auto.
    double enchantment_DamageBonus;

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
        if (!(Owner is 'S7_BasePlayer'))
            return false;

        let pPawn = S7_BasePlayer (Owner);
        if (!pPawn)
            return false;

        if (!pPawn.selectedWeapon)
            return false;

        bool ret = Super.Use (pickup);
        pPawn.selectedWeapon = false;
        return ret;
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

    action int S7_GetMeleeDamage (double baseDamage) {
        double dmgMul = 1.0;

        let pPawn = S7_BasePlayer (invoker.Owner);
        if (pPawn && pPawn.xpSys)
            dmgMul += pPawn.xpSys.GetStat (S7Stat_Strength, false) * .025;

        if (CheckInventory ('S7_BerserkToken', 1))
            dmgMul *= 3.0;

        return int (ceil (baseDamage * dmgMul + .5));
    }

    double ConvWeapRecoil (double amount, double strengthStat, double berserkMod) const {
        return amount * (1 - clamp ((log10 (strengthStat) / 5.) + (.000035 * (strengthStat**2)), 0., .75)) * (1. - berserkMod);
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

    virtual double S7_WeightSpeedModifier (double strengthStat, double berserkCount) {
        return 1.;
    }

    override double GetSpeedFactor () {
        if (!Owner || Owner.player.ReadyWeapon != self)
            return 1.;

        let xpSys = GetOwnerXPSystem ();

        double strengthStat = (xpSys ? xpSys.GetStat (S7Stat_Strength) : 0.);
        double berserkCount = Owner.CountInv ("S7_BerserkToken");

        if (berserkCount < 1) {
            let pPawn = S7_BasePlayer (Owner);
            if (pPawn && pPawn.playerData)
                berserkCount = clamp (-(.2 * pPawn.playerData.bsrkAddiction), -1., 0.);
        }

        return S7_WeightSpeedModifier (strengthStat, berserkCount);
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

    action Actor S7_CustomPunch (
        int damage, int flags = CPF_UseAmmo, class<Actor> puffType = "BulletPuff", double range = 0,
        name damageType = 'Melee', double lifesteal = 0, int lifestealmax = 0,
        class<BasicArmorBonus> armorBonusType = "ArmorBonus", sound MeleeSound = 0, sound MissSound = ""
    ) {
        if (!player)
            return null;

        let weapon = player.ReadyWeapon;
        double angle, pitch;
        FTranslatedLineTarget t;
        int actualdamage;

        if (range == 0)
            range = DEFMELEERANGE;

        angle = self.Angle + random2 [cwpunch] () * (5.625 / 256);
        pitch = AimLineAttack (angle, range, t, 0., ALF_Check3D);

        // only use ammo when actually hitting something!
        if ((flags & CPF_UseAmmo) && t.linetarget && weapon && stateinfo != null && stateinfo.mStateType == STATE_PSprite) {
            if (!weapon.DepleteAmmo (weapon.bAltFire, true))
                return null; // out of ammo
        }

        if (puffType == NULL)
            puffType = 'BulletPuff';
        int puffFlags = LAF_IsMeleeAttack | ((flags & CPF_NoRandomPuffZ) ? LAF_NoRandomPuffZ : 0);

        Actor puff;
        [puff, actualdamage] = LineAttack (angle, range, pitch, damage, damageType, puffType, puffFlags, t);

        if (!t.linetarget) {
            if (MissSound)
                A_PlaySound (MissSound, CHAN_WEAPON);
        } else {
            if (lifesteal > 0 && !(t.linetarget.bDontDrain)) {
                if (flags & CPF_StealArmor) {
                    if (armorBonusType == NULL)
                        armorBonusType = 'ArmorBonus';

                    if (armorBonusType != NULL) {
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
            if (weapon != NULL) {
                if (MeleeSound) A_PlaySound ( MeleeSound, CHAN_WEAPON);
                else            A_PlaySound (AttackSound, CHAN_WEAPON);
            }

            // turn to face target
            if (!(flags & CPF_NoTurn))
                self.Angle = t.angleFromSource;

            if (flags & CPF_PullIn)
                self.bJustAttacked = true;
            if (flags & CPF_Dagger)
                t.linetarget.DaggerAlert (self);
        }

        return puff;
    }

    bool meleeAttackSoundPlayed;
    action void S7_QuickMeleeCustomPunch (int damage, class<Actor> puffType) {
        let puff = S7_CustomPunch (damage, 0, puffType, damageType: 'QuickMelee');

        if (!puff)
            return;

        if (invoker.meleeAttackSoundPlayed) {
            for (int i = CHAN_Auto; i < CHAN_7; i++)
                puff.A_StopSound (i);
        }

        let crashState = puff.FindState ("Crash"),
            xdeathState = puff.FindState ("XDeath");
        if (puff.InStateSequence (puff.CurState, crashState) ||
            puff.InStateSequence (puff.CurState, xdeathState))
            invoker.meleeAttackSoundPlayed = true;
    }

    enum S7_A_FireBullets_Flags {
        S7_FB_SpeedOffs = 1 << 0,
        S7_FB_UseAmmo   = 1 << 1,
    }

    action Actor, S7_TZK_ArrayObj S7_A_SpawnSFX (class<Actor> sfxType, Vector3 offs = (0, 0, 0), int amount = 1, int flags = 0) {
        return S7_A_FireBullets (sfxType, offs: offs, amount: amount, flags: flags | S7_FB_SpeedOffs);
    }

    action Actor, S7_TZK_ArrayObj S7_A_FireBullets (
        class<Actor> projType,
        Vector2 spread = (0, 0), Vector3 offs = (0, 0, 0),
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
            Vector3 xVec = (1, 0, 0),
                    yVec = (0, 1, 0),
                    zVec = (0, 0, 1);

            let qRot = S7_GM_Quaternion.CreateFromAngles (angle, pitch, roll);

            xVec = qRot.RotateVector3 (xVec);
            yVec = qRot.RotateVector3 (yVec);
            zVec = qRot.RotateVector3 (zVec);

            origin = level.Vec3Offset (Vec2OffsetZ (0, 0, player.viewZ),
                xVec * offs.X -
                yVec * offs.Y -
                zVec * offs.Z
            );
        }

        Vector3 forwards, sideways, vertical; {
            forwards = (1, 0, 0);
            sideways = (0, 1, 0);
            vertical = (0, 0, 1);

            let qRot = S7_GM_Quaternion.CreateFromAngles (
                angle          + fRandom [weaponSpread] (-spread.X, spread.X),
                BulletSlope () + fRandom [weaponSpread] (-spread.Y, spread.Y),
                roll
            );

            forwards = qRot.RotateVector3 (forwards);
            sideways = qRot.RotateVector3 (sideways);
            vertical = qRot.RotateVector3 (vertical);
        }

        let arr = new ('S7_TZK_ArrayObj');
        arr.Clear ();

        for (int i = 0; i < amount; i++) {
            let proj = Spawn (projType, origin);

            proj.target = self;
            let dir = forwards.Unit ();
            proj.vel = (dir * proj.Speed);
            proj.angle = atan2 (dir.Y, dir.X);
            proj.pitch = -asin (dir.Z);

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
        ---- A 0 {
            TakeInventory ('S7_HoldingZoom', 0x7FFFFFFF);
            TakeInventory ('S7_Weap_ReadyFrame', 0x7FFFFFFF);
            A_ZoomFactor (1.0);
            A_WeaponOffset (0, 32);

            if (!health)
                return ResolveState ("Deselect.DEAD");

            return ResolveState (null);
        }
        ---- A 0 A_Lower ();
        wait;
    Deselect.DEAD:
        ---- A 0 {
            A_ZoomFactor (1.0, ZOOM_Instant);
            A_WeaponOffset (0, 32);
        }
        ---- A 1 A_Lower;
        wait;
    Overlay.DeselectDEAD:
        #### # 1 {
            let psp = player.FindPSprite (PSP_WEAPON);

            if (!psp)
                return ResolveState ("Null");

            return ResolveState (null);
        }
        wait;

    QuickMelee:
        TNT1 A 0 {
            TakeInventory ('S7_DoMelee', 0x7FFFFFFF);
            if (CheckInventory ('S7_DaggerMelee', 1))
                return ResolveState ("DaggerMelee");
            if (CheckInventory ('S7_MacheteMelee', 1))
                return ResolveState ("MacheteMelee");

            return ResolveState ("KickMelee");
        }

    DaggerMelee:
        TNT1 A 0 A_Jump (256, "DaggerMelee1", "DaggerMelee2");
        wait;
    DaggerMelee1:
        DAG1 ABCD 1;
        DAG1 E    1 {
            A_PlaySound ("Weapons/Tridagger/Swing", CHAN_Weapon);
            S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (9. + fRandom [weaponDamage] (-0.5, 1.0)), 'S7_DaggerPuff');
        }
        DAG1 F    1 S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (9. + fRandom [weaponDamage] (-0.5, 1.0)), 'S7_DaggerPuff');
        DAG1 G    1 S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (9. + fRandom [weaponDamage] (-0.5, 1.0)), 'S7_DaggerPuff');
        DAG1 H    1 { invoker.meleeAttackSoundPlayed = false; }
        TNT1 A    5;
        TNT1 A    0 A_Jump (256, "MeleeDone");
        wait;
    DaggerMelee2:
        DAG2 AB 1;
        DAG2 C  1 {
            A_PlaySound ("Weapons/Tridagger/Swing", CHAN_Weapon);
            S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (9. + fRandom [weaponDamage] (-0.5, 1.0)), 'S7_DaggerPuff');
        }
        DAG2 D  1 S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (9. + fRandom [weaponDamage] (-0.5, 1.0)), 'S7_DaggerPuff');
        DAG2 E  1 S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (9. + fRandom [weaponDamage] (-0.5, 1.0)), 'S7_DaggerPuff');
        DAG2 F  1 { invoker.meleeAttackSoundPlayed = false; }
        DAG2 GH 1;
        TNT1 A  5;
        TNT1 A  0 A_Jump (256, "MeleeDone");
        wait;

    MacheteMelee:
        TNT1 A  4;
        KNF1 AB 1;
        KNF1 C  1 {
            A_PlaySound ("Weapons/Machete/Swing", CHAN_Weapon);
            S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (15.35 + fRandom [weaponDamage] (-2, 5)), 'S7_MachetePuff');
        }
        KNF1 D  1 S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (15.35 + fRandom [weaponDamage] (-2, 5)), 'S7_MachetePuff');
        KNF1 E  1 S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (15.35 + fRandom [weaponDamage] (-2, 5)), 'S7_MachetePuff');
        KNF1 F  1 { invoker.meleeAttackSoundPlayed = false; }
        TNT1 A 12;
        TNT1 A 0 A_Jump (256, "MeleeDone");
        wait;

    KickMelee:
        KICK BCD   1;
        KICK H     1 S7_CustomPunch (S7_GetMeleeDamage (30. + fRandom [weaponDamage] (-2.5, 5)), 0, 'S7_MeleePuff');
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
    Crash:
        TNT1 A 1;
        stop;
    XDeath:
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
        ActiveSound "";
        AttackSound "Weapons/Tridagger/HitWall";
        SeeSound "Weapons/Tridagger/HitFlesh";
    }
}

class S7_MachetePuff : S7_MeleePuff {
    default {
        DamageType 'Blade';
        ActiveSound "";
        AttackSound "Weapons/Machete/HitWall";
        SeeSound "Weapons/Machete/HitFlesh";
    }
}

//-------------------------------------------------------------------------------------------
//
// Misc crap
//
//-------------------------------------------------------------------------------------------
class S7_Unarmed : S7_BaseWeapon { default { Tag "$UNARMED"; } }