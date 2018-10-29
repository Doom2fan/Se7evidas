/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

class S7_SlotMaxUpgrade : Inventory {
    bool didUpgrade;
    meta int upgradeSlot;
    meta int upgradeAmount;

    property Slot: upgradeSlot;
    property Amount: upgradeAmount;

    default {
        Inventory.MaxAmount 1;

        S7_SlotMaxUpgrade.Slot -1;
        S7_SlotMaxUpgrade.Amount 1;
    }

    void DoSlotUpgrade (Actor other) {
        if (!other) {
            didUpgrade = false;
            return;
        }

        if (upgradeSlot < 0 || upgradeSlot > (S7_WeapBindsSystem.NUM_WEAPON_SLOTS - 1)) {
            Console.Printf ("Invalid weapon slot %d.", upgradeSlot);
            didUpgrade = true;
            return;
        }

        let weapBinds = S7_WeapBindsSystem (other.FindInventory ('S7_WeapBindsSystem'));
        if (!weapBinds) {
            didUpgrade = false;
            return;
        }

        weapBinds.SlotMaximum [upgradeSlot] = max (0, weapBinds.SlotMaximum [upgradeSlot] + upgradeAmount);

        didUpgrade = true;
    }

    override void AttachToOwner (Actor other) {
        Super.AttachToOwner (other);

        DoSlotUpgrade (other);
    }

    override void DoEffect () {
        Super.DoEffect ();

        if (!didUpgrade)
            DoSlotUpgrade (Owner);
    }

    override void DetachFromOwner () {
        Super.DetachFromOwner ();

        didUpgrade = false;
        if (!Owner)
            return;

        if (upgradeSlot < 0 || upgradeSlot > (S7_WeapBindsSystem.NUM_WEAPON_SLOTS - 1))
            return;

        let weapBinds = S7_WeapBindsSystem (Owner.FindInventory ('S7_WeapBindsSystem'));
        if (!weapBinds)
            return;

        weapBinds.SlotMaximum [upgradeSlot] = max (0, weapBinds.SlotMaximum [upgradeSlot] - upgradeAmount);
    }
}

class S7_WeapBindsSystem : Inventory {
    const NUM_WEAPON_SLOTS = 10;
    const NUM_WEAPON_SLOTS_DRACO = 4;

    // The actual weapon binds.
    Array<S7_BaseWeapon> Binds [NUM_WEAPON_SLOTS];
    // The weapon binds for the Draco
    Array<S7_BaseWeapon> DracoBinds [NUM_WEAPON_SLOTS_DRACO];
    // The maximum amount of weapons in a slot.
    int SlotMaximum [NUM_WEAPON_SLOTS];
    // The last selected weapon;
    S7_BaseWeapon LastWeapon;

    override void AttachToOwner (Actor other) {
        Super.AttachToOwner (other);

        for (int i = 0; i < NUM_WEAPON_SLOTS; i++) {
            Binds [i].Clear ();
            if (i < NUM_WEAPON_SLOTS_DRACO)
                DracoBinds [i].Clear ();

            if (i > 0 && i < 5)
                SlotMaximum [i] = 1;
            else if (i == 5)
                SlotMaximum [i] = 2;
            else
                SlotMaximum [i] = 0;
        }
    }

    override void DoEffect () {
        for (int i = 0; i < NUM_WEAPON_SLOTS; i++) {
            int j;
            while ((j = Binds [i].Find (null)) != Binds [i].Size ()) {
                Binds [i].Delete (j, 1);
            }

            if (Binds [i].Size () > SlotMaximum [i])
                Binds [i].Delete (SlotMaximum [i], 0x7FFFFFFF);
        }
    }

    clearscope int GetSlotMaximum (int slot, bool draco = false) {
        if (slot < (!draco ? 0 : 1) || slot > 9) return -1; // If slot is outside the range 0-9, return -1.

        if (draco)
            return (slot >= 1 && slot <= 4) ? 1 : -1;

        return SlotMaximum [slot];
    }

    clearscope int SlotCount (int slot, bool draco = false) {
        if (slot < (!draco ? 0 : 1) || slot > 9) return -1; // If slot is outside the range 0-9, return -1.

        if (draco)
            return (slot >= 1 && slot <= 4) ? DracoBinds [slot-1].Size () : -1;

        return Binds [slot].Size ();
    }

    clearscope S7_BaseWeapon GetBind (int slot, int pos, bool draco = false) {
        if (slot < (!draco ? 0 : 1) || pos < 0)
            return NULL;
        if (!draco && (slot > NUM_WEAPON_SLOTS-1 || pos >= Binds [slot].Size ()))
            return NULL;
        if (draco && (slot > NUM_WEAPON_SLOTS_DRACO || pos >= DracoBinds [slot-1].Size ()))
            return NULL;

        Array<S7_BaseWeapon> weapons;

        if (!draco) weapons.Copy (     Binds [slot]);
        else        weapons.Copy (DracoBinds [slot-1]);

        let weap = weapons [pos];
        weapons.Clear ();

        return weap;
    }

    clearscope bool BindUsed (int slot, int pos, bool draco = false) {
        if (slot < (!draco ? 0 : 1) || pos < 0)
            return false;
        if (!draco && (slot > NUM_WEAPON_SLOTS-1 || pos >= Binds [slot].Size ()))
            return false;
        if (draco && (slot > NUM_WEAPON_SLOTS_DRACO || pos >= DracoBinds [slot-1].Size ()))
            return false;

        Array<S7_BaseWeapon> weapons;

        if (!draco) weapons.Copy (     Binds [slot]);
        else        weapons.Copy (DracoBinds [slot-1]);

        bool ret = weapons [pos] != NULL;
        weapons.Clear ();

        return ret;
    }

    // Finds the slot and index of a weapon
    clearscope int, int LocateWeapon (S7_BaseWeapon weap, bool draco = false) {
        int i, j;
        int slotsCount = (!draco ? NUM_WEAPON_SLOTS : NUM_WEAPON_SLOTS_DRACO);

        for (i = 0; i < slotsCount; i++) {
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
            if (slot == -1) { // If the current weapon wasn't found and is powered up, look for its non-powered up version.
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
        if (slot < (!draco ? 0 : 1) || (!draco && slot > NUM_WEAPON_SLOTS-1) || (draco && slot > NUM_WEAPON_SLOTS_DRACO))
            return NULL;

        PlayerInfo player = PlayerPawn (Owner).player;
        Array<S7_BaseWeapon> weapons;

        if (slot < (!draco ? 0 : 1) || slot > 9) // Return if the slot number is out of bounds.
            return S7_BaseWeapon (player.ReadyWeapon);
        if ((!draco && Binds [slot].Size () < 1) || (draco && DracoBinds [slot-1].Size () < 1)) // Return if the slot is empty
            return S7_BaseWeapon (player.ReadyWeapon);

        if (!draco) weapons.Copy (     Binds [slot]);
        else        weapons.Copy (DracoBinds [slot-1]);

        int i, j;
        if (player.ReadyWeapon) {
            for (i = 0; i < weapons.Size (); i++) {
                if (weapons [i] == player.ReadyWeapon || (player.ReadyWeapon.bPowered_Up && player.ReadyWeapon.SisterWeapon == weapons [i])) {
                    j = (i == 0 ? weapons.Size () - 1 : i - 1);
                    for (; j != i; j = (j == 0 ? weapons.Size () - 1 : j - 1))
                        if (weapons [j] && weapons [j] is 'Weapon' && (!checkAmmo || weapons [j].CheckAmmo (weapon.EitherFire, false)))
                            return weapons [j];
                }
            }
        }
        for (i = weapons.Size () - 1; i >= 0; i--)
            if (weapons [i] && weapons [i] is 'Weapon' && (!checkAmmo || weapons [i].CheckAmmo (weapon.EitherFire, false)))
                return weapons [i];

        return S7_BaseWeapon (player.ReadyWeapon);
    }

    // Cycles through all the slots and weapons
    S7_BaseWeapon CycleWeapons (bool prev, bool checkAmmo = false, bool draco = false) {
        PlayerInfo player = PlayerPawn (Owner).player;
        int startSlot, startIndex;
        int slotsChecked = 0;
        int slotsCount = (!draco ? NUM_WEAPON_SLOTS : NUM_WEAPON_SLOTS_DRACO);

        [startSlot, startIndex] = FindMostRecentWeapon (draco);
        if (!player.ReadyWeapon || (startSlot >= 0 && startIndex >= 0)) {
            int slot, index;

            if (!player.ReadyWeapon) {
                startSlot = !prev ? (slotsCount - 1) : 0;
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
                    if (++index >= weapons.Size ()) {
                        index = 0;
                        slotsChecked++;
                        if (++slot >= slotsCount)
                            slot = 0;

                        weapons.Clear ();
                        if (!draco) weapons.Copy (     Binds [slot]);
                        else        weapons.Copy (DracoBinds [slot]);
                    }
                } else {
                    if (--index < 0) {
                        slotschecked++;
                        if (--slot < 0)
                            slot = slotsCount - 1;

                        weapons.Clear ();

                        if (!draco) weapons.Copy (     Binds [slot]);
                        else        weapons.Copy (DracoBinds [slot]);

                        index = weapons.Size () - 1;
                    }
                }

                if (index >= 0 && index < weapons.Size ()) {
                    let weap = weapons [index];
                    if (weap && weap.CheckAmmo (Weapon.EitherFire, false))
                        return weap;
                }
            } while ((slot != startSlot || index != startIndex) && slotsChecked <= slotsCount);
        }

        if (player.ReadyWeapon is 'S7_NullWeapon')
            return LastWeapon;
        else
            return S7_BaseWeapon (player.ReadyWeapon);
    }

    void SetBind (int slot, int pos, S7_BaseWeapon weap, bool draco = false) {
        if (slot < (!draco ? 0 : 1) || pos < 0 || (!weap && pos >= (!draco ? (Binds [slot].Size ()) : (DracoBinds [slot-1].Size ()))))
            return;

        if (!weap) {
            if (!draco) Binds [slot  ].Delete (pos, 1);
            else   DracoBinds [slot-1].Delete (pos, 1);
            return;
        }

        if (pos >= Binds [slot].Size ()) {
            if (!draco) Binds [slot  ].Push (weap);
            else   DracoBinds [slot-1].Push (weap);
        } else {
            if (!draco) {
                Binds [slot].Delete (pos, 1);
                Binds [slot].Insert (pos, weap);
            } else {
                DracoBinds [slot-1].Delete (pos, 1);
                DracoBinds [slot-1].Insert (pos, weap);
            }
        }
    }
}