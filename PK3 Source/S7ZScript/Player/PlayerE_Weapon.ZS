extend class S7_BasePlayer {
    static const string PermanentWeapons [] = {
        "S7_GrenadeWeap",
        "S7_BerserkWeap"
    };

    void Weapon_PermanentWeapons () {
        for (int i = 0; i < PermanentWeapons.Size (); i++) {
            let weap = PermanentWeapons [i];

            if (!CheckInventory (weap, 1))
                GiveInventory (weap, 1);
        }
    }

    const BaseAmmoMax = 6.0;
    void Weapon_SetAmmoMax () {
        double ammoMax = BaseAmmoMax;

        if (CheckInventory ("S7_BackpackToken", 1))
            ammoMax += 2.0;

        if (ammoMax != playerData.ammoMaxMult) { // Only update if it changed...
            for (int i = 0; i < S7_WeapData.AmmoTypesData.Size (); i++) {
                Array<String> res;
                S7_WeapData.AmmoTypesData [i].Split (res, ":");
                if (res.Size () != 2) // Uhhh... Should always equal two exactly...
                    continue;

                Ammo ammoInv = Ammo (FindInventory (res [0]));
                int maxAmount = floor (res [1].ToInt () * ammoMax);

                if (ammoInv)
                    ammoInv.maxAmount = maxAmount;
                else {
                    ammoInv = Ammo (GiveInventoryType (res [0]));
                    if (ammoInv) {
                        ammoInv.maxAmount = maxAmount;
                        ammoInv.amount = 0;
                    }
                }
            }
        }

        playerData.ammoMaxMult = ammoMax;
    }
}