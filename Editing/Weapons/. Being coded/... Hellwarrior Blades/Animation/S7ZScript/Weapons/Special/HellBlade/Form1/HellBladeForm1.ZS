class S7_HellhunterBladeForm1 : S7_BaseWeapon {
    default {
        tag "$HELLBLADE";
        inventory.pickupMessage "$HELLBLADE";
        weapon.ammoUse 0;
        weapon.ammoGive 0;
    }

    // Temporary stuff
    int comboCounter;
    bool specialActive;

    override void DetachFromOwner () {
        comboCounter = 0;
        specialActive = false;
    }

    states {
    Spawn:
        HWBP A -1;
        loop;

    Ready:
        TNT1 A    1;
        HB11 DCBA 1;
    Ready2:
        TNT1 A 0 {
            TakeInventory ("S7_Reloading", 0x7FFFFFFF);
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");

            A_WeaponReady ();
            invoker.comboCounter = 0;

            if (invoker.specialActive) {
                int frame = (level.totaltime / 3) % 4;

                if (frame <= 0) return ResolveState ("Ready2.SpcFrame1");
                if (frame == 1) return ResolveState ("Ready2.SpcFrame2");
                if (frame == 2) return ResolveState ("Ready2.SpcFrame3");
                if (frame >= 3) return ResolveState ("Ready2.SpcFrame4");
            }

            return ResolveState ("Ready2.Normal");
        }
    Ready2.Normal:    HB11 A 1; goto Ready2;
    Ready2.SpcFrame1: HB13 A 1; goto Ready2;
    Ready2.SpcFrame2: HB13 B 1; goto Ready2;
    Ready2.SpcFrame3: HB13 C 1; goto Ready2;
    Ready2.SpcFrame4: HB13 D 1; goto Ready2;

    Deselect:
        HB11 A    0 A_JumpIf (invoker.specialActive, "Deselect.Special");
        HB11 ABCD 1;
        TNT1 A    1;
        goto TrueDeselect;
    Deselect.Special:
        HB13 A   1;
        HB14 LMN 1;
        TNT1 A   1;
        goto TrueDeselect;

    Fire:
        HB11 A   1 {
            if (invoker.comboCounter == 1)
                return ResolveState ("Fire2");
            else if (invoker.comboCounter == 2)
                return ResolveState ("Fire4");

            return invoker.specialActive ? ResolveState ("Fire.Special") : ResolveState (null);
        }
        HB11 ABCD 1;
        goto Fire1;
    Fire.Special:
        HB13 A   1;
        HB14 LMN 1;
        goto Fire1;

    Fire1:
        HB11 EF   1;
        HB11 G    1 A_JumpIf (invoker.specialActive, "Fire1.Special");
        HB11 H    1 A_PlaySound ("Weapons/HHunterBladeF1/Swing", CHAN_Weapon);
        HB11 IJK  1;
        HB11 L    1 A_CustomPunch (callACS ("S7_HellBladeDMG", HELLBLADE_FORM1, random [weaponDamage] (1, 3), 20), TRUE, 0, "S7_HBForm1_Puff", 112.0);
        HB11 MNOP 1;
        goto Fire.ContinueCombo;
    Fire1.Special:
        HB13 E    1;
        HB13 F    1 A_PlaySound ("Weapons/HHunterBladeF1/Swing", CHAN_Weapon);
        HB13 GHI  1;
        HB13 J    1 A_CustomPunch (callACS ("S7_HellBladeDMG", HELLBLADE_FORM1, random [weaponDamage] (1, 3), 20), TRUE, 0, "S7_HBForm1_PuffSpc", 112.0);
        HB13 KLMN 1;
        HB13 OP   1;
        goto Fire.ContinueCombo;

    Fire2:
        HB11 X    1 A_Jump (128, "Fire3");
        HB11 Y    1 {
            A_PlaySound ("Weapons/HHunterBladeF1/Swing", CHAN_Weapon);
            return invoker.specialActive ? ResolveState ("Fire2.Special") : ResolveState (null);
        }
        HB11 Z    1;
        HB12 A    1;
        HB12 B    1 A_CustomPunch (callACS ("S7_HellBladeDMG", HELLBLADE_FORM1, random [weaponDamage] (1, 3), 20), TRUE, 0, "S7_HBForm1_Puff", 112.0);
        HB12 CDEF 1;
        goto Fire.ContinueCombo;
    Fire2.Special:
        HB13 T   1;
        HB13 U   1;
        HB13 V   1;
        HB13 W   1 A_CustomPunch (callACS ("S7_HellBladeDMG", HELLBLADE_FORM1, random [weaponDamage] (1, 3), 20), TRUE, 0, "S7_HBForm1_PuffSpc", 112.0);
        HB13 XYZ 1;
        HB14 A   1;
        goto Fire.ContinueCombo;

    Fire3:
        HB12 G     1 A_JumpIf (invoker.specialActive, "Fire3.Special");
        HB12 H     1 A_PlaySound ("Weapons/HHunterBladeF1/Swing", CHAN_Weapon);
        HB12 IJ    1;
        HB12 K     1 A_CustomPunch (callACS ("S7_HellBladeDMG", HELLBLADE_FORM1, random [weaponDamage] (1, 3), 20), TRUE, 0, "S7_HBForm1_Puff", 112.0);
        HB12 LMNOP 1;
        goto Fire.ContinueCombo;
    Fire3.Special:
        HB14 B     1;
        HB14 C     1 A_PlaySound ("Weapons/HHunterBladeF1/Swing", CHAN_Weapon);
        HB14 DE    1;
        HB14 F     1 A_CustomPunch (callACS ("S7_HellBladeDMG", HELLBLADE_FORM1, random [weaponDamage] (1, 3), 20), TRUE, 0, "S7_HBForm1_PuffSpc", 112.0);
        HB14 GHIJK 1;
        goto Fire.ContinueCombo;

    Fire4:
        //TNT1 A      0 A_JumpIf (invoker.specialActive, "Fire4.Special");
        HB11 Q      1 A_PlaySound ("Weapons/HHunterBladeF1/Swing", CHAN_Weapon);
        HB11 S      1;
        HB11 U      1 A_CustomPunch (callACS ("S7_HellBladeDMG", HELLBLADE_FORM1, random [weaponDamage] (1, 3), 35), TRUE, 0, "S7_HBForm1_PuffStab", 112.0);
        HB11 UUTSRQ 1;
        TNT1 A     15;
        goto Fire.End;
    Fire4.Special:
        HB13 O      1 A_PlaySound ("Weapons/HHunterBladeF1/Swing", CHAN_Weapon);
        HB13 Q      1;
        HB13 S      1 A_CustomPunch (callACS ("S7_HellBladeDMG", HELLBLADE_FORM1, random [weaponDamage] (1, 3), 35), TRUE, 0, "S7_HBForm1_PuffSpc", 112.0);
        HB13 SSRQPO 1;
        TNT1 A     15;
        goto Fire.End;

    Fire.ContinueCombo:
        TNT1 A               1 { invoker.comboCounter++; }
        TNT1 AAAAAAAAAAAAAAA 1 A_WeaponReady (WRF_NoBob | WRF_NoSecondary | WRF_NoSwitch);
    Fire.End:
        HB11 D 1 {
            invoker.comboCounter = 0;
            return invoker.specialActive ? ResolveState ("Fire.EndSpecial") : ResolveState (null);
        }
        HB11 CBA 1;
        goto Ready2;
    Fire.EndSpecial:
        HB14 NML 1;
        HB13 A   1;
        goto Ready2;

    AltFire:
        HB11 A    2 {
            if (invoker.specialActive)
                return ResolveState ("CancelSpecial");
            if (CheckInventory ("S7_HellhunterBladeLust", 5))
                return ResolveState ("Ready2");

            A_SetBlend ("7F0000", 1.0, 2);

            return ResolveState (null);
        }
        HB11 BCD  1;
        HB14 N    1 {
            invoker.specialActive = true;
            A_SetBlend ("000000", 0.0,  3);
        }
        HB14 ML   1;
        goto Ready2;
    CancelSpecial:
        HB13 A   2 A_SetBlend ("7F0000", 1.0, 2);
        HB14 LMN 1;
        HB11 D   1 {
            invoker.specialActive = false;
            A_SetBlend ("000000", 0.0,  3);
        }
        HB11 CBA 1;
        goto Ready2;
    }
}

class S7_HBForm1_Puff : S7_HBPuff_Base {
    default {
        renderStyle "add";
        scale 0.05;
        seeSound "Weapons/HHunterBladeF1/Hit";
        attackSound "Weapons/HHunterBladeF1/HitWall";
    }

    states {
    Crash:
        SPRK A 2 bright {
            for (int i = 0; i < 6; i++) {
                A_SpawnItemEx ("S7_BulletPuffSparks", 0.0, 0.0, 0.0, fRandom [sfx] (0.0, 2.0), fRandom [sfx] (-2.0, 2.0), fRandom [sfx] (1.5, 4.0), 0, SXF_Clientside);
                A_SpawnItemEx ("S7_BulletPuffSmoke", 0.0, 0.0, 0.0, 0.0, fRandom [sfx] (-1.0, 1.0), fRandom [sfx] (-0.8, 0.8), 0, SXF_Clientside);
            }
        }
        SPRK A 2 bright;
        stop;
    }
}

class S7_HBForm1_PuffSpc : S7_HBForm1_Puff {
    default {
        damageType "SpecialFire";
        deathType "Fire";

        -noExtremeDeath
    }
}

class S7_HBForm1_PuffStab : S7_HBForm1_Puff { default { seeSound "Weapons/HHunterBladeF1/Stab"; } }