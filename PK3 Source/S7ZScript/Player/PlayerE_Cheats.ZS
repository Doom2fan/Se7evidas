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

        Super.CheatGive (name, amount);
    }
}