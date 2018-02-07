class S7_WeapBindsSystem : Inventory {
    const NUM_WEAPON_SLOTS = 10;

    // The actual weapon binds.
    Array<S7_BaseWeapon> Binds [10];
    // The weapon binds for the Draco
    Array<S7_BaseWeapon> DracoBinds [4];
    // The maximum amount of weapons in a slot.
    int SlotMaximum [10];
    // The last selected weapon;
    S7_BaseWeapon LastWeapon;

    override void AttachToOwner (Actor other) {
        super.AttachToOwner (other);

        for (int i = 0; i < 10; i++) {
            Binds [i].Clear ();
            if (i < 4)
                DracoBinds [i].Clear ();

            SlotMaximum [i] = ((i > 0 && i <= 5) ? 1 : 0);
        }
    }

    clearscope S7_BaseWeapon GetBind (int slot, int pos, bool draco = false) {
        if (slot < 0 || pos < 0 || pos >= Binds [slot].Size ())
            return NULL;

        Array<S7_BaseWeapon> weapons;

        if (!draco) weapons.Copy (     Binds [slot]);
        else        weapons.Copy (DracoBinds [slot]);

        let weap = weapons [pos];
        weapons.Clear ();

        return weap;
    }

    clearscope bool BindUsed (int slot, int pos, bool draco = false) {
        if (slot < 0 || pos < 0 || pos >= Binds [slot].Size ())
            return false;

        Array<S7_BaseWeapon> weapons;

        if (!draco) weapons.Copy (     Binds [slot]);
        else        weapons.Copy (DracoBinds [slot]);

        bool ret = weapons [pos] != NULL;
        weapons.Clear ();

        return ret;
    }

    // Finds the slot and index of a weapon
    clearscope int, int LocateWeapon (S7_BaseWeapon weap, bool draco = false) {
        int i, j;

        for (i = 0; i < NUM_WEAPON_SLOTS; i++) {
            j = (!draco ? (Binds [i].Find (weap)) : (DracoBinds [i].Find (weap)));

            if (j != (!draco ? (Binds [i].Size ()) : (DracoBinds [i].Size ())))
                return i, j;
        }

        return -1, -1;
    }

    // Checks if a weapon is bound
    clearscope bool WeaponBound (S7_BaseWeapon weap, bool draco = false) {
        int x, y;
        [x, y] = LocateWeapon (weap, draco);

        return (x >= 0 && y >= 0);
    }

    // Finds the weapon most recently used
    clearscope int, int FindMostRecentWeapon (bool draco = false) {
        PlayerInfo player = PlayerPawn (Owner).player;

        if (player.PendingWeapon != WP_NOCHANGE) {
            let weap = S7_BaseWeapon (player.PendingWeapon);

            if (!weap)
                return -1, -1;
            return LocateWeapon (weap, draco);
        } else if (player.ReadyWeapon) {
            let weap = S7_BaseWeapon (player.ReadyWeapon);
            if (!weap) return -1, -1;

            int slot, index;
            [slot, index] = LocateWeapon (weap, draco);
            if (!slot) { // If the current weapon wasn't found and is powered up, look for its non-powered up version.
                if (weap.bPowered_Up && weap.SisterWeapon) {
                    weap = S7_BaseWeapon (weap.SisterWeapon);
                    if (!weap)
                        return -1, -1;
                    return LocateWeapon (weap, draco);
                } else
                    return -1, -1;
            }

            return slot, index;
        } else
            return -1, -1;
    }

    // Picks the next weapon in the specified slot
    S7_BaseWeapon PickWeapon (uint slot, bool checkAmmo = false, bool draco = false) {
        PlayerInfo player = PlayerPawn (Owner).player;
        Array<S7_BaseWeapon> weapons;

        if (slot < 0 || slot > 9) // Return if the slot number is out of bounds.
            return S7_BaseWeapon (player.ReadyWeapon);
        if ((!draco && Binds [slot].Size () < 1) || (draco && DracoBinds [slot].Size () < 1)) // Return if the slot is empty
            return S7_BaseWeapon (player.ReadyWeapon);

        if (!draco) weapons.Copy (     Binds [slot]);
        else        weapons.Copy (DracoBinds [slot]);

        int i, j;
        if (player.ReadyWeapon) {
            for (i = 0; i < weapons.Size (); i++) {
                if (weapons [i] == player.ReadyWeapon || (player.ReadyWeapon.bPowered_Up && player.ReadyWeapon.SisterWeapon == weapons [i])) {
                    j = (i == 0 ? weapons.Size () - 1 : i - 1);
                    for (; j != i; j = (j == 0 ? weapons.Size () - 1 : j - 1))
                        if (weapons [j] && weapons [j] is "Weapon" && (!checkAmmo || weapons [j].CheckAmmo (weapon.EitherFire, false)))
                            return weapons [j];
                }
            }
        }
        for (i = weapons.Size () - 1; i >= 0; i--)
            if (weapons [i] && weapons [i] is "Weapon" && (!checkAmmo || weapons [i].CheckAmmo (weapon.EitherFire, false)))
                return weapons [i];

        return S7_BaseWeapon (player.ReadyWeapon);
    }

    // Cycles through all the slots and weapons
    S7_BaseWeapon CycleWeapons (bool prev, bool checkAmmo = false, bool draco = false) {
        PlayerInfo player = PlayerPawn (Owner).player;
        int startSlot, startIndex;
        int slotsChecked = 0;

        [startSlot, startIndex] = FindMostRecentWeapon (draco);
        if (!player.ReadyWeapon || (startSlot >= 0 && startIndex >= 0)) {
            int slot, index;

            if (!player.ReadyWeapon) {
                startSlot = !prev ? (NUM_WEAPON_SLOTS - 1) : 0;
                if (!draco) startIndex = !prev ? (     Binds [startSlot].Size () - 1) : 0;
                else        startIndex = !prev ? (DracoBinds [startSlot].Size () - 1) : 0;
            }

            slot = startSlot;
            index = startIndex;
            Array<S7_BaseWeapon> weapons;
            if (!draco) weapons.Copy (     Binds [slot]);
            else        weapons.Copy (DracoBinds [slot]);
            do {
                if (!prev) {
                    if (++index >= (!draco ? (Binds [slot].Size ()) : (DracoBinds [slot].Size ()))) {
                        index = 0;
                        slotsChecked++;
                        if (++slot >= NUM_WEAPON_SLOTS)
                            slot = 0;

                        weapons.Clear ();
                        if (!draco) weapons.Copy (     Binds [slot]);
                        else        weapons.Copy (DracoBinds [slot]);
                    }
                } else {
                    if (--index < 0) {
                        slotschecked++;
                        if (--slot < 0)
                            slot = NUM_WEAPON_SLOTS - 1;
                        index = (!draco ? (Binds [slot].Size ()) : (DracoBinds [slot].Size ())) - 1;

                        weapons.Clear ();
                        if (!draco) weapons.Copy (     Binds [slot]);
                        else        weapons.Copy (DracoBinds [slot]);
                    }
                }

                if (index >= 0 && index < weapons.Size ()) {
                    let weap = weapons [index];
                    if (weap && weap.CheckAmmo (Weapon.EitherFire, false))
                        return weap;
                }
            }
            while ((slot != startSlot || index != startIndex) && slotsChecked <= NUM_WEAPON_SLOTS);
        }

        return S7_BaseWeapon (player.ReadyWeapon);
    }

    void SetBind (int slot, int pos, S7_BaseWeapon weap, bool draco = false) {
        if (slot < 0 || pos < 0 || (!weap && pos >= (!draco ? (Binds [slot].Size ()) : (DracoBinds [slot].Size ()))))
            return;

        if (!weap) {
            if (!draco) Binds [slot].Delete (pos, 1);
            else   DracoBinds [slot].Delete (pos, 1);
            return;
        }

        if (pos >= Binds [slot].Size ()) {
            if (!draco) Binds [slot].Push (weap);
            else   DracoBinds [slot].Push (weap);
        } else {
            if (!draco) {
                Binds [slot].Delete (pos, 1);
                Binds [slot].Insert (pos, weap);
            } else {
                DracoBinds [slot].Delete (pos, 1);
                DracoBinds [slot].Insert (pos, weap);
            }
        }
    }
}