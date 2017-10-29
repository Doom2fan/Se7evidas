//-------------------------------------------------------------------------------------------
//
// Player event handler
//
//-------------------------------------------------------------------------------------------
class S7_PlayerEventHandler : EventHandler {
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

        SplitResult strings;
        strings = S7_Extensions.Split (e.Name, ":");

        if (strings.Result.Size () < 2) // Return if the array has less than two strings
            return;

        if (strings.Result [0] == "S7_Keys") {
            let pPawn = players [e.Player].mo;

            if (strings.Result [1] == "Melee")
                pPawn.SetInventory ("S7_DoMelee", 1);
            else if (strings.Result [1] == "FiringMode")
                pPawn.SetInventory ("S7_ChangeFireMode", 1);
        } else if (strings.Result [0] == "S7_WeapBindsSystem")
            WeapBindsSystem (e);
    }

    void WeapBindsSystem (ConsoleEvent e) {
        PlayerInfo player = players [e.Player];
        let weapBinds = S7_WeapBindsSystem (player.mo.FindInventory ("S7_WeapBindsSystem"));

        if (!weapBinds) // Return if weapBinds is null
            return;

        SplitResult commandStrings;
        commandStrings = S7_Extensions.Split (e.Name, ":");
        if (commandStrings.Result.Size () < 2) // Return if the array contains less than two strings
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