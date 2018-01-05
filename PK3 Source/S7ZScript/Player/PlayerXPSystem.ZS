//-------------------------------------------------------------------------------------------
//
// XP System
//
//-------------------------------------------------------------------------------------------
class S7_PlayerXPSystem : S7_XPSystem {
    default {
        +inventory.invBar
        inventory.icon "PISTA0";
    }

    int attrPoints;

    override bool Use (bool pickup) {
        Menu.SetMenu ('S7_XPSystemMenu');
        return false;
    }

    void LevelUpMessage (int level, int attrPoints, string message = "", bool additional = true) {
        if (!Owner)
            return;

        PlayerInfo p = players [consoleplayer];
        let pPawn = S7_BasePlayer (Owner);

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
        Super.DoEffect ();

        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn)
            return;

        // Agility
        let staminaItem = pPawn.FindInventory ("S7_Stamina");
        if (staminaItem)
            staminaItem.maxAmount = pPawn.GetMaxStamina ();

        // Vitality
        pPawn.maxHealth = pPawn.S7_GetMaxHealth ();

        // Defense
        pPawn.damageFactor = clamp (1.0 - (0.01 * GetStat (S7Stat_Defense)), 0.1, 1.0);

        // Magic
        let manaItem = pPawn.FindInventory ("S7_Mana");
        if (manaItem)
            manaItem.maxAmount = pPawn.GetMaxMana ();
    }

    override void OnLevelUp () {
        string message = "";
        bool additional = true;

        switch (level) {
        default:
            break;
        }

        LevelUpMessage (level, attrPoints, message, additional);
        attrPoints += 4;
    }
}