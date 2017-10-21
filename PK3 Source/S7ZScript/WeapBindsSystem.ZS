class S7_WeapBindsSystem : Inventory {
    const NUM_WEAPON_SLOTS = 10;

    // The actual weapon binds.
    Array<S7_BaseWeapon> Binds [10];
    // The maximum amount of weapons in a slot.
    int SlotMaximum [10];
    // The last selected weapon;
    S7_BaseWeapon LastWeapon;

    override void AttachToOwner (Actor other) {
        super.AttachToOwner (other);

        for (int i = 0; i < 10; i++) {
            Binds [i].Clear ();
            SlotMaximum [i] = ((i > 0 && i <= 5) ? 1 : 0);
        }

        if (Owner.player != NULL) {
            S7_BaseWeapon weap;

            if (Owner is "S7_ScoutPlayer")
                weap = S7_TEC9 (Owner.FindInventory ("S7_TEC9"));

            if (weap)
                Binds [2].Push (weap);

            LastWeapon = weap;
        }
    }

    // Finds the slot and index of a weapon
    int, int LocateWeapon (S7_BaseWeapon weap) {
        int i, j;

        for (i = 0; i < NUM_WEAPON_SLOTS; i++) {
            j = Binds [i].Find (weap);

            if (j != Binds [i].Size ())
                return i, j;
        }

        return -1, -1;
    }

    // Finds the weapon most recently used
    int, int FindMostRecentWeapon () {
        PlayerInfo player = PlayerPawn (Owner).player;

        if (player.PendingWeapon != WP_NOCHANGE) {
            let weap = S7_BaseWeapon (player.PendingWeapon);

            if (!weap)
                return -1, -1;
            return LocateWeapon (weap);
        } else if (player.ReadyWeapon) {
            let weap = S7_BaseWeapon (player.ReadyWeapon);
            if (!weap) return -1, -1;

            int slot, index;
            [slot, index] = LocateWeapon (weap);
            if (!slot) { // If the current weapon wasn't found and is powered up, look for its non-powered up version.
                if (weap.bPowered_Up && weap.SisterWeapon) {
                    weap = S7_BaseWeapon (weap.SisterWeapon);
                    if (!weap)
                        return -1, -1;
                    return LocateWeapon (weap);
                } else
                    return -1, -1;
            }

            return slot, index;
        } else
            return -1, -1;
    }

    // Picks the next weapon in the specified slot
    S7_BaseWeapon PickWeapon (uint slot, bool checkAmmo = false) {
        PlayerInfo player = PlayerPawn (Owner).player;
        Array<S7_BaseWeapon> weapons;

        if (slot < 0 || slot > 9) // Return if the slot number is out of bounds.
            return S7_BaseWeapon (player.ReadyWeapon);
        if (Binds [slot].Size () < 1) // Return if the slot is empty
            return S7_BaseWeapon (player.ReadyWeapon);

        weapons.Copy (Binds [slot]);

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
    S7_BaseWeapon CycleWeapons (bool prev, bool checkAmmo = false) {
        PlayerInfo player = PlayerPawn (Owner).player;
        int startSlot, startIndex;
        int slotsChecked = 0;

        [startSlot, startIndex] = FindMostRecentWeapon ();
        if (!player.ReadyWeapon || (startSlot >= 0 && startIndex >= 0)) {
            int slot, index;

            if (!player.ReadyWeapon) {
                startSlot = !prev ? (NUM_WEAPON_SLOTS - 1) : 0;
                startIndex = !prev ? (Binds [startSlot].Size () - 1) : 0;
            }

            slot = startSlot;
            index = startIndex;
            Array<S7_BaseWeapon> weapons;
            weapons.Copy (Binds [slot]);
            do {
                if (!prev) {
                    if (++index >= Binds [slot].Size ()) {
                        index = 0;
                        slotsChecked++;
                        if (++slot >= NUM_WEAPON_SLOTS)
                            slot = 0;

                        weapons.Clear ();
                        weapons.Copy (Binds [slot]);
                    }
                } else {
                    if (--index < 0) {
                        slotschecked++;
                        if (--slot < 0)
                            slot = NUM_WEAPON_SLOTS - 1;
                        index = Binds [slot].Size () - 1;

                        weapons.Clear ();
                        weapons.Copy (Binds [slot]);
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
}

class S7_WeapBindsSystem_EventHandler : EventHandler {
    static const String KeyBindsCCMDs [] = {
        "slot 1", "slot 2", "slot 3", "slot 4", "slot 5",
        "slot 6", "slot 7", "slot 8", "slot 9", "slot 0",
        "weapnext", "weapprev"
    };
    static const String KeyBindsNetEvents [] = {
        "slot:1", "slot:2", "slot:3", "slot:4", "slot:5",
        "slot:6", "slot:7", "slot:8", "slot:9", "slot:0",
        "next", "prev"
    };

    override bool InputProcess (InputEvent e) {
        if (e.Type != InputEvent.Type_KeyDown)
            return false;

        int bind1, bind2;
        for (int i = 0; i < 12; i++) {
            [bind1, bind2] = Bindings.GetKeysForCommand (KeyBindsCCMDs [i]);

            if (e.KeyScan == bind1 || e.KeyScan == bind2) {
                EventHandler.SendNetworkEvent (String.Format ("S7_WeapBindsSystem:%s", KeyBindsNetEvents [i]));
                return true;
            }
        }

        return false;
    }

    override void NetworkProcess (ConsoleEvent e) {
        if (e.Player < 0) // Don't execute this if the player isn't given/valid
            return;
        if (!playeringame [e.Player] || !players [e.Player].mo) // Don't execute if the player isn't ingame, the player is null or the player's PlayerPawn is null
            return;

        PlayerInfo player = players [e.Player];
        let weapBinds = S7_WeapBindsSystem (player.mo.FindInventory ("S7_WeapBindsSystem"));
        if (!weapBinds) // Return if weapBinds is null
            return;

        SplitResult commandStrings;
        commandStrings = S7_Extensions.Split (e.Name, ":");
        if (commandStrings.Result.Size () < 2 || commandStrings.Result [0] != "S7_WeapBindsSystem") // Return if the array contains less than two strings or the first string isn't "S7_WeapBindsSystem"
            return;

        if (commandStrings.Result [1] == "slot") {
            if (commandStrings.Result.Size () < 3) // Return if the array contains less than 3 strings
                return;

            int slot = commandStrings.Result [2].ToInt ();
            if (slot < 0 || slot > 9)
                return;

            S7_BaseWeapon weapon = weapBinds.PickWeapon (slot, false);

            if (player.ReadyWeapon != weapon) {
                player.PendingWeapon = weapon;
                weapBinds.LastWeapon = weapon;
            }
        } else if (commandStrings.Result [1] == "next") {
            S7_BaseWeapon weapon = weapBinds.CycleWeapons (false, false);

            if (player.ReadyWeapon != weapon) {
                player.PendingWeapon = weapon;
                weapBinds.LastWeapon = weapon;
            }
        } else if (commandStrings.Result [1] == "prev") {
            S7_BaseWeapon weapon = weapBinds.CycleWeapons (true, false);

            if (player.ReadyWeapon != weapon) {
                player.PendingWeapon = weapon;
                weapBinds.LastWeapon = weapon;
            }
        } else if (commandStrings.Result [1] == "test") {
            for (int i = 1; i <= 5; i++)
                weapBinds.SlotMaximum [i] = 3;

            // Medium
            player.mo.GiveInventory ("S7_AK47", 1);
            player.mo.GiveInventory ("S7_Fauchard", 1);
            player.mo.GiveInventory ("S7_SSG", 1);
            weapBinds.Binds [1].Push (S7_BaseWeapon (player.mo.FindInventory ("S7_AK47")));
            weapBinds.Binds [1].Push (S7_BaseWeapon (player.mo.FindInventory ("S7_Fauchard")));
            weapBinds.Binds [1].Push (S7_BaseWeapon (player.mo.FindInventory ("S7_SSG")));
            // Light
            player.mo.GiveInventory ("S7_Revolver", 1);
            player.mo.GiveInventory ("S7_HitterSMG", 1);
            player.mo.GiveInventory ("S7_LaserPewPew", 1);
            weapBinds.Binds [2].Clear ();
            weapBinds.Binds [2].Push (S7_BaseWeapon (player.mo.FindInventory ("S7_Revolver")));
            weapBinds.Binds [2].Push (S7_BaseWeapon (player.mo.FindInventory ("S7_HitterSMG")));
            // Heavy
            player.mo.GiveInventory ("S7_ConquerorRifle", 1);
            player.mo.GiveInventory ("S7_Thumper", 1);
            weapBinds.Binds [3].Push (S7_BaseWeapon (player.mo.FindInventory ("S7_ConquerorRifle")));
            weapBinds.Binds [3].Push (S7_BaseWeapon (player.mo.FindInventory ("S7_Thumper")));
            // Area-damage
            player.mo.GiveInventory ("S7_PrettyShootyIonCannonGun", 1);
            weapBinds.Binds [4].Push (S7_BaseWeapon (player.mo.FindInventory ("S7_PrettyShootyIonCannonGun")));
            // Special
            player.mo.GiveInventory ("S7_GrenadeWeap", 1);
            weapBinds.Binds [5].Push (S7_BaseWeapon (player.mo.FindInventory ("S7_GrenadeWeap")));
        }
    }
}