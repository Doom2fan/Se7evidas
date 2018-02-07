/** Perfect Hatred **/
class S7_MEATW_EyesCounter : S7_Boolean { }
class S7_MEATW_Eyes : S7_EffectsBase {
    default {
        scale 0.1;
        tag "";

        +noGravity +cannotPush +noTeleport +isMonster
        +noDamage +invulnerable +forceXYBillboard
    }

    states {
    Spawn:
        TNT1 A 0 noDelay GiveInventory ("S7_NotRealMonster", 1);
    Idle:
        MATW A 1 bright; // A_RadiusGive ("S7_MEATW_EyesCounter", 128.0, RGF_Players, 1);
        loop;
    Death:
    GoAway:
        MATW A 1 bright A_FadeOut (0.2);
        loop;
    }
}