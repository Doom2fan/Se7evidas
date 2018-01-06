//-------------------------------------------------------------------------------------------
//
// XP System
//
//-------------------------------------------------------------------------------------------
class S7_PlayerXPSystem : S7_XPSystem {
    default {
        S7_XPSystem.canLevelUp true;

        +inventory.invBar
        inventory.icon "PISTA0";
    }

    int attrPoints;

    override bool Use (bool pickup) {
        Menu.SetMenu ('S7_XPSystemMenu');
        return false;
    }

    void LevelUpMessage (int lvl, int attrPts, string message = "", bool additional = true) {
        if (!Owner)
            return;

        PlayerInfo p = players [consoleplayer];
        let pPawn = S7_BasePlayer (Owner);

        if (p && p == pPawn.Player) {
            CVar msgsOn = CVar.GetCvar ("S7_MsgsOn", pPawn.Player);
            CVar logMsgsCVar = CVar.GetCvar ("S7_LogLVLUpMsgs", pPawn.Player);
            bool logMsgs = logMsgsCVar && logMsgsCVar.GetBool ();

            if (msgsOn && msgsOn.GetInt ()) {
                S7_HudMessage.ShowFade (consoleplayer, "Level up!", 1, (0.5, 0.5), 35 * 3, 7, 10, alignment: S7_HudMessage.AlignCenter, color: Font.CR_UNTRANSLATED, fnt: "BigFont");

                if (message != "" && !additional)
                    S7_HudMessage.ShowFade (consoleplayer, message, 2, (0.5, 0.55), 35 * 3, 7, 10,
                        flags: logMsgs ? S7_HudMessage.MSG_Log : 0, alignment: S7_HudMessage.AlignCenter, color: Font.CR_UNTRANSLATED, fnt: "SmallFont");
                else {
                    S7_HudMessage.ShowFade (consoleplayer, String.Format ("You've reached level %d.\nYou have gained %d attribute points.", lvl, attrPts), 2, (0.5, 0.55), 35 * 3, 7, 10,
                        flags: logMsgs ? S7_HudMessage.MSG_Log : 0, alignment: S7_HudMessage.AlignCenter, color: Font.CR_UNTRANSLATED, fnt: "SmallFont");

                    if (message != "")
                        S7_HudMessage.ShowFade (consoleplayer, message, 2, (0.5, 0.6), 35 * 3, 7, 10,
                            flags: logMsgs ? S7_HudMessage.MSG_Log : 0, alignment: S7_HudMessage.AlignCenter, color: Font.CR_UNTRANSLATED, fnt: "SmallFont");
                }
            }
        }

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
        int oldAttrPoints = attrPoints;

        switch (level) {
        default:
            attrPoints += 4;
            break;
        }

        LevelUpMessage (level, attrPoints - oldAttrPoints, message, additional);
    }
}