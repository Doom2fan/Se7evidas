extend class S7_BasePlayer {
    static const string StatNames [] = {
        "strength",
        "agility",
        "vitality",
        "defense",
        "will",
        "magic",
        "tech"
    };

    override void CheatGive (String name, int amount) {
        let player = self.player;

        if (player.mo == NULL || player.health <= 0)
            return;

        int giveall = ALL_NO;
        if (name ~== "all")
            giveall = ALL_YES;
        else if (name ~== "everything")
            giveall = ALL_YESYES;

        if (giveall == ALL_YESYES || name ~== "levels") {
            xpSys.GiveXP (int.max);

            if (!giveall)
                return;
        }

        if (giveall == ALL_YESYES || name ~== "attrPoints") {
            xpSys.attrPoints += amount;

            if (!giveall)
                return;
        }

        for (int i = 0; i < StatNames.Size (); i++) {
            if (name ~== StatNames [i]) {
                xpSys.SetStat (i + 1, amount, true);

                return;
            }
        }

        if (giveall || name ~== "weapons") {
            let savedpending = player.PendingWeapon;
            for (int i = 0; i < AllActorClasses.Size (); ++i) {
                let type = (class<S7_BaseWeapon>) (AllActorClasses [i]);
                if (type != null && type != "S7_BaseWeapon") {
                    // Don't give replaced weapons unless the replacement was done by Dehacked.
                    let rep = GetReplacement (type);
                    if (rep == type || rep is "DehackedPickup") {
                        readonly<S7_BaseWeapon> def = GetDefaultByType (type);
                        if (giveall == ALL_YESYES || !def.bCheatNotWeapon)
                            GiveInventory (type, 1, true);
                    }
                }
            }
            player.PendingWeapon = savedpending;

            if (!giveall)
                return;
        }

        Super.CheatGive (name, amount);
    }
}