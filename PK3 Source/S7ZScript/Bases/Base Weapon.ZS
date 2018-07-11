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
    String weapIcon;
    String shortTag;
    S7_WeaponSlots bindSlot;

    property Icon: weapIcon;
    property ShortTag: shortTag;
    property BindSlot: bindSlot;

    default {
        Inventory.PickupSound "misc/gunpickup";
        Weapon.BobRangeX 0.3;
        Weapon.BobRangeY 0.5;
        Weapon.BobSpeed 2.0;
        Weapon.BobStyle "inverseSmooth";
        Weapon.Kickback 100;
        S7_BaseWeapon.Icon "";
        S7_BaseWeapon.BindSlot -1;

        +INVENTORY.UNDROPPABLE +WEAPON.AMMO_OPTIONAL +WEAPON.NOAUTOFIRE +WEAPON.NOALERT
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
        let weapBinds = S7_WeapBindsSystem (Owner.FindInventory ("S7_WeapBindsSystem"));
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

    action int S7_GetMeleeDamage (double baseDamage, double mul) {
        double baseMul  = 1.0;
        double mulBonus = 0.0;

        let pPawn = S7_BasePlayer (invoker.Owner);
        if (pPawn)
            baseMul += pPawn.xpSys.GetStat (S7Stat_Strength, false) * 0.025;

        if (CheckInventory ("S7_BerserkToken", 1)) {
            baseMul *= 3.0;
            mulBonus = fRandom [weaponDamage] (0.0, 2.0);
        }

        return ceil ((baseDamage * baseMul + 0.5) * (mul + mulBonus));
    }

    S7_XPSystem GetOwnerXPSystem () {
        if (!Owner || !(Owner is "S7_BasePlayer"))
            return null;

        let xpSystem = S7_XPSystem (Owner.FindInventory ("S7_XPSystem", true));

        if (!xpSystem)
            return null;

        return xpSystem;
    }

    virtual void V_S7_Recoil (double amount) {
        if (S7_Debug_NoRecoil)
            return;

        Owner.A_SetPitch (Owner.pitch + amount, SPF_Interpolate);
    }

    action void S7_Recoil (double amount) {
        invoker.V_S7_Recoil (amount);
    }

    states {
    DryFire:
        TNT1 A 0 {
            A_PlaySound ("Weapons/DryFire", CHAN_Weapon);

            if (S7_PlayerCVar.GetInt (player, "S7_AutoReloading"))
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
            TakeInventory ("S7_HoldingZoom", 0x7FFFFFFF);
            TakeInventory ("S7_Weap_ReadyFrame", 0x7FFFFFFF);
            A_ZoomFactor (1.0);

            if (!health)
                return ResolveState ("Deselect.DEAD");

            A_Lower ();
            return ResolveState (null);
        }
        loop;
    Deselect.DEAD:
        TNT1 A 1 A_Lower;
        wait;

    QuickMelee:
        TNT1 A 0 {
            TakeInventory ("S7_DoMelee", 0x7FFFFFFF);
            if (CheckInventory ("S7_DaggerMelee", 1))
                return ResolveState ("DaggerMelee");
            if (CheckInventory ("S7_PunchMelee", 1))
                return ResolveState ("PunchMelee");
            if (CheckInventory ("S7_KickMelee", 1))
                return ResolveState ("KickMelee");

            return ResolveState ("KickMelee");
        }

    DaggerMelee:
        TNT1 A 0 A_Jump (256, "DaggerMelee1", "DaggerMelee2");
        wait;
    DaggerMelee1:
        DAG1 ABCD 1;
        DAG1 E    1 A_CustomPunch (S7_GetMeleeDamage (3, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_DaggerPuffSilent");
        DAG1 F    1 A_CustomPunch (S7_GetMeleeDamage (3, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_DaggerPuff");
        DAG1 G    1 A_CustomPunch (S7_GetMeleeDamage (3, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_DaggerPuffSilent");
        DAG1 H    1;
        TNT1 A    5;
        TNT1 A    0 A_Jump (256, "MeleeDone");
        wait;
    DaggerMelee2:
        DAG2 AB  1;
        DAG2 C   1 A_CustomPunch (S7_GetMeleeDamage (2, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_DaggerPuffSilent");
        DAG2 D   1 A_CustomPunch (S7_GetMeleeDamage (2, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_DaggerPuff");
        DAG2 EF  1 A_CustomPunch (S7_GetMeleeDamage (2, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_DaggerPuffSilent");
        DAG2 GH  1;
        TNT1 A   5;
        TNT1 A   0 A_Jump (256, "MeleeDone");
        wait;

    PunchMelee:
        TNT1 A 0 A_Jump (256, "MeleeDone");
        wait;

    KickMelee:
        KICK BCD   1;
        KICK H     1 A_CustomPunch (S7_GetMeleeDamage (13, fRandom [weaponDamage] (1.0, 5.0)), 1, 0, "S7_MeleePuff");
        KICK HHHIG 1;
        KICK FEDCB 1;
        KICK A     1;

        TNT1 A 0 A_Jump (256, "MeleeDone");
        wait;

    MeleeDone:
        TNT1 A 0 A_JumpIfInventory ("S7_DoMelee", 1, "QuickMelee");
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

    property MaxForce: maxForce;

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
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("CancelThrow");

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
class S7_MeleePuff : S7_EffectsBase { // By Jekyll Grim Payne/zer0, edited by Chronos "phantombeta" Ouroboros
    default {
        DamageType "Kick";
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

class S7_MeleePuffStrong : S7_MeleePuff { // Ditto
    default {
        Decal "FistScorch";
        AttackSound "Weapons/Kick/Strong";
        ActiveSound "Weapons/Kick/Swing";

        +EXTREMEDEATH
        -NOEXTREMEDEATH
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnItem ("S7_ShotSmoke");
        stop;
    }
}

class S7_DaggerPuff : S7_MeleePuff {
    default {
        DamageType "Blade";
        AttackSound "Weapons/Tridagger/HitWall";
        ActiveSound "Weapons/Tridagger/Swing";
    }
}
class S7_DaggerPuffSilent : S7_DaggerPuff {
    default {
        AttackSound "";
        ActiveSound "";
    }
}

//-------------------------------------------------------------------------------------------
//
// Misc crap
//
//-------------------------------------------------------------------------------------------
class S7_Unarmed : S7_BaseWeapon { default { Tag "$UNARMED"; } }