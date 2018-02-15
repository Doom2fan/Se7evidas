version "3.3"

class S7_Draco_Massacre : S7_DracoWeapon {
    default {
        tag "lolololololololol";
        inventory.pickupMessage "$IONCANNON";
        //weapon.ammoType1 "S7_PrettyShootyIonCannonGunMag";
        //weapon.ammoType2 "S7_Cells";
        weapon.ammoUse 0;
        weapon.ammoGive 0;
        S7_BaseWeapon.Icon "PIC1Z0";
        S7_BaseWeapon.ShortTag "lolololololololol";
    }

    action void DMSC_SpawnSmoke (int count) {
        for (int i = 0; i < count; i++)
            A_FireProjectile ("S7_HeatSmokeSpawner", 0, 0, random [sfx] (4, 10), fRandom [sfx] (-8.0, -9.2));
    }

    states {
    Spawn:
        //PIC1 Z -1;
        //stop;

    Ready:
    Ready2:
        DMSC AAAAAAAAAAAABBCCDDEEFFFFFEEDDCCBB 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            /*if (CheckInventory ("S7_ChangeFireMode", 1))
                return ResolveState ("ChangeMode");*/
            TakeInventory ("S7_ChangeFireMode", 1);

            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Reload:
        DMSC A 5 TakeInventory ("S7_Reloading", 1);
        goto Ready2;

    Fire:
        DMSC A 1 {
            A_FireProjectile ("S7_Draco_MassacreProjectile", 0.0, 1, 6, -3.3);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 4, 0);

            A_AlertMonsters ();

            A_WeaponOffset (6, 32 + 4.5);
        }
        DMSC A 2 A_WeaponOffset (12, 32 + 9, WOF_Interpolate);
        DMSC A 1 {
            DMSC_SpawnSmoke (2);
            A_WeaponOffset (8, 32 + 6, WOF_Interpolate);
        }
        DMSC A 1 {
            DMSC_SpawnSmoke (2);
            A_WeaponOffset (4, 32 + 3, WOF_Interpolate);
        }
        DMSC A 1 {
            DMSC_SpawnSmoke (2);
            A_WeaponOffset (0, 32, WOF_Interpolate);
        }
        DMSC A 5 DMSC_SpawnSmoke (5);
        goto Ready2;
    }
}

class S7_Draco_MassacreProjectile : S7_Projectile {
    int realDamage;

    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.interpMove false;
        S7_Projectile.EffectStepMul 0.015625;
        radius 8;
        height 8;
        speed 20;
        renderStyle "add";
        scale 0.04;
        damageFunction (realDamage);
        damageType "DracoMassacre";
        missileType "S7_Draco_MassacreProjectileTrail";
        missileHeight 8;
        //decal "S7_IonCannon";

        +forceXYBillboard +forceRadiusDMG +bloodlessImpact
    }

    override Actor StepEffects (Vector3 initialPos, Vector3 stepDiff, Vector3 realVel) {
        let act = super.StepEffects (initialPos, stepDiff, realVel);
        act.alpha = (abs (stepDiff.Length ()) / abs (realVel.Length ()));
        return act;
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            A_ScaleVelocity (1.0 / 20);
            A_ScaleVelocity (240);
            realDamage = 100 + (fRandom [weaponDamage] (1.0, 10.0) * 15);
        }
    Idle:
        PLGF A 1 bright;
        PLGF A 1 bright {
            let swVel = vel.Unit () * 3.5;
            Actor sw; bool useless;
            [useless, sw] = A_SpawnItemEx ("S7_Draco_MassacreProjectileShockwave", flags: SXF_NoCheckPosition | SXF_Clientside);
            sw.vel = -swVel;
        }
        wait;

    Death:
        TNT1 A 3 {
            for (int i = 0; i < 8; i++)
                A_SpawnItemEx ("S7_Draco_MassacreExpSmoke", fRandom [sfx] (-5, 5), fRandom [sfx] (-5, 5), fRandom [sfx] (-5, 5),
                    fRandom [sfx] (2, 6), 0, fRandom [sfx] (0, 4) * randomPick [sfx] (-1, 1), fRandom [sfx] (0, 359), SXF_NoCheckPosition | SXF_Clientside);
            A_Explode (304, 256, fulldamagedistance: 144);
        }
        stop;
    }
}

class S7_Draco_MassacreProjectileTrail : S7_TracerEffectsBase {
    default {
        renderStyle "add";
        scale 0.04;
    }

    states {
    Spawn:
        PLGF A 2 bright;
        stop;
    }
}

class S7_Draco_MassacreProjectileShockwave : S7_FastProjTrailBase {
    default {
        renderStyle "add";
        scale 0.25;
        alpha 1.0;

        +noInteraction
    }

    states {
    Spawn:
        SSHK ABCDEFGHIJKL 1 A_FadeOut (0.08182);
        stop;
    }
}

class S7_Draco_MassacreExpSmoke : S7_HeatSmoke {
    default {
        renderStyle "add";
        scale 1.0;
        alpha 1.0;

        +rollSprite
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            A_SetRoll (fRandom [sfx] (0, 360));
            return A_Jump (256, "FrameA", "FrameB", "FrameC", "FrameD");
        }
        wait;

    FrameA: DMSE A 0; goto Loople;
    FrameB: DMSE B 0; goto Loople;
    FrameC: DMSE C 0; goto Loople;
    FrameD: DMSE D 0; goto Loople;

    Loople:
        "####" "#" 1 bright {
            A_FadeOut (0.05);
            A_SetScale (scale.X + 0.02);
        }
        loop;
    }
}