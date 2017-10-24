// Mode constants
enum GauntletsOfPowerModes {
    GoPSp_None                  =  0,
    GoPSp_Fireball              =  1,
    GoPSp_Flamethrower          =  2,
    GoPSp_IceBall               =  3,
    GoPSp_IceMissile            =  4,
    GoPSp_AirBlast              =  5,
    GoPSp_Pillars               =  6,
    GoPSp_PillarsAoE            =  7,
    GoPSp_LightningBolt         =  8,
    GoPSp_LightningBall         =  9,
    GoPSp_MagicMissile          = 10,
    GoPSp_Shockwave             = 11,
};

class S7_Gauntlets : S7_BaseWeapon {
    default {
        weapon.ammoType "S7_Mana";
        weapon.ammoUse 0;
        weapon.ammoGive 0;
        weapon.slotNumber 0;
    }

    int mode;

    states {
    Ready:
        SGTS AB 1;
    Ready2:
        SGNT A 1 {
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            if (CheckInventory ("S7_ChangeFireMode", 1))
                return ResolveState ("ChangeMode");
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("ChangeModeReverse");

            GiveInventory ("S7_WeapReady", 1);
            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Deselect:
        SGNT A  1;
        SGTS BA 1;
        goto TrueDeselect;

    Fire:
        SGNT A 6 {
            switch (invoker.mode) {
                //case GoPSp_Shockwave:     return ResolveState ("Shockwave_Fire"); break;
                //case GoPSp_MagicMissile:  return ResolveState ("MagicMissile_Fire"); break;
                //case GoPSp_LightningBall: return ResolveState ("LightningBall_Fire"); break;
                case GoPSp_LightningBolt: return ResolveState ("LightningBolt_Fire");
                //case GoPSp_PillarsAoE:    return ResolveState ("PillarsAoE_Fire"); break;
                //case GoPSp_Pillars:       return ResolveState ("Pillars_Fire"); break;
                //case GoPSp_AirBlast:      return ResolveState ("AirBlast_Fire"); break;
                //case GoPSp_IceMissile:    return ResolveState ("IceMissile_Fire"); break;
                //case GoPSp_IceBall:       return ResolveState ("IceBall_Fire"); break;
                case GoPSp_Flamethrower:  return ResolveState ("Flamethrower_Fire"); break;
                case GoPSp_Fireball:      return ResolveState ("Fireball_Fire"); break;
            }

            A_Print ("$GOP_NOSPELL");

            return ResolveState (null);
        }
        goto Ready2;

    ChangeMode:
        TNT1 A 0 {
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            if (++invoker.mode > GoPSp_Shockwave)
                invoker.mode = GoPSp_Fireball;
        }
        goto ModeChange.End;
    ChangeModeReverse:
        TNT1 A 0 {
            TakeInventory ("S7_Reloading", 0x7FFFFFFF);

            if (--invoker.mode < GoPSp_Fireball)
                invoker.mode = GoPSp_Shockwave;
        }
        goto ModeChange.End;
    ModeChange.End:
        SGNT A 4 A_PlaySound ("Weapons/Gauntlets/ModeChange", CHAN_Weapon);
        goto Ready2;

    /*
    ** Fireball
    */
    Fireball_Fire:
        SGNT A   2 {
            if (!CheckInventory ("S7_Mana", 15))
                return ResolveState ("Fire.Cancel");

            return ResolveState (null);
        }
        GHFB ABC 2;
        GHFB DE  2 bright;
    Fireball_Hold:
        GHFB F  1 bright;
        GHFB F  2 bright {
            TakeInventory ("S7_Mana", 15);
            A_SetBlend ("Red", 0.1, 10);
            A_PlaySound ("Weapons/Gauntlets/FireballFire", CHAN_Weapon);
            A_FireProjectile ("S7_Gauntlets_Fireball", 0, FALSE, 1, -7.0, 0, 3.0);
        }
        GHFB GH 1 bright;
        GHFB F  5 bright;
        GHFB FF 1 bright A_Refire ("Fireball_Refire");
        goto Fireball_Finish;
    Fireball_Refire:
        GHFB F 18 bright {
            if (!CheckInventory ("S7_Mana", 15))
                return ResolveState ("Fireball_Finish");

            return ResolveState (null);
        }
        goto Fireball_Hold;
    Fireball_Finish:
        GHFB ED  2 bright A_ClearRefire;
        GHFB CBA 2;
        SGNT A   2;
        goto Ready2;

    /*
    ** Flamethrower
    */
    Flamethrower_Fire:
        SGNT A   2 {
            if (!CheckInventory ("S7_Mana", 15))
                return ResolveState ("Fire.Cancel");

            return ResolveState (null);
        }
        SGNT RST 2;
        GHFT ABC 2;
    Flamethrower_Hold:
        GHFT D  2 {
            if (!CheckInventory ("S7_Mana", 5))
                return ResolveState ("Flamethrower_End");

            TakeInventory ("S7_Mana", 5);

            A_FireProjectile ("S7_Gauntlets_Flamethrower", 0.0, FALSE, 0, -3.0);
            return ResolveState (null);
        }
        GHFT EF 2 A_FireProjectile ("S7_Gauntlets_Flamethrower", 0.0, FALSE, 0, -3.0);

        GHFT G  2 {
            if (!CheckInventory ("S7_Mana", 5))
                return ResolveState ("Flamethrower_End");

            TakeInventory ("S7_Mana", 5);

            A_FireProjectile ("S7_Gauntlets_Flamethrower", 0.0, FALSE, 0, -3.0);
            return ResolveState (null);
        }
        GHFT HI 2 A_FireProjectile ("S7_Gauntlets_Flamethrower", 0.0, FALSE, 0, -3.0);

        GHFT D 1 A_Refire ("Flamethrower_Hold");
    Flamethrower_End:
        GHFT CBA  2 A_ClearRefire;
        SGNT TSRA 2;
        goto Ready2;

    /*
    ** Lightning bolt
    */
    LightningBolt_Fire:
        SGNT A 2 {
            if (!CheckInventory ("S7_Mana", 2))
                return ResolveState ("Fire.Cancel");

            return ResolveState (null);
        }
        SGNT RST 2;
    LightningBolt_Hold:
        SGNT UVW 1 {
            if (!CheckInventory ("S7_Mana", 2))
                return ResolveState ("LightningBolt_Finish");

            A_SetTics (random (2, 3));
            A_RailAttack (fRandom (1, 2) * fRandom (3.5, 7.5), -5, 0, "", "", RGF_Silent | RGF_NoPiercing | RGF_ExplicitAngle, 0.5, "S7_GauntletsLightningPuff", 0.0, 0.0, 384.0, 0, 10.0, 0.0, "S7_GauntletsLightning", -3.3);
            A_RailAttack (fRandom (1, 2) * fRandom (3.5, 7.5),  5, 0, "", "", RGF_Silent | RGF_NoPiercing | RGF_ExplicitAngle, 0.5, "S7_GauntletsLightningPuff", 0.0, 0.0, 384.0, 0, 10.0, 0.0, "S7_GauntletsLightning", -3.3);
            TakeInventory ("S7_Mana", 2);

            return ResolveState (null);
        }
        TNT1 A 0 A_Refire ("LightningBolt_Hold");
        goto LightningBolt_Finish;
    LightningBolt_Finish:
        SGNT TSRA 2 A_ClearRefire;
        goto Ready2;

    Fire.Cancel:
        SGNT A 1 A_ClearRefire;
        goto Ready2;

    DerpMelee:
        SGNT A  1 TakeInventory ("S7_DoMelee", 0x7FFFFFFF);
        SGTS BA 1;
        TNT1 A  1 A_Jump (256, "AltHold");
        wait;

    AltFire:
        SGNT A  1;
        SGTS BA 1;
    AltHold:
        SGNT B    1 A_PlaySound ("Weapons/Gauntlets/Swing", 5);
        SGNT CD   1 A_SetAngle (angle - 0.85);
        SGNT E    1 {
            A_CustomPunch (0, TRUE, 0, "S7_GauntletsMeleeSound");
            A_CustomPunch (fRandom (1.75, 3) * 8, TRUE, 0, "S7_GauntletsMelee");
        }
        SGNT FGHI 1;
        TNT1 A    3;
        TNT1 A    0 A_Refire ("AltHold2");
        goto AltFire.Finish;
    AltHold2:
        TNT1 A    1;
        SGNT J    1 A_PlaySound ("Weapons/Gauntlets/Swing", 6);
        SGNT KL   1 A_SetAngle (angle + 0.85);
        SGNT M    1 {
            A_CustomPunch (0, TRUE, 0, "S7_GauntletsMeleeSound");
            A_CustomPunch (fRandom (1.75, 3) * 8, TRUE, 0, "S7_GauntletsMelee");
        }
        SGNT NOPQ 1;
        TNT1 A    3;
        TNT1 A    0 A_Refire ("AltHold");
        goto AltFire.Finish;
    AltFire.Finish:
        TNT1 A  1;
        SGTS AB 1;
        SGNT A  1;
        goto Ready2;
    }
}

class S7_GauntletsMelee : S7_BulletPuff {
    default {
        +noExtremeDeath
    }

    states {
    Spawn:
        TNT1 A 0;
        goto NoSound;
    }
}

class S7_GauntletsMeleeSound : S7_BulletPuff {
    default {
        seeSound "Weapons/Gauntlets/Hit";
        attackSound "Weapons/Gauntlets/HitWall";

        +noExtremeDeath +puffOnActors +alwaysPuff
    }

    states {
    Crash:
    Death:
    XDeath:
    Melee:
    Spawn:
        TNT1 A 1;
        stop;
    }
}