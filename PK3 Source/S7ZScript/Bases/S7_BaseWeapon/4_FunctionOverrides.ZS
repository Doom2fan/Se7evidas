/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2019 Chronos "phantombeta" Ouroboros
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

extend class S7_BaseWeapon {
    override void AttachToOwner (Actor other) { // Override this so we can disable selection on pickup
        StateProvider.AttachToOwner (other);

        Ammo1 = AddAmmo (Owner, AmmoType1, AmmoGive1);
        Ammo2 = AddAmmo (Owner, AmmoType2, AmmoGive2);
        SisterWeapon = AddWeapon (SisterWeaponType);
        if (Owner.player != null) {
            if (Owner.player.mo == players [consoleplayer].camera)
                StatusBar.ReceivedWeapon (self);
        }
        GivenAsMorphWeapon = false; // Will be set explicitly by morphing code
    }

    override void DetachFromOwner () {
        let weapBinds = S7_WeapBindsSystem (Owner.FindInventory ('S7_WeapBindsSystem'));
        if (!weapBinds)
            return;

        int slot, pos;

        [slot, pos] = weapBinds.LocateWeapon (self, false);
        if (slot > -1 && pos > -1)
            weapBinds.SetBind (slot, pos, null, false);

        [slot, pos] = weapBinds.LocateWeapon (self, true);
        if (slot > -1 && pos > -1)
            weapBinds.SetBind (slot, pos, null, true);
    }

    override bool Use (bool pickup) { // Override Use so it can't be used to bypass the weapon limits
        if (!(Owner is 'S7_BasePlayer'))
            return false;

        let pPawn = S7_BasePlayer (Owner);
        if (!pPawn)
            return false;

        if (!pPawn.selectedWeapon)
            return false;

        bool ret = Super.Use (pickup);
        pPawn.selectedWeapon = false;
        return ret;
    }

    override Inventory CreateTossable (int amt) {
        // If self actor lacks a SpawnState, don't drop it. (e.g. A base weapon
        // like the fist can't be dropped because you'll never see it.)
        if (SpawnState == GetDefaultByType ('Actor').SpawnState || SpawnState == null)
            return null;
        if (bUndroppable || bUntossable || Owner == null || Amount <= 0)
            return null;

        // Will pretty much always be true, but ehhh...
        if (Owner && Owner.player && Owner.player.ReadyWeapon == self) {
            int weapState = Owner.player.WeaponState;

            if (!(weapState & WF_WeaponSwitchOK))
                return null;
            if (weapState & WF_DisableSwitch)
                return null;
        }

        amt = 1; // Never drop more than one instance of a weapon

        if (Amount == 1 && !bKeepDepleted) {
            let ammo1Act = Ammo1;

            BecomePickup ();
            DropTime = 30;
            bSpecial = bSolid = false;

            if (usesMag) {
                ammo1Act.BecomePickup ();
                self.AddInventory (ammo1Act);
            }

            return self;
        }

        let copy = Inventory (Spawn (GetClass (), Owner.Pos, NO_REPLACE));
        if (copy != null) {
            copy.MaxAmount = MaxAmount;
            copy.Amount = amt;
            copy.DropTime = 30;
            copy.bSpecial = copy.bSolid = false;
            Amount -= amt;
        }

        return copy;
    }

    override double GetSpeedFactor () {
        if (!Owner || Owner.player.ReadyWeapon != self)
            return 1.;

        let xpSys = GetOwnerXPSystem ();

        double strengthStat = (xpSys ? xpSys.GetStat (S7Stat_Strength) : 0.);
        double berserkCount = Owner.CountInv ("S7_BerserkToken");

        if (berserkCount < 1) {
            let pPawn = S7_BasePlayer (Owner);
            if (pPawn && pPawn.playerData)
                berserkCount = clamp (-(.2 * pPawn.playerData.bsrkAddiction), -1., 0.);
        }

        return S7_WeightSpeedModifier (strengthStat, berserkCount);
    }
}