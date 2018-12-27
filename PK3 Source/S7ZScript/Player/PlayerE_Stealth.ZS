/*
** zlib License
**
** (C) 2018 Sterling Parker (aka "Caligari87")
**
** This software is provided 'as-is', without any express or implied
** warranty.  In no event will the authors be held liable for any damages
** arising from the use of this software.
**
** Permission is granted to anyone to use this software for any purpose,
** including commercial applications, and to alter it and redistribute it
** freely, subject to the following restrictions:
**
** 1. The origin of this software must not be misrepresented; you must not
**    claim that you wrote the original software. If you use this software
**    in a product, an acknowledgment in the product documentation would be
**    appreciated but is not required.
** 2. Altered source versions must be plainly marked as such, and must not be
**    misrepresented as being the original software.
** 3. This notice may not be removed or altered from any source distribution.
*/

extend class S7_BasePlayer {
    int stealthFactor;
    void Misc_Stealth () {
        if (!player || (player.cheats & CF_PREDICTING))
            return;

        int threshold = int (floor ((24. / max (player.crouchfactor, 0.0001)) - vel.Length ()));

        stealthFactor -= clamp (Misc_Stealth_GetLightLevel () - threshold, -5, 5);
        stealthFactor = clamp (stealthFactor, 0, 100);
    }

    int Misc_Stealth_GetLightLevel () {
        // Set up light iterator
        let LightFinder = ThinkerIterator.Create ("DynamicLight", Thinker.STAT_DLIGHT);

        // Initial "base" lightlevel
        int trueLightLevel = CurSector.lightlevel;

        // Iterate lights
        DynamicLight currentLight = null;
        while (currentLight = DynamicLight (LightFinder.Next ())) {
            // Skip if the light isn't in LoS
            if (!currentLight.CheckSight (self))
                continue;

            Vector3 posdiff = level.Vec3Diff ((pos.x, pos.y, pos.z + (height / 2.)), currentLight.pos);
            double currentDistance = posdiff.Length ();

            double distanceFactor = currentDistance / (double (currentLight.args [DynamicLight.LIGHT_INTENSITY] + 1) * 2);

            double r = currentLight.args [DynamicLight.LIGHT_RED  ],
                   g = currentLight.args [DynamicLight.LIGHT_GREEN],
                   b = currentLight.args [DynamicLight.LIGHT_BLUE ];

            double avgIntensity = (0.299 * r + 0.587 * g + 0.114 * b);

            // Invert cuz math
            avgIntensity *= 1.0 - distanceFactor;

            // Handle spotlights
            if (currentLight.bSpot) {
                double offangle = abs (deltaangle (currentLight.AngleTo (self), currentLight.angle));
                if (offangle > currentLight.SpotInnerAngle)
                    avgIntensity *= 0.5;
                if (offangle > currentLight.SpotOuterAngle)
                    avgIntensity *= 0.1;
            }

            // Intensify lights close to player
            if (currentDistance < radius)
                avgIntensity *= 10;

            // Handle dormant lights
            if (currentLight.bDormant)
                avgIntensity = 0;

            trueLightLevel = int (max (trueLightLevel, avgIntensity));
        }

        return trueLightLevel;
    }
}