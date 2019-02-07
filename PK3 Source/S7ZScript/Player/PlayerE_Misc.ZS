/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
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

extend class S7_BasePlayer {
    static const string PermanentItems [] = {
        "S7_GrenadeWeap:S7_GrenadeCount",
        "S7_BerserkWeap:S7_Berserk",
        "S7_Thumper_PUnified",
        "S7_UnarmedWeap"
    };

    void Misc_PermanentItems () {
        if (player.cheats & CF_PREDICTING)
            return;

        for (int i = 0; i < PermanentItems.Size (); i++) {
            Array<String> parts; parts.Clear ();
            PermanentItems [i].Split (parts, ":");

            // If this happens someone's a fucking idiot.
            if (parts.Size () < 1 || parts.Size () > 2)
                continue;

            if ((parts.Size () == 1 || CheckInventory (parts [1], 1)) && !CheckInventory (parts [0], 1))
                GiveInventory (parts [0], 1);
        }
    }

    void Misc_StaminaRegen () {
        if (player.cheats & CF_PREDICTING)
            return;

        int curStamina = CountInv ('S7_Stamina');
        int maxStamina = GetMaxStamina ();

        if (health <= 0 || curStamina == maxStamina || sprint_Sprinting) {
            playerData.staminaTics = 0;
            return;
        }

        bool berserkActive = CheckInventory ('S7_BerserkToken', 1);
        int count = 1, interval = 1;

        if (berserkActive)
            count = (!playerData.dying) ? 4 : 2;
        if (playerData.dying)
            interval = berserkActive ? 2 : 3;

        if (playerData.staminaTics >= interval) {
            GiveInventory ('S7_Stamina', count);
            playerData.staminaTics = 0;
        }

        if (curStamina != maxStamina)
            playerData.staminaTics++;
    }

    void Misc_BerserkSideEffects () {
        if (player.cheats & CF_PREDICTING)
            return;
        if (health <= 0 || bKilled)
            return;

        int bsrkCount = CountInv ('S7_BerserkToken');

        if (!playerData.bsrkAddiction)
            playerData.bsrkMaxAddiction = 0;
        else
            playerData.bsrkMaxAddiction = max (playerData.bsrkMaxAddiction, playerData.bsrkAddiction);

        if (bsrkCount > 0 || !playerData.bsrkAddiction)
            playerData.bsrkWithdrawalTics = 0;
        else if (!bsrkCount && playerData.bsrkAddiction > 0) {
            playerData.bsrkWithdrawalTics++;

            double shiverTime = floor ((35. * 5.) * clamp (1. - (.2 * (playerData.bsrkMaxAddiction - 1.)), 0., 1.));
            if (playerData.bsrkWithdrawalTics >= shiverTime) {
                double shiverMod = max (playerData.bsrkWithdrawalTics / max (shiverTime * .35, 5), 1.);

                A_SetAngle (angle + clamp (fRandom [berserkEffects] (-.01, .01) * shiverMod, -.5, .5));
                A_SetPitch (pitch + clamp (fRandom [berserkEffects] (-.01, .01) * shiverMod, -.5, .5));
            }

            double baseDetoxTime = ((playerData.bsrkMaxAddiction < 2) ? (35. * 20.) : (35. * 40.)) * clamp (1. - (.01 * (xpSys.GetStat (S7Stat_Will) / 3.)), .45, 1.);
            double detoxTime = floor (baseDetoxTime * (1. + .2 * (playerData.bsrkMaxAddiction - 1.)));
            if (playerData.bsrkWithdrawalTics >= detoxTime) {
                double additionalDetoxTime = detoxTime * clamp (1. - (.035 * (xpSys.GetStat (S7Stat_Will) / 3.)), .35, 1.);
                bool doDetox = ((playerData.bsrkWithdrawalTics % max (additionalDetoxTime, 5)) == 0);

                if (doDetox)
                    playerData.bsrkAddiction--;
            }
        }
    }

    transient CVar heartbeatsSoundCVar;
    void Misc_Heartbeats () {
        if (health <= 0)
            return;

        if (!heartbeatsSoundCVar)
            heartbeatsSoundCVar = CVar.GetCVar ("S7_HeartbeatsOn", players [consoleplayer]);
        if (heartbeatsSoundCVar && heartbeatsSoundCVar.GetInt ()) {
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

    Actor Misc_BC_GetRightAct (Actor opt1, Actor opt2, Actor opt3, Actor opt4) {
        if (opt1)
            return opt1;
        else if (opt2)
            return opt2;
        else if (opt3)
            return opt3;
        else if (opt4)
            return opt4;

        return null;
    }

    void Misc_BC_DoCamera (out S7_BlurCamera cam, Actor dataActor) {
        if (!dataActor)
            return;

        if (!cam) {
            cam = S7_BlurCamera (Spawn ('S7_BlurCamera'));

            if (!cam)
                return;
        }

        cam.target = self;

        Vector3 camPos = dataActor.pos;
        double camAngle = dataActor.angle;
        double camPitch = dataActor.pitch;

        if (dataActor is 'PlayerPawn' && dataActor.player)
            camPos = (camPos.XY, dataActor.player.viewZ);

        Vector2 fwd = AngleToVector (camAngle, 2);

        if (s7_debugmode) {
        if (abs (camPitch) > 89)
            fwd = (fwd * max (0.5, cos (camPitch)) * 2);
        else
            fwd = (fwd * cos (camPitch) * 6);
        }

        cam.SetOrigin (camPos + fwd, true);
        //cam.vel = dataActor.vel;
        cam.angle = camAngle;
        cam.pitch = camPitch;
    }

    S7_BlurCamera cam1, cam2, cam3, cam4;
    void Misc_BlurCamera () {
        if (player.cheats & CF_PREDICTING)
            return;

        Misc_BC_DoCamera (cam4, Misc_BC_GetRightAct (cam3, cam2, cam1, self));
        Misc_BC_DoCamera (cam3, Misc_BC_GetRightAct (cam2, cam1, self, null));
        Misc_BC_DoCamera (cam2, Misc_BC_GetRightAct (cam1, self, null, null));
        Misc_BC_DoCamera (cam1, Misc_BC_GetRightAct (self, null, null, null)); // We don't actually show this one.
    }

    void Misc_HellhunterBlade () {
        if (player.cheats & CF_PREDICTING)
            return;

        int curLvl = CountInv ('S7_HellhunterBladeAffinity');
        int curExp = CountInv ('S7_HellhunterBladeExperience');
        int nxtLvl = 2500 + curLvl * 1250;
        if (curLvl < 10 && curExp >= nxtLvl) {
            GiveInventory ('S7_HellhunterBladeAffinity', 1);
            TakeInventory ('S7_HellhunterBladeExperience', nxtLvl);
        }
    }
}