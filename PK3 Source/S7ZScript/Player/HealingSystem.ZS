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

class S7_HealingSystem : Inventory {
    const baseRegenAmount = 1.0;
    const baseRegenTime = 3;

    int regenPoints;
    protected int regenTimer;

    override void AttachToOwner (Actor other) {
        Super.AttachToOwner (other);

        regenPoints = 0;
    }

    override void DoEffect () {
        if (!Owner || !(Owner is "S7_BasePlayer"))
            return;

        let pPawn = S7_BasePlayer (Owner);
        if (!pPawn || !pPawn.xpSys)
            return;

        if (regenTimer > 0 && regenPoints > 0)
            regenTimer--;

        if (regenTimer == 0 && regenPoints > 0) {
            double regenRateAmount, regenRateTime;

            [regenRateTime, regenRateAmount] = pPawn.xpSys.GetStatMod (S7Stat_Special, specialName: "regenRate");
            regenRateAmount += baseRegenAmount;

            int giveCount = int (min (regenRateAmount, regenPoints));

            pPawn.GiveBody (giveCount);
            regenPoints -= giveCount;

            regenTimer = int (baseRegenTime * regenRateTime);
        } else if (regenPoints < 0) {
            Console.PrintF ("S7 Error: What the hell? S7_HealingSystem.regenPoints became negative!");
            regenPoints = 0;
            regenTimer = 0;
        } else if (regenPoints == 0 && regenTimer > 0)
            regenTimer = 0;
    }
}