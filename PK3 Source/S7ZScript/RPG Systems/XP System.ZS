//-------------------------------------------------------------------------------------------
//
// XP System
//
//-------------------------------------------------------------------------------------------
class S7_XP_System_Experience : S7_Counter { default { inventory.maxAmount 0x7FFFFFFF; } }
class S7_XPSystemWorker : Inventory {
    const BaseXPGoal = 2500;

    default {
        inventory.maxAmount 1;
        inventory.interHubAmount 1;

        +inventory.undroppable +inventory.untossable
        //-inventory.invBar
        +inventory.invBar
        inventory.icon "PISTA0";
    }

    int level;
    int attrPoints;
    int strengthStat, agilityStat, vitalityStat, defenseStat, willStat, magicStat, techStat;

    override bool Use (bool pickup) {
        Menu.SetMenu ('S7_XPSystemMenu');
        return false;
    }

    void LevelUpMessage (int level, int attrPoints, string message = "", bool additional = true) {
        if (!Owner)
            return;

        PlayerInfo p = players [consoleplayer];
        let pPawn = PlayerPawn (Owner);

        /*if (p && p == pPawn.Player) {
            CVar msgsOn = CVar.GetCvar ("S7_MsgsOn", pPawn.Player);

            if (msgsOn && msgsOn.GetInt ()) {
                let sBar = Se7evidasStatusBar (StatusBar);
                sBar.AttachToPlayer (p);

                sBar.DrawString (sBar.mBigFont, "Level up!", (0, 0), BaseStatusBar.DI_SCREEN_CENTER | BaseStatusBar.DI_TEXT_ALIGN_CENTER | BaseStatusBar.DI_NOSHADOW, Font.CR_UNTRANSLATED);
                //sBar.

                if (message != "" && !additional)
                    sBar.DrawString (sBar.mSmallFont, message, (0, -10), BaseStatusBar.DI_SCREEN_CENTER | BaseStatusBar.DI_TEXT_ALIGN_CENTER | BaseStatusBar.DI_NOSHADOW, Font.CR_UNTRANSLATED);
                else {
                    sBar.DrawString (sBar.mSmallFont, String.Format ("You've reached level %d.\nYou have gained %d attribute points.", lvl, attrPts),
                        (0, -10), BaseStatusBar.DI_SCREEN_CENTER | BaseStatusBar.DI_TEXT_ALIGN_CENTER | BaseStatusBar.DI_NOSHADOW, Font.CR_UNTRANSLATED);

                    if (message != "" && additional)
                        sBar.DrawString (sBar.mSmallFont, message, (0, -18), BaseStatusBar.DI_SCREEN_CENTER | BaseStatusBar.DI_TEXT_ALIGN_CENTER | BaseStatusBar.DI_NOSHADOW, Font.CR_UNTRANSLATED);
                }
            }
        }*/

        if (Owner)
            Owner.A_PlaySound ("Player/LevelUp", CHAN_UI);
    }

    override void DoEffect () {
        let pPawn = PlayerPawn (Owner);

        if (!pPawn)
            return;

        int reqXP = BaseXPGoal * (1.0 + 2 * level),
            nextLevel = level + 1;

        if (pPawn.CountInv ("S7_XP_System_Experience") >= reqXP && level < S7_MaxLevel) {
            switch (nextLevel) {
            default:
                LevelUpMessage (nextLevel, attrPoints);
                level = nextLevel;
                attrPoints += 4;
                pPawn.TakeInventory ("S7_XP_System_Experience", reqXP);
                break;
            }
        }

        // Agility
        let staminaItem = pPawn.FindInventory ("S7_Stamina");
        if (staminaItem)
            staminaItem.maxAmount = 150 + 10 * agilityStat;

        // Vitality
        int baseHealth = 100;
        if (pPawn is "S7_ScoutPlayer")
            baseHealth = 75;
        pPawn.maxHealth = baseHealth * (1.0 + 0.06 * vitalityStat);

        // Defense
        pPawn.damageFactor = clamp (1.0 - (0.01 * defenseStat), 0.1, 1.0);

        // Magic
        let manaItem = pPawn.FindInventory ("S7_Mana");
        if (manaItem)
            manaItem.maxAmount = 250 + 15 * magicStat;
    }
}