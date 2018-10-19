/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2017-2018 Caligari87
 *  Copyright (C) 2018      Chronos "phantombeta" Ouroboros
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

/* Credits:
** Coding: Caligari87, Chronos "phantombeta" Ouroboros
**
** Sprites:
**   Sprites: None yet lol.
**
** Sounds: Credits in the SNDINFO file (SNDINFO.MiscInventory)
*/
class S7_FlashlightBattery : Inventory {
    default {
        Tag "$FLASHLIGHT_BATTERY";

        Inventory.MaxAmount 4;
        Inventory.InterHubAmount 4;
        Inventory.PickupMessage "$FLASHLIGHT_BATTERY";
        Inventory.Icon "FLBTA0";

        +INVENTORY.INVBAR
    }

    override bool Use (bool pickup) {
        let flashlight = S7_Flashlight (Owner.FindInventory ("S7_Flashlight"));

        if (!flashlight) // Return false if the player doesn't have a flashlight.
            return false;

        if (flashlight.battery >= S7_Flashlight.MaxBatteryCharge) // Return false if the flashlight already has a full battery.
            return false;

        flashlight.battery = S7_Flashlight.MaxBatteryCharge;

        return true;
    }

    states {
    Spawn:
        FLBT A -1;
        stop;
    }
}

class S7_Flashlight : Inventory {
    const MaxBatteryCharge = 35 * 60 * 30;

    S7_Flashlight_Spotlight selfLight1, selfLight2;

    bool active;
    int battery;

    override void BeginPlay () {
        battery = MaxBatteryCharge;
    }

    override bool Use (bool pickup) {
        if (battery > 0)
            ToggleLight ();

        return false;
    }

    void ToggleLight () {
        Owner.A_PlaySound (active ? "Inventory/Flashlight/Off" : "Inventory/Flashlight/On", CHAN_ITEM, volume: 0.25);
        active = !active;
    }

    override void DoEffect () {
        Super.DoEffect ();

        if (active && battery <= 0)
            ToggleLight ();

        if (!active) {
            if (selfLight1)
                selfLight1.Destroy ();
            if (selfLight2)
                selfLight2.Destroy ();

            return;
        }

        battery--;

        Color colorCVar = S7_PlayerCVar.GetInt (Owner.player, "S7_FlashlightColor");
        double intensityMod = clamp (1. - ((max (battery - (MaxBatteryCharge/4.), 0.) / MaxBatteryCharge) / 4), 0., 1.);

        if (battery <= 0) // We shouldn't get here in the first place, but whatever.
            intensityMod = 0.;

        int r = int (colorCVar.R * intensityMod),
            g = int (colorCVar.G * intensityMod),
            b = int (colorCVar.B * intensityMod);
        
        int beamInner = 10;
        int beamOuter = 15;
        int beamRadius = 640;
        int spillInner = 15;
        int spillOuter = 75;
        int spillRadius = 256;

        int mount = S7_PlayerCVar.GetInt (Owner.player, "S7_FlashlightMount");
        double pViewZ = (owner.player.viewZ - owner.pos.Z);

        double offsetAngle, offsetZ;
        int inertia;
        double spring, damping;

        switch (mount) {
        case 0: // Left Shoulder
            spring = 0.35;
            damping = 0.75;
            inertia = 2;
            offsetAngle = 80;
            offsetZ = pViewZ - 5;
            break;
        case 1: // Right Shoulder
            spring = 0.35;
            damping = 0.75;
            inertia = 2;
            offsetAngle = -80;
            offsetZ = pViewZ - 5;
            break;
        case 2: // Helmet
            spring = 1;
            damping = 1;
            inertia = 1;
            offsetAngle = 0;
            offsetZ = pViewZ + 4;
            break;
        }

        if (!selfLight1) {
            selfLight1 = S7_Flashlight_Spotlight (Spawn ("S7_Flashlight_Spotlight", Owner.pos, false));
            selfLight1.followTarget = Owner;
        }
        if (!selfLight2) {
            selfLight2 = S7_Flashlight_Spotlight (Spawn ("S7_Flashlight_Spotlight", Owner.pos, false));
            selfLight2.followTarget = Owner;
        }

        if (selfLight1) {
            selfLight1.args [0] = r; // R
            selfLight1.args [1] = g; // G
            selfLight1.args [2] = b; // B
            selfLight1.args [3] = beamRadius; // Radius
            selfLight1.SpotInnerAngle = beamInner;
            selfLight1.SpotOuterAngle = beamOuter;
            selfLight1.angle = Owner.angle;
            selfLight1.pitch = Owner.pitch;
            selfLight1.spring = spring;
            selfLight1.damping = damping;
            selfLight1.inertia = inertia;
            selfLight1.offsetAngle = offsetAngle;
            selfLight1.offsetZ = offsetZ;
        }
        if (selfLight2) {
            selfLight2.args [0] = int (r * .75); // R
            selfLight2.args [1] = int (g * .75); // G
            selfLight2.args [2] = int (b * .75); // B
            selfLight2.args [3] = spillRadius; // Radius
            selfLight2.SpotInnerAngle = spillInner;
            selfLight2.SpotOuterAngle = spillOuter;
            selfLight2.angle = Owner.angle;
            selfLight2.pitch = Owner.pitch;
            selfLight2.spring = spring;
            selfLight2.damping = damping;
            selfLight2.inertia = inertia;
            selfLight2.offsetAngle = offsetAngle;
            selfLight2.offsetZ = offsetZ;
        }
    }
}

class S7_Flashlight_Spotlight : DynamicLight {
    Actor followTarget;
    double vela, velp;
    double spring, damping;
    double offsetAngle, offsetZ;
    Vector3 targetPos;
    int inertia;

    default {
        DynamicLight.Type "Point";

        +DYNAMICLIGHT.ATTENUATE +DYNAMICLIGHT.SPOT
    }

    override void Tick () {
        Super.Tick ();

        if (followTarget) {
            if (inertia == 0)
                inertia = 1;

            targetPos = followTarget.Vec3Angle (
                2 + (6 * abs (sin (offsetAngle))),
                followTarget.angle + offsetAngle,
                offsetZ * followTarget.player.crouchfactor,
                false
            );

            vel.x += S7_Math.DampedSpring (pos.x, targetPos.x, vel.x, 1, 1);
            vel.y += S7_Math.DampedSpring (pos.y, targetPos.y, vel.y, 1, 1);
            vel.z += S7_Math.DampedSpring (pos.z, targetPos.z, vel.z, 1, 1);
            vela  += S7_Math.DampedSpring (angle, followTarget.angle, vela, spring, damping);
            velp  += S7_Math.DampedSpring (pitch, followTarget.pitch, velp, spring, damping);

            SetOrigin (pos + vel, true);

            A_SetAngle (angle + (vela / inertia), true);
            A_SetPitch (pitch + (velp / inertia), true);
        }
    }
}