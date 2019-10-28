extend class S7_LaserPewPew {
    const LeftActionLayer_ID = 3;
    const LeftAnimLayer_ID = 4;

    action void S7_SetLeftAction (StateLabel animState) {
        A_Overlay (LeftActionLayer_ID, animState);
    }

    action void S7_SetLeftAnim (StateLabel animState) {
        S7_Internal_SetAnim (LeftAnimLayer_ID, animState, PSPF_Flip | PSPF_Mirror, PSPF_AddBob);
    }

    action bool S7_IsLeftReady () {
        let psp = player.FindPSprite (LeftActionLayer_ID);
        if (!psp)
            return false;
        return InStateSequence (psp.CurState, ResolveState ("AkimboLeft.Ready"));
    }

    protected bool reloadLeft, reloadRight;

    /** Animations **/
    states {
    AnimAkimbo.Idle:
        BLS2 A 1;
        wait;
    AnimAkimbo.Fire:
        BLS2 A 1 bright;
        BLS2 C 1;
        BLS2 B 1;
        goto AnimAkimbo.Idle;
    AnimAkimbo.Reload: // 18 tics
        BLSG GH  2;
        BLSG I   4 A_PlaySound ("Weapons/LaserPewPew/In", CHAN_7);
        BLSG J   4;
        BLSG IHG 2;
        goto AnimAkimbo.Idle;

    AnimAkimbo.DeselectDEAD:
        BLS2 A 0 A_OverlayFlags (0, PSPF_AddWeapon | PSPF_AddBob, true);
        goto Overlay.DeselectDEAD;
    AnimAkimbo.Select:
        TNT1 A 0 {
            A_OverlayFlags (0, PSPF_AddWeapon | PSPF_AddBob, false);
        }
        BLS2 A 1 DoSelectOffset ((103, 67), 0, forceNoInterpolate: true);
        BLS2 A 1 DoSelectOffset (( 84, 52), 0);
        BLS2 A 1 DoSelectOffset (( 64, 35), 0);
        BLS2 A 1 DoSelectOffset (( 39, 20), 0);
        BLS2 A 1 DoSelectOffset (( 20, 10), 0);
        BLS2 A 1 DoSelectOffset ((  0,  0), 0);
        TNT1 A 0 {
            A_OverlayFlags (0, PSPF_AddWeapon | PSPF_AddBob, true);
            A_OverlayOffset (0, 0, 0);
        }
        goto AnimAkimbo.Idle;
    AnimAkimbo.Deselect:
        TNT1 A 0 {
            A_OverlayFlags (0, PSPF_AddWeapon | PSPF_AddBob, false);
        }
        BLS2 A 1 DoSelectOffset ((  0,  0), 0, forceNoInterpolate: true);
        BLS2 A 1 DoSelectOffset (( 20, 10), 0);
        BLS2 A 1 DoSelectOffset (( 39, 20), 0);
        BLS2 A 1 DoSelectOffset (( 64, 35), 0);
        BLS2 A 1 DoSelectOffset (( 84, 52), 0);
        BLS2 A 1 DoSelectOffset ((103, 67), 0);
        TNT1 A 0 {
            A_OverlayFlags (0, PSPF_AddWeapon | PSPF_AddBob, true);
            A_OverlayOffset (0, 0, 0);
        }
        TNT1 A 1;
        wait;

    AnimRight.ToAkimbo:
        BLSG ADEF 2;
        goto AnimAkimbo.Idle;
    AnimRight.ToSingle:
        BLSG FEDA 2;
        goto AnimSingle.Idle;
    }

    /** Actions **/
    states {
    ChangeMode:
        TNT1 A 6 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            if (invoker.amount <= 1)
                return ResolveState ("Ready2");

            S7_SetRightAnim ("AnimRight.ToAkimbo");

            return ResolveState (null);
        }
        TNT1 A 4 {
            invoker.akimbo = true;
            // Just to be sure:
            player.WeaponState &= ~WF_DisableSwitch;
            player.WeaponState &= ~WF_WeaponSwitchOK;
        }
        TNT1 A 6 S7_SetLeftAction ("AkimboLeft.Select");
        goto AkimboRight.Ready;
    ChangeMode.ToSingle:
        BLS2 A 10 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            invoker.akimbo = false;
            S7_SetRightAnim ("AkimboAnim.Idle");
            S7_SetLeftAction ("Null");
            S7_SetLeftAnim ("AnimAkimbo.Deselect");
        }
        TNT1 A 6 S7_SetRightAnim ("AnimRight.ToSingle");
        goto Ready2;
    ChangeMode.ToSingleDropped:
        TNT1 A 6 {
            invoker.akimbo = false;
            S7_SetLeftAction ("Null");
            S7_SetLeftAnim ("Null");
            S7_SetRightAnim ("AnimRight.ToSingle");
        }
        goto Ready2;

    // Ready
    AkimboRight.Ready:
        TNT1 A 1 {
            TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

            S7_SetRightAnim ("AnimAkimbo.Idle");
            A_OverlayFlags (RightAnimLayer_ID, PSPF_AddBob, true);
            if (!(player.WeaponState & WF_WeaponBobbing))
                DoReadyWeaponToBob (player);

            bool leftReady = S7_IsLeftReady ();
            if (leftReady) {
                if (CheckInventory ('S7_Reloading', 1) && invoker.CanReload ()) {
                    S7_SetLeftAction ("AkimboLeft.Waiting");
                    return ResolveState ("AkimboRight.Reload");
                }
                TakeInventory ("S7_Reloading", 0x7FFFFFFF);

                if (CheckInventory ('S7_ChangeFireMode', 1) && invoker.CanReload ()) {
                    S7_SetLeftAction ("AkimboLeft.Waiting");
                    return ResolveState ("ChangeMode.ToSingle");
                }
                TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);
            }

            DoReadyWeaponToSwitch (player, leftReady);

            if (invoker.CheckButton (CB_Pressed, BT_Attack))
                return ResolveState ("AkimboRight.Fire");

            return ResolveState (null);
        }
        wait;
    AkimboLeft.Ready:
        TNT1 A 1 {
            TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

            S7_SetLeftAnim ("AnimAkimbo.Idle");
            A_OverlayFlags (LeftAnimLayer_ID, PSPF_AddBob, true);

            if (!(player.WeaponState & WF_WeaponBobbing))
                DoReadyWeaponToBob (player);

            if (invoker.CheckButton (CB_Pressed, BT_AltAttack))
                return ResolveState ("AkimboLeft.Fire");

            return ResolveState (null);
        }
        loop;
    AkimboLeft.Waiting:
        TNT1 A 1;
        wait;

    // Selection
    AkimboRight.Select:
        TNT1 A 6 S7_SetRightAnim ("AnimAkimbo.Select");
        goto AkimboRight.Ready;
    AkimboLeft.Select:
        TNT1 A 6 S7_SetLeftAnim ("AnimAkimbo.Select");
        goto AkimboLeft.Ready;
    Akimbo.Select:
        TNT1 A 0 S7_SetLeftAction ("AkimboLeft.Select");
        goto AkimboRight.Select;
    Akimbo.Deselect:
        TNT1 A 6 {
            if (health <= 0) {
                S7_SetRightAnim ("AnimAkimbo.DeselectDEAD");
                S7_SetLeftAction ("Null");
                S7_SetLeftAnim ("AnimAkimbo.DeselectDEAD");

                return ResolveState ("Deselect.DEAD");
            }

            S7_SetLeftAction ("Null");
            S7_SetLeftAnim ("AnimAkimbo.Deselect");
            S7_SetRightAnim ("AnimAkimbo.Deselect");

            return ResolveState (null);
        }
        goto TrueDeselect;

    // Firing
    AkimboRight.Fire:
        TNT1 A 1 bright {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("AkimboRight.DryFire");

            S7_SetRightAnim ("AnimAkimbo.Fire");

            A_AlertMonsters ();
            A_PlaySound ("Weapons/LaserPewPew/Fire", CHAN_Weapon);

            A_GunFlash ("Flash");
            S7_A_FireBullets ('S7_LaserPewPew_Tracer', spread: (.2, .2), offs: (10, 4.5, 4.5), bonusDMGFactor: invoker.GetDamageBonus (), flags: S7_FB_UseAmmo);
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2.75, 2.75));

            A_ZoomFactor (invoker.GetZoomFactor () * .996);
            S7_Recoil (-0.38);

            return ResolveState (null);
        }
        TNT1 A 1 {
            A_ZoomFactor (invoker.GetZoomFactor () * .998);
            S7_Recoil (-0.07);
        }
        TNT1 A 1 {
            A_ZoomFactor (invoker.GetZoomFactor ());
            S7_Recoil (-0.07);
        }
        TNT1 A 1;
        TNT1 A 1 A_JumpIf (invoker.CheckButton (CB_Down, BT_Attack), "AkimboRight.Fire");
        goto AkimboRight.Ready;
    AkimboLeft.Fire:
        TNT1 A 1 bright {
            if (!CheckInventory (SecondMagClass, 1))
                return ResolveState ("AkimboLeft.DryFire");

            S7_SetLeftAnim ("AnimAkimbo.Fire");

            A_AlertMonsters ();
            A_PlaySound ("Weapons/LaserPewPew/Fire", CHAN_Weapon);

            A_Overlay (1001, "Flash");
            A_OverlayFlags (1001, PSPF_AddWeapon | PSPF_PowDouble | PSPF_CVarFast | PSPF_Flip | PSPF_Mirror, true);
            S7_A_FireBullets ('S7_LaserPewPew_Tracer', spread: (.2, .2), offs: (10, -4.5, 4.5), bonusDMGFactor: invoker.GetDamageBonus ());
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, -2.75, 2.75));

            TakeInventory (SecondMagClass, 1);

            A_ZoomFactor (invoker.GetZoomFactor () * .996);
            S7_Recoil (-0.38);

            return ResolveState (null);
        }
        TNT1 A 1 {
            A_ZoomFactor (invoker.GetZoomFactor () * .998);
            S7_Recoil (-0.07);
        }
        TNT1 A 1 {
            A_ZoomFactor (invoker.GetZoomFactor ());
            S7_Recoil (-0.07);
        }
        TNT1 A 1;
        TNT1 A 1 A_JumpIf (invoker.CheckButton (CB_Down, BT_AltAttack), "AkimboLeft.Fire");
        goto AkimboLeft.Ready;

    // Dryfiring
    AkimboRight.DryFire:
        TNT1 A 3 {
            S7_SetRightAnim ("AnimAkimbo.Idle");
            A_PlaySound ("Weapons/LaserPewPew/DryFire", CHAN_6);
        }
        TNT1 A 0 {
            // Check the opposite ammo, if there's none, we can go ahead and reload
            if (!CheckInventory (SecondMagClass, 1) && S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload ())
                GiveInventory ("S7_Reloading", 1);
        }
        goto AkimboRight.Ready;
    AkimboLeft.DryFire:
        TNT1 A 3 {
            S7_SetLeftAnim ("AnimAkimbo.Idle");
            A_PlaySound ("Weapons/LaserPewPew/DryFire", CHAN_7);
        }
        TNT1 A 0 {
            // Check the opposite ammo, if there's none, we can go ahead and reload
            if (!CheckInventory (FirstMagClass, 1) && S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload ())
                GiveInventory ("S7_Reloading", 1);
        }
        goto AkimboLeft.Ready;

    // Reloading
    AkimboRight.Reload:
        TNT1 A 0 {
            TakeInventory ('S7_Reloading', 0x7FFFFFFF);

            // Get the ammo amounts.
            int mag1 = CountInv (FirstMagClass),
                mag2 = CountInv (SecondMagClass);
            int mag1Req = S7_LaserPewPew.MagSize - mag1,
                mag2Req = S7_LaserPewPew.MagSize - mag2;
            int ammoPool = CountInv ('S7_FBSysCells');

            // Cancel if both are full or there's no spare ammo.
            if (mag1Req + mag2Req <= 0 || ammoPool <= 0)
                return ResolveState ("AkimboRight.ReloadEnd");

            if (mag1Req + mag2Req > ammoPool) { // If not enough ammo to top both off.
                int ammoGiven = 0, ammoToGive = 0;

                // Return if both require the same amount and there's less than 2 ammo.
                if (mag1Req == mag2Req && ammoPool < 2) // If they require the same amount and there's less than 2 ammo.
                    return ResolveState ("AkimboRight.ReloadEnd");

                // Equalize the mags.
                if (mag1Req != mag2Req) {
                    int ammoDiff = abs (mag1Req - mag2Req); // Get the difference.
                    ammoToGive = ((ammoDiff > ammoPool) ? ammoPool : AmmoDiff); // Make sure the given amount isn't greater than the available amount.
                    GiveInventory ((mag1Req - mag2Req > 0) ? FirstMagClass : SecondMagClass, ammoToGive); // Give the ammo.
                    ammoGiven += ammoToGive;
                }

                // If there's enough ammo, split it between the mags.
                if (ammoPool - ammoGiven > 1) {
                    ammoToGive = ammoPool - ammoGiven;
                    ammoToGive = ((ammoToGive & 1) ? ammoToGive - 1 : AmmoToGive) / 2;  // Calculate the amount to give.
                    GiveInventory (FirstMagClass, ammoToGive); // Give the ammo.
                    GiveInventory (SecondMagClass, ammoToGive);
                    ammoGiven += ammoToGive * 2;
                }

                TakeInventory ('S7_FBSysCells', ammoGiven); // Take the ammo from the ammo pool.
            } else {
                GiveInventory (FirstMagClass, mag1Req);
                GiveInventory (SecondMagClass, mag2Req);
                TakeInventory ('S7_FBSysCells', mag1Req + mag2Req);
            }

            // Mark which should be reloaded in the animation.
            invoker.reloadRight = mag1 != CountInv ( FirstMagClass);
            invoker.reloadLeft  = mag2 != CountInv (SecondMagClass);

            return ResolveState ("AkimboRight.ReloadAnim");
        }
    AkimboRight.ReloadAnim:
        TNT1 A 1 {
            S7_SetRightAnim ("AnimAkimbo.Idle");
            S7_SetLeftAnim ("AnimAkimbo.Idle");

            if (invoker.reloadRight)
                A_PlaySound ("Weapons/LaserPewPew/Out", CHAN_5);
        }
        TNT1 A 2 {
            if (invoker.reloadLeft)
                A_PlaySound ("Weapons/LaserPewPew/Out", CHAN_6);
        }
    AkimboRight.ReloadAnim_ReloadRight:
        TNT1 A 0 A_JumpIf (!invoker.reloadRight, "AkimboRight.ReloadAnim_ReloadLeft");
        TNT1 A 6 S7_SetLeftAnim ("AnimAkimbo.Deselect");
        TNT1 A 4;
        TNT1 A 18 S7_SetRightAnim ("AnimAkimbo.Reload");
        TNT1 A 4;
        TNT1 A 6 S7_SetLeftAnim ("AnimAkimbo.Select");
        TNT1 A 2;
    AkimboRight.ReloadAnim_ReloadLeft:
        TNT1 A 0 A_JumpIf (!invoker.reloadLeft, "AkimboRight.ReloadEnd");
        TNT1 A 6 S7_SetRightAnim ("AnimAkimbo.Deselect");
        TNT1 A 4;
        TNT1 A 18 S7_SetLeftAnim ("AnimAkimbo.Reload");
        TNT1 A 2;
        TNT1 A 6 S7_SetRightAnim ("AnimAkimbo.Select");
        TNT1 A 4;
        goto AkimboRight.ReloadEnd;
    AkimboRight.ReloadEnd:
        TNT1 A 0 S7_SetLeftAction ("AkimboLeft.Ready");
        goto AkimboRight.Ready;
    }
}