/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

extend class S7_BasePlayer {
    void Misc_StaminaRegen () {
        int curStamina = CountInv ("S7_Stamina");
        int maxStamina = GetMaxStamina ();

        if (health <= 0 || curStamina == maxStamina || playerData.sprinting) {
            playerData.staminaTics = 0;
            return;
        }

        bool berserkActive = CheckInventory ("S7_BerserkToken", 1);
        int count = 1, interval = 1;

        if (berserkActive)
            count = (!playerData.dying) ? 4 : 2;
        if (playerData.dying)
            interval = berserkActive ? 2 : 3;

        if (playerData.staminaTics >= interval) {
            GiveInventory ("S7_Stamina", count);
            playerData.staminaTics = 0;
        }

        if (curStamina != maxStamina)
            playerData.staminaTics++;
    }

    void Misc_Heartbeats () {
        if (health <= 0)
            return;

        CVar heartbeats = CVar.GetCVar ("S7_HeartbeatsOn", players [consoleplayer]);
        if (heartbeats && heartbeats.GetInt ()) {
            if ((health <= 25 && health > 15 && playerData.heartbeatTics >= 89) || // I couldn't find a better way to do this... >.>
                (health <= 15 && health > 10 && playerData.heartbeatTics >= 71) ||
                (health <= 10 && health > 5  && playerData.heartbeatTics >= 53) ||
                (health <= 5  && health > 2  && playerData.heartbeatTics >= 35) ||
                (health <= 2  &&                playerData.heartbeatTics >= 18)
            ) {
                A_PlaySound ("Player/Heartbeat", CHAN_Body, 1.0, false, ATTN_NONE, true);
                playerData.heartbeatTics = 0;
            } else if (health > 25) // If health is greater than 25...
                playerData.heartbeatTics = 0; // Set heartbeatTics to 0
            else // if neither...
                playerData.heartbeatTics++; // Add one to heartbeatTics
        }
    }

    void Misc_HellhunterBlade () {
        int curLvl = CountInv ("S7_HellhunterBladeAffinity");
        int curExp = CountInv ("S7_HellhunterBladeExperience");
        int nxtLvl = 2500 + curLvl * 1250;
        if (curLvl < 10 && curExp >= nxtLvl) {
            GiveInventory ("S7_HellhunterBladeAffinity", 1);
            TakeInventory ("S7_HellhunterBladeExperience", nxtLvl);
        }
    }
}