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

//-------------------------------------------------------------------------------------------
//
// XP System
//
//-------------------------------------------------------------------------------------------
class S7_PlayerXPSystem : S7_XPSystem {
    default {
        S7_XPSystem.CanLevelUp true;
    }

    int attrPoints;

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
                S7_HudMessageFade.Show (consoleplayer, "Level up!", 1, (0.5 * 800, 0.75 * 600), 35 * 3, 7, 10, alignment: S7_HudMessage.AlignCenter,
                    color: Font.CR_UNTRANSLATED, fnt: "BigFont", screenSize: (800, 600));

                if (message != "" && !additional)
                    S7_HudMessageFade.Show (consoleplayer, message, 2, (0.5 * 800, 0.8 * 600), 35 * 3, 7, 10,
                        flags: logMsgs ? S7_HudMessage.MSG_Log : 0, alignment: S7_HudMessage.AlignCenter, color: Font.CR_UNTRANSLATED, fnt: 'SmallFont', screenSize: (800, 600));
                else {
                    S7_HudMessageFade.Show (consoleplayer, String.Format ("You've reached level %d.\nYou have gained %d attribute points.", lvl, attrPts), 2, (0.5 * 800, 0.8 * 600), 35 * 3, 7, 10,
                        flags: logMsgs ? S7_HudMessage.MSG_Log : 0, alignment: S7_HudMessage.AlignCenter, color: Font.CR_UNTRANSLATED, fnt: 'SmallFont', screenSize: (800, 600));

                    if (message != "")
                        S7_HudMessageFade.Show (consoleplayer, message, 2, (0.5 * 800, 0.8 * 4805), 35 * 3, 7, 10,
                            flags: logMsgs ? S7_HudMessage.MSG_Log : 0, alignment: S7_HudMessage.AlignCenter, color: Font.CR_UNTRANSLATED, fnt: 'SmallFont', screenSize: (800, 600));
                }
            }
        }

        CVar globalLevelUpSoundsCVar = CVar.GetCVar ("S7_GlobalLevelUpSounds", players [consoleplayer]);
        Owner.A_PlaySound ("Player/LevelUp", CHAN_Body, volume: .75, local: (!globalLevelUpSoundsCVar || !globalLevelUpSoundsCVar.GetBool ()));
    }

    override void DoEffect () {
        Super.DoEffect ();

        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn)
            return;

        // Agility
        let staminaItem = pPawn.FindInventory ('S7_Stamina');
        if (staminaItem)
            staminaItem.maxAmount = pPawn.GetMaxStamina ();

        // Vitality
        pPawn.maxHealth = pPawn.S7_GetMaxHealth ();

        // Defense
        pPawn.damageFactor = clamp (1.0 - (0.01 * GetStat (S7Stat_Defense)), 0.1, 1.0);

        // Magic
        let manaItem = pPawn.FindInventory ('S7_Mana');
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