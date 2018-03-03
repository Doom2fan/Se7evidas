class S7_BaseS7HUD : BaseStatusBar {
    int GetStamina (bool max) {
        let dracoPlayer = S7_DracoPlayer (CPlayer.mo);

        if (max) {
            if (!dracoPlayer) return GetMaxAmount ("S7_Stamina");
            else return 500;
        } else {
            if (!dracoPlayer) return GetAmount ("S7_Stamina");
            else return dracoPlayer.defenseMatrixEnergy;
        }
    }

    /** Armor stuff **/
    int GetS7ArmorAmount () {
        let armor = CPlayer.mo.FindInventory ("S7_BasicArmor");
        return armor ? armor.Amount : 0;
    }

    int GetS7ArmorSaveAmount () {
        let armor = S7_BasicArmor (CPlayer.mo.FindInventory ("S7_BasicArmor"));
        return armor ? armor.ActualSaveAmount : 0;
    }
}