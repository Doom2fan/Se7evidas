//-------------------------------------------------------------------------------------------
//
// Null weapons
//
//-------------------------------------------------------------------------------------------
class S7_NullWeapon : Weapon {
    default {
        Tag "Unarmed";

        +INVENTORY.UNDROPPABLE +WEAPON.WIMPY_WEAPON +WEAPON.CHEATNOTWEAPON +WEAPON.NOALERT
        +NOINTERACTION
    }

    states {
    Spawn:
        stop;

    Select:
        TNT1 A 0 A_Raise;
        wait;
    Deselect:
        TNT1 A 0 A_Lower;
        wait;
    Ready:
        TNT1 A 1 A_WeaponReady (WRF_NoFire | WRF_NoBob);
        loop;
    Fire:
        TNT1 A 1;
        goto Ready;
    }
}

class S7_SprintWeapon : S7_NullWeapon {
    states {
    Ready:
        TNT1 A 1 {
            let pData = S7_PlayerData (FindInventory ("S7_PlayerData"));

            bool sprinting = false;
            if (pData) sprinting = pData.sprinting;

            A_WeaponReady (WRF_NoFire | WRF_NoBob | (sprinting ? WRF_DisableSwitch : 0));
        }
        loop;
    }
}

class S7_LedgeGrabWeapon : S7_NullWeapon {
    states {
    Ready:
        TNT1 A 1 {
            let pData = S7_PlayerData (FindInventory ("S7_PlayerData"));

            bool grabbed = false;
            if (pData) grabbed = pData.lGrabGrabbed;

            A_WeaponReady (WRF_NoFire | WRF_NoBob | (grabbed ? WRF_DisableSwitch : 0));
        }
        loop;
    }
}