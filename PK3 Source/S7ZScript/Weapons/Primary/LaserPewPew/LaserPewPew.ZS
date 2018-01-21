//-------------------------------------------------------------------------------------------
//
// FS/909G "Butterfly" SMG
//
//-------------------------------------------------------------------------------------------
class S7_LaserPewPewClip : ammo {
    default {
        inventory.maxAmount S7_LaserPewPew.MagSize;
        ammo.backpackMaxAmount S7_LaserPewPew.MagSize;

        +inventory.ignoreSkill
    }
}
class S7_LaserPewPewClipSecond : ammo {
    default {
        inventory.maxAmount S7_LaserPewPew.MagSize;
        ammo.backpackMaxAmount S7_LaserPewPew.MagSize;

        +inventory.ignoreSkill
    }
}

class S7_LaserPewPewSecond : S7_Boolean { } // This one stays as an inventory token because we don't want it to be removed if the gun is removed or dropped.
class S7_LaserPewPew : S7_BaseWeapon {
    const MagSize = 32;

    default {
        tag "$BUTTFLY";
        inventory.pickupMessage "$BUTTFLY";
        weapon.ammoType1 "S7_LaserPewPewClip";
        weapon.ammoType2 "S7_FBSysCells";
        weapon.ammoUse 1;
        weapon.ammoGive 0;
        S7_BaseWeapon.Icon "BLSPA0";
        S7_BaseWeapon.ShortTag "$SHORTBUTTFLY";
        S7_BaseWeapon.BindSlot WpSlot_Light;
    }

    bool akimbo, sights;

    states {
    Spawn:
        BLSP A -1;
        loop;

    /** Normal mode **/
    Ready:
        BLSG V     1 A_JumpIf (invoker.akimbo, "Ready.Akimbo");
        BLSG WXYZA 1;
    Ready2:
        BLSG A 0 A_JumpIf (invoker.sights, "Ready2.Sights");
        goto Ready2.DoThings;
    Ready2.Sights:
        BLSG K 0;
        goto Ready2.DoThings;
    Ready2.DoThings:
        #### # 1 {
            if (invoker.akimbo)
                return ResolveState ("AkimboRight.Ready");

            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (!invoker.sights) {
                if (CheckInventory ("S7_DoMelee", 1))
                    return ResolveState ("QuickMelee");
                if (CheckInventory ("S7_ChangeFireMode", 1))
                    return ResolveState ("ChangeMode");
            } else {
                TakeInventory ("S7_DoMelee", 0x7FFFFFFF);
                TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);
            }

            A_WeaponReady (WRF_AllowZoom | WRF_NoSecondary);

            return ResolveState (null);
        }
        #### # 0 TakeInventory ("S7_HoldingZoom", 0x7FFFFFFF);
        goto Ready2;
    Ready2.HoldingZoom:
        #### # 1 A_WeaponReady (WRF_NoFire | WRF_NoSwitch | WRF_AllowZoom);
        goto Ready2;

    ChangeMode:
        BLSG A   2 {
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            if (!CheckInventory ("S7_LaserPewPewSecond", 1))
                return ResolveState ("Ready2");
            if (invoker.akimbo)
                return ResolveState ("ChangeMode.ToSingle");

            invoker.akimbo = true;
            return ResolveState (null);
        }
        BLSG DEF 2;
        BLS2 A   7 {
            A_Overlay (2, "AkimboLeft.Select");
        }
        goto AkimboRight.Ready;
    ChangeMode.ToSingle:
        BLS2 A    7 {
            invoker.akimbo = false;
            A_Overlay (2, "AkimboLeft.Deselect");
        }
        BLSG FEDA 2;
        goto Ready2;

    Deselect:
        BLSG A 1 {
            if (invoker.sights)
                return ResolveState ("Deselect.Sights");
            if (invoker.akimbo)
                return ResolveState ("AkimboRight.Deselect");

            return ResolveState (null);
        }

        BLSG ZYXWV 1;
        goto TrueDeselect;
    Deselect.Sights:
        BLSG K   1 { invoker.sights = false; }
        BLSG N   1 {
            A_ZoomFactor (1.0);
            A_SetCrosshair (0);
        }
        BLSG MLA 1;
        goto Deselect;

    Fire:
        BLSG A 1 {
            if (invoker.akimbo)
                return ResolveState ("AkimboRight.Fire");
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_AlertMonsters ();
            A_PlaySound ("Weapons/LaserPewPew/Fire", CHAN_Weapon);

            if (invoker.sights)
                return ResolveState ("Fire.Sights");

            A_GunFlash ("Flash");
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2.5, 3);
            A_FireProjectile ("S7_LaserPewPew_Tracer", fRandom [weaponSpread] (-0.2, 0.2), 1, 6, -2, 0, fRandom [weaponSpread] (-0.2, 0.2));

            A_SetPitch (pitch - 0.38, SPF_Interpolate);

            return ResolveState (null);
        }
        BLSG C 1 A_SetPitch (pitch - 0.07, SPF_Interpolate);
        BLSG B 1 A_SetPitch (pitch - 0.07, SPF_Interpolate);
        BLSG A 1;
        BLSG A 1 A_Refire ("Fire");
        goto Ready2;
    Fire.Sights:
        BLSG K 1 {
            A_GunFlash ("Flash.Sights");
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 0, 4);
            A_FireProjectile ("S7_LaserPewPew_Tracer", fRandom [weaponSpread] (-0.2, 0.2), 1, 0, -1, 0, fRandom [weaponSpread] (-0.2, 0.2));

            A_ZoomFactor (1.270);
            A_SetPitch (pitch - 0.38, SPF_Interpolate);
            //A_SetAngle (angle - 0.5 * random [weaponSpc] (-1, 1), SPF_Interpolate);

            return ResolveState (null);
        }
        BLSG O 1 {
            A_ZoomFactor (1.2725);
            A_SetPitch (pitch - 0.07, SPF_Interpolate);
        }
        BLSG P 1 {
            A_ZoomFactor (1.275);
            A_SetPitch (pitch - 0.07, SPF_Interpolate);
        }
        BlSG K 1;
        BLSG K 1 A_Refire ("Fire");
        goto Ready2;

    DryFire:
        BLSG A 0 A_JumpIf (invoker.sights, "DryFire.Sights");
        goto DryFire.End;
    DryFire.Sights:
        BLSG K 0;
        goto DryFire.End;
    DryFire.End:
        #### # 3 A_PlaySound ("Weapons/LaserPewPew/DryFire", CHAN_7);
        #### # 0 {
            if (CheckInventory ("S7_LaserPewPewSecond", 1) && CheckInventory ("S7_LaserPewPewClipSecond", 1))
                return ResolveState ("Reload.SwapGuns");

            if (S7_PlayerCVar.GetInt (player, "S7_AutoReloading"))
                return ResolveState ("Reload");

            return ResolveState (null);
        }
        goto Ready2;

    Zoom:
        #### # 1 {
            if (invoker.akimbo) {
                invoker.sights = false;
                A_ZoomFactor (1.0);
                A_SetCrosshair (0);
                return ResolveState ("AkimboRight.Ready");
            }

            if (CheckInventory ("S7_HoldingZoom", 1))
                return ResolveState ("Ready2.HoldingZoom");

            GiveInventory ("S7_HoldingZoom", 1);

            if (invoker.sights)
                return ResolveState ("Unzoom");

            invoker.sights = true;
            A_SetCrosshair (99);
            A_ZoomFactor (1.275);

            return ResolveState (null);
        }

        BLSG ALMNK 1;
        goto Ready2.HoldingZoom;
    Unzoom:
        BLSG K    1 {
            invoker.sights = false;
            A_ZoomFactor (1.0);
            A_SetCrosshair (0);
        }
        BLSG NMLA 1;
        goto Ready2.HoldingZoom;

    Reload.Sights:
        BLSG K    1 {
            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1))
                return ResolveState ("Ready2");

            invoker.sights = false;
            A_SetCrosshair (0);
            A_ZoomFactor (1.0);

            return ResolveState (null);
        }
        BLSG NMLA 1;
        goto Reload;
    Reload:
        TNT1 A 0 {
            TakeInventory ("S7_Reloading", 1);

            if (invoker.sights)
                return ResolveState ("Reload.Sights");

            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1))
                return ResolveState ("Ready2");

            int ammoAmount = min (FindInventory (invoker.ammoType1).maxAmount - CountInv (invoker.ammoType1), CountInv (invoker.ammoType2));
            if (ammoAmount <= 0)
                return ResolveState ("Ready2");

            GiveInventory (invoker.ammoType1, ammoAmount);
            TakeInventory (invoker.ammoType2, ammoAmount);

            return ResolveState ("ReloadFinish");
        }
    ReloadFinish:
        BLSG ADEFF   2;
        BLSG F      15 A_PlaySound ("Weapons/LaserPewPew/Out", CHAN_6);
        BLSG GHI     2;
        BLSG I       2 A_PlaySound ("Weapons/LaserPewPew/In", CHAN_7);
        BLSG IIJEDAA 2;
        goto Ready2;
    Reload.SwapGuns: // Gun swapping
        BLSG AZYXWV 1;
        TNT1 A      5 {
            int mag1 = CountInv ("S7_LaserPewPewClip"), mag2 = CountInv ("S7_LaserPewPewClipSecond");
            SetInventory ("S7_LaserPewPewClip", mag2);
            SetInventory ("S7_LaserPewPewClipSecond", mag1);
        }
        BLSG VWXYZA 1;
        goto Ready2;

    // Muzzle flashes
    Flash:
        BLSG U 1 bright;
        stop;
    Flash.Sights:
        BLSG T 1 bright;
        stop;

    /** Akimbo mode **/
    Ready.Akimbo:
        BLS2 ZYXWVU 1;
        BLS2 U      1 {
            A_Overlay (2, "AkimboLeft.Ready");
            A_OverlayFlags (2, PSPF_AddWeapon | PSPF_AddBob | PSPF_PowDouble | PSPF_CVarFast | PSPF_Flip | PSPF_Mirror, true);
        }
    AkimboRight.Ready:
        BLS2 A 1 {
            if (!CheckInventory ("S7_LaserPewPewSecond", 1))
                return ResolveState ("AkimboRight.NoSecLPP");
            if (!invoker.akimbo)
                return ResolveState ("AkimboRight.Derped");

            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("AkimboRight.Reload");
            if (CheckInventory ("S7_ChangeFireMode", 1))
                return ResolveState ("ChangeMode");
            TakeInventory ("S7_DoMelee", 0x7FFFFFFF);

            A_WeaponReady (WRF_NoSecondary | WRF_DisableSwitch);

            return ResolveState (null);
        }
        goto AkimboRight.Ready;
    AkimboLeft.Ready:
        BLS2 A 1 {
            if (!CheckInventory ("S7_LaserPewPewSecond", 1))
                return ResolveState ("AkimboLeft.NoSecLPP");
            if (!invoker.akimbo)
                return ResolveState ("AkimboLeft.Derped");

            if ((player.cmd.buttons & BT_ALTATTACK) && !(player.oldbuttons & BT_ALTATTACK))
                return ResolveState ("AkimboLeft.Fire");

            return ResolveState (null);
        }
        goto AkimboLeft.Ready;

    AkimboRight.Deselect:
        BLS2 L    1 {
            A_Overlay (2, "AkimboLeft.DeselectReal");
            A_OverlayFlags (2, PSPF_AddWeapon | PSPF_AddBob | PSPF_PowDouble | PSPF_CVarFast | PSPF_Flip | PSPF_Mirror, true);
        }
        BLS2 MNOP 1;
        goto Super::Deselect;
    AkimboLeft.DeselectReal:
        BLS2 LMNOP 1;
        //BLS2 GHIJK 1;
        stop;

    AkimboLeft.Select:
        BLS2 K      1 A_OverlayFlags (2, PSPF_AddWeapon | PSPF_AddBob | PSPF_PowDouble | PSPF_CVarFast, true);
        BLS2 KJIHGD 1;
        BLS2 D      1;
        TNT1 A      0 A_OverlayFlags (2, PSPF_AddWeapon | PSPF_AddBob | PSPF_PowDouble | PSPF_CVarFast | PSPF_Flip | PSPF_Mirror, true);
        goto AkimboLeft.Ready;
    AkimboLeft.Deselect:
        BLS2 D      1 A_OverlayFlags (2, PSPF_AddWeapon | PSPF_AddBob | PSPF_PowDouble | PSPF_CVarFast, true);
        BLS2 DGHIJK 1;
        BLS2 K      1;
        stop;

    AkimboRight.Fire:
        BLS2 A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("AkimboRight.DryFire");

            A_GunFlash ("Flash");
            A_AlertMonsters ();
            A_PlaySound ("Weapons/LaserPewPew/Fire", CHAN_Weapon);

            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2.5, 3);
            A_FireProjectile ("S7_LaserPewPew_Tracer", fRandom [weaponSpread] (-0.2, 0.2), 1, 6, -2, 0, fRandom [weaponSpread] (-0.2, 0.2));

            A_SetPitch (pitch - 0.38, SPF_Interpolate);

            return ResolveState (null);
        }
        BLS2 C 1 A_SetPitch (pitch - 0.07, SPF_Interpolate);
        BLS2 B 1 A_SetPitch (pitch - 0.07, SPF_Interpolate);
        BLS2 A 1;
        BLS2 A 1 A_Refire ("AkimboRight.Fire");
        goto AkimboRight.Ready;
    AltFire:
    AkimboLeft.Fire:
        BLS2 A 1 {
            if (!CheckInventory ("S7_LaserPewPewClipSecond", 1))
                return ResolveState ("AkimboLeft.Dryfire");

            A_Overlay (1001, "Flash");
            A_OverlayFlags (1001, PSPF_AddWeapon | PSPF_AddBob | PSPF_PowDouble | PSPF_CVarFast | PSPF_Flip | PSPF_Mirror, true);
            A_AlertMonsters ();
            A_PlaySound ("Weapons/LaserPewPew/Fire", CHAN_Weapon);

            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, -2.5, 3);
            A_FireProjectile ("S7_LaserPewPew_Tracer", fRandom [weaponSpread] (-0.2, 0.2), 0, -6, -2, 0, fRandom [weaponSpread] (-0.2, 0.2));
            TakeInventory ("S7_LaserPewPewClipSecond", 1);

            A_SetPitch (pitch - 0.38, SPF_Interpolate);

            return ResolveState (null);
        }
        BLS2 C 1 A_SetPitch (pitch - 0.07, SPF_Interpolate);
        BLS2 B 1 A_SetPitch (pitch - 0.07, SPF_Interpolate);
        BLS2 A 1;
        BLS2 A 1 A_JumpIf (player.cmd.buttons & BT_ALTATTACK, "AkimboLeft.Fire");
        goto AkimboLeft.Ready;

    AkimboRight.Dryfire:
        BLS2 A 7 A_PlaySound ("Weapons/LaserPewPew/DryFire", CHAN_7);
        TNT1 A 0 {
            if (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && !CheckInventory ("S7_LaserPewPewClipSecond", 1)) // Check the opposite ammo, if there's none, we can go ahead and reload
                return ResolveState ("AkimboRight.Reload");
            return ResolveState (null);
        }
        goto AkimboRight.Ready;
    AkimboLeft.Dryfire:
        BLS2 A 7 A_PlaySound ("Weapons/LaserPewPew/DryFire", CHAN_6);
        TNT1 A 0 {
            if (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && !CheckInventory ("S7_LaserPewPewClip", 1))
                return ResolveState ("AkimboLeft.Reload");
            return ResolveState (null);
        }
        goto AkimboLeft.Ready;

    AkimboLeft.Reload:
        TNT1 A 0 GiveInventory ("S7_Reloading", 1);
        goto AkimboLeft.Ready;
    AkimboRight.Reload:
        TNT1 A 0 {
            TakeInventory ("S7_Reloading", 0x7FFFFFFF);

            int mag1 = CountInv ("S7_LaserPewPewClip"), mag2 = CountInv ("S7_LaserPewPewClipSecond"),
                mag1Req = S7_LaserPewPew.MagSize - mag1, mag2Req = S7_LaserPewPew.MagSize - mag2,
                ammoPool = CountInv ("S7_FBSysCells");

            if (mag1Req + mag2Req <= 0 || ammoPool <= 0)
                return ResolveState (null);

            if (mag1Req + mag2Req > ammoPool) { // If not enough ammo to top both off
                int ammoGiven = 0, ammoToGive = 0;

                if (mag1Req == mag2Req && ammoPool < 2) // If they require the same amount and there's less than 2 ammo.
                    return ResolveState (null);

                // Equalize the mags
                if (mag1Req != mag2Req) {
                    int ammoDiff = abs (mag1Req - mag2Req); // Get the difference
                    ammoToGive = ((ammoDiff > ammoPool) ? ammoPool : ammoDiff); // Make sure the given amount isn't greater than the available amount
                    GiveInventory ((mag1Req - mag2Req > 0) ? "S7_LaserPewPewClip" : "S7_LaserPewPewClipSecond", ammoToGive); // Give the ammo
                    ammoGiven += ammoToGive;
                }

                // If there's enough ammo, split it between the mags
                if (ammoPool - ammoGiven > 1) {
                    ammoToGive = ammoPool - ammoGiven;
                    ammoToGive = ((ammoToGive & 1) ? ammoToGive - 1 : ammoToGive) / 2;  // Calculate the amount to give
                    GiveInventory ("S7_LaserPewPewClip", ammoToGive); // Give the ammo
                    GiveInventory ("S7_LaserPewPewClipSecond", ammoToGive);
                    ammoGiven += ammoToGive * 2;
                }

                TakeInventory ("S7_FBSysCells", ammoGiven); // Take the ammo from the ammo pool
            } else {
                GiveInventory ("S7_LaserPewPewClip", mag1Req);
                GiveInventory ("S7_LaserPewPewClipSecond", mag2Req);
                TakeInventory ("S7_FBSysCells", mag1Req + mag2Req);
            }

            return ResolveState ("AkimboRight.ReloadAnim");
        }
        goto AkimboRight.Ready;
    AkimboRight.ReloadAnim:
        BLS2 A     3 {
            A_Overlay (2, "AkimboLeft.ReloadAnim");
            A_OverlayFlags (2, PSPF_AddWeapon | PSPF_AddBob | PSPF_PowDouble | PSPF_CVarFast, true);
            A_PlaySound ("Weapons/LaserPewPew/Out", CHAN_6);
        }
        BLS2 AAAAA 1; // Left buttfly lower
        BLS2 A     2; // Start right clip insert
        BLSG G     2 A_PlaySound ("Weapons/LaserPewPew/In", CHAN_7);
        BLSG HIIJJ 2;
        BLSG IHG   2; // Finish right clip insert
        BLS2 A     2;
        BLS2 LMNOP 1; // Right buttfly lower
        TNT1 A     2;
        TNT1 A     2;
        TNT1 AAAAA 2;
        TNT1 AAA   2; // Finish left clip insert
        BLS2 PONML 1;
        BLS2 A     3;
        goto AkimboRight.Ready;

    AkimboLeft.ReloadAnim:
        BLS2 D     3 A_PlaySound ("Weapons/LaserPewPew/Out", CHAN_5);
        BLS2 GHIJK 1; // Left buttfly lower
        TNT1 A     2; // Start right clip insert
        TNT1 A     2;
        TNT1 AAAAA 2;
        TNT1 AAA   2; // Finish right clip insert
        TNT1 A     2;
        BLS2 KJIHG 1; // Right buttfly lower
        BLS2 D     2; // Start left clip insert
        BLS2 Q     2 A_PlaySound ("Weapons/LaserPewPew/In", CHAN_7);
        BLS2 RSSTT 2;
        BLS2 SRQ   2; // Finish left clip insert
        BLS2 DDDDD 1;
        BLS2 D     3;
        TNT1 A     0 A_OverlayFlags (2, PSPF_AddWeapon | PSPF_AddBob | PSPF_PowDouble | PSPF_CVarFast | PSPF_Flip | PSPF_Mirror, true);
        goto AkimboLeft.Ready;

    AkimboRight.Derped:
        BLS2 A    8;
        BLSG FEDA 2;
        goto Ready2;
    AkimboRight.NoSecLPP:
        TNT1 A 0 { invoker.akimbo = false; }
        goto Ready2;

    AkimboLeft.Derped:
        BLS2 GHIJK 1;
        TNT1 A     1;
        stop;
    AkimboLeft.NoSecLPP:
        TNT1 A 0 { invoker.akimbo = false; }
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Tracer
//
//-------------------------------------------------------------------------------------------
class S7_LaserPewPew_Tracer : S7_BaseTracer {
    default {
        damageFunction (fRandom [weaponDamage] (1.0, 4.25) * 8);
        S7_BaseTracer.trueSpeed 310;
        damageType "LaserTracer";
        scale 0.0125;
        missileType "S7_LaserPewPew_Tracer_Trail";
        decal "S7_LaserPewPewDecal";

        -bloodSplatter
    }

    states {
    Idle:
        BLSF A 1 bright;
        wait;

    Death:
    Crash:
        TNT1 A 0 A_FaceTarget;
        TNT1 A 3; //A_SpawnItemEx ("S7_LaserPewPew_Puff")
        stop;
    XDeath:
        TNT1 A 3;
        stop;
    }
}

class S7_LaserPewPew_Tracer_Trail : S7_TracerEffectsBase {
    default {
        scale 0.0125;
    }

    states {
    Spawn:
        BLSF A 1 bright;
    Loople:
        "----" A 1 bright A_FadeOut (0.2);
        wait;
    }
}