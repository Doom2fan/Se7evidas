//-------------------------------------------------------------------------------------------
//
// Infiltrator playerclass
//
//-------------------------------------------------------------------------------------------
class S7_InfiltratorPlayer : S7_ScoutPlayer {
    default {
        // Movement
        Player.JumpZ 9.55; // Not quite as good at jumping as scouts

        // Class stuff
        Player.DisplayName "$S7_INFILTRATORPLAYER";

        // Misc
        Radius 15; // Can fit into smaller spaces
    }

    override void GiveBasics_ClassSpecific () {
        GiveInventory ("S7_DaggerMelee", 1);
        GiveInventory ("S7_MultiJump_Max", 1); // Scouts can do double jumps from the start
        // Equipment
        GiveInventory ("S7_Stimpack", 3);
        GiveInventory ("S7_Medikit", 1);
        // Ammo
        GiveInventory ("S7_TEC9Clip", 32);
        GiveInventory ("S7_ManxCarbineClip", 23);
        GiveInventory ("S7_9mmCartridges", 6 * 23);

        GiveBasics_GiveStartingWeapon ("S7_TEC9");
        let manx = GiveBasics_GiveStartingWeapon ("S7_ManxCarbine");
        // The TEC9 and the Manx should start out suppressed, but mods aren't in yet.

        weapBinds.LastWeapon = manx;
        player.PendingWeapon = manx;
    }
}