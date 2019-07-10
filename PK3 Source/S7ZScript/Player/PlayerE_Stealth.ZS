/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2002-2016 Christoph Oelckers
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

extend class S7_BasePlayer {
    double stealthFactor, shaderStealthFactor;
    void Misc_Stealth () {
        // Still needs to be enabled because of the shadowsphere.
        if (!player || (player.cheats & CF_PREDICTING))
            return;

        double lightLevel = 1.0;//Misc_Stealth_GetLightLevel ();
        lightLevel *= (CheckInventory ('S7_Invisibility_Power', 1) ? 0. : 1.);
        lightlevel = clamp (clamp (.6 - lightlevel, 0., 1.) / .4, 0., 1.);

        double crouchFactor = clamp (1. + .25 * (1. - player.crouchFactor), 1., 1.25);
        stealthFactor = clamp (lightLevel * crouchFactor, 0., 1.);

        shaderStealthFactor = S7_Math.Lerp (shaderStealthFactor, max ((stealthFactor - .6), 0.) / .4, .1);
        //Shader.SetUniform1f (player, "S7_StealthShader", "stealthFactor", shaderStealthFactor);
    }

    double Misc_Stealth_GetLightLevel () {
        // Initial "base" lightlevel
        double trueLightLevel = CurSector.lightlevel / 255.;

        // Check if the player is using their flashlight
        let flashlight = S7_Flashlight (FindInventory ("S7_Flashlight"));
        if (flashlight && flashlight.active && flashlight.battery > 0 && !flashlight.infraredMode)
            return 1.;

        // Set up light iterator
        let LightFinder = ThinkerIterator.Create ("DynamicLight", Thinker.STAT_DLIGHT);

        // Iterate lights
        DynamicLight currentLight = null;
        while (currentLight = DynamicLight (LightFinder.Next ())) {
            // Skip deactivated lights, lights that don't light actors and lights that don't light the owner
            if (currentLight.bDormant || currentLight.bDontLightActors || (currentLight.bDontLightSelf && currentLight.target == self))
                continue;

            if (currentLight is 'S7_Flashlight_Spotlight') {
                let curFlashlight = S7_Flashlight_Spotlight (currentLight);
                // Skip infrared lights
                if (curFlashlight && curFlashlight.infrared)
                    continue;
            }

            double r = 0., g = 0., b = 0.;

            Vector3 posDiff = currentLight.Vec3To (self);
            double dist = posDiff dot posDiff;
            double lightRadius = currentLight.Radius;
            if (dist < lightRadius * lightRadius && !(lightRadius ~== 0.)) {
                dist = posDiff.Length (); // Only calculate the square root if we really need it.

                double frac = 1.0 - (dist / lightRadius);

                if (currentLight.bSpot) {
                    Vector3 L = posDiff * (-1.0 / dist);

                    double xyLen = cos (currentLight.pitch);

                    Vector3 spotDir = (
                        -cos (currentLight.angle) * xyLen,
                        -sin (currentLight.angle) * xyLen,
                         sin (currentLight.pitch)
                    );

                    double cosDir = L.X * spotDir.X + L.Y * spotDir.Y + L.Z * spotDir.Z;
                    frac *= S7_Math.Smoothstep (cos (currentLight.SpotOuterAngle), cos (currentLight.SpotInnerAngle), cosDir);
                }

                if (frac > 0) {
                    double lR = currentLight.Args [DynamicLight.LIGHT_RED  ] / 255.;
                    double lG = currentLight.Args [DynamicLight.LIGHT_GREEN] / 255.;
                    double lB = currentLight.Args [DynamicLight.LIGHT_BLUE ] / 255.;

                    if (currentLight.bSubtractive) {
                        double bright = (lR, lG, lB).Length ();
                        lR = (bright - lR) * -1.;
                        lG = (bright - lG) * -1.;
                        lB = (bright - lB) * -1.;
                    }

                    r += lR * frac;
                    g += lG * frac;
                    b += lB * frac;
                } else
                    continue;
            } else
                continue;

            if (!currentLight.CheckSight (self))
                continue;

            double avgIntensity = clamp (.299 * r + .587 * g + .114 * b, 0., 1.);

            trueLightLevel = trueLightLevel + avgIntensity;
        }

        return clamp (trueLightLevel, 0., 1.);
    }
}