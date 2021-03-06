/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2017-2018 Caligari87
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

/* Credits:
** Coding: Chronos "phantombeta" Ouroboros
**
** Sprites: Id Software, Chronos "phantombeta" Ouroboros
*/
class S7_FlashlightBattery : Inventory {
    default {
        //$Category "Se7evidas/Inventory"
        //$Color 13
        //$Title "Flashlight Battery"
        //$NotAngled

        Tag "$FLASHLIGHT_BATTERY";

        Inventory.MaxAmount 4;
        Inventory.InterHubAmount 4;
        Inventory.PickupMessage "$FLASHLIGHT_BATTERY";
        Inventory.Icon "FLBTA0";

        +INVENTORY.INVBAR
    }

    override bool Use (bool pickup) {
        let flashlight = S7_Flashlight (Owner.FindInventory ('S7_Flashlight'));

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

/* Credits:
** Coding: Caligari87, Chronos "phantombeta" Ouroboros
**
** Sprites:
**   Sprites: None yet lol.
**
** Sounds: Credits in the SNDINFO file (SNDINFO.MiscInventory)
*/
class S7_Flashlight : Inventory {
    const MaxBatteryCharge = TicRate * 60 * 30;

    default {
        Inventory.MaxAmount 1;
        Tag "$S7_FLASHLIGHT";
    }

    transient CVar lightColorCVar, mountCVar;
    S7_Flashlight_Spotlight selfLight1, selfLight2;

    bool active;
    bool infraredMode;
    int battery;

    override void PostBeginPlay () {
        battery = MaxBatteryCharge;
    }

    override bool Use (bool pickup) {
        if (battery > 0)
            ToggleLight ();

        return false;
    }

    const Toggle_InfraredHoldTime = 10;
    transient int toggle_TimePressed;
    void TogglePressed () {
        if (!active)
            toggle_TimePressed = level.time;
        else {
            toggle_TimePressed = 0;
            ToggleLight ();
        }
    }

    void ToggleReleased () {
        if (toggle_TimePressed == 0)
            return;

        int timeHeld = level.time - toggle_TimePressed;
        toggle_TimePressed = 0;

        if (battery <= 0)
            return;

        ToggleLight ();
    }

    void ToggleLight () {
        Owner.A_StartSound (active ? "Inventory/Flashlight/Off" : "Inventory/Flashlight/On", slot: CHAN_Item, volume: 0.5);
        active = !active;
        infraredMode = false;
    }

    override void DoEffect () {
        Super.DoEffect ();

        let pPawn = S7_BasePlayer (Owner);
        if (!pPawn || pPawn.player == null || !pPawn.shaderData)
            return;

        if (toggle_TimePressed != 0) {
            int toggleTimeHeld = level.time - toggle_TimePressed;

            if (toggleTimeHeld >= Toggle_InfraredHoldTime) {
                toggle_TimePressed = 0;

                if (battery > 0) {
                    ToggleLight ();
                    infraredMode = (toggleTimeHeld >= Toggle_InfraredHoldTime);
                }
            }
        }

        if (active && (battery <= 0 || (infraredMode && battery <= (MaxBatteryCharge / 4. / 2.))))
            ToggleLight ();

        pPawn.shaderData.nightvisionOn = (active && infraredMode);

        if (!active) {
            if (selfLight1)
                selfLight1.Destroy ();
            if (selfLight2)
                selfLight2.Destroy ();

            return;
        }

        battery--;

        if (!lightColorCVar)
            lightColorCVar = CVar.GetCVar ("S7_FlashlightColor", pPawn.player);

        Color lightColor = lightColorCVar ? lightColorCVar.GetInt () : 0xFFFFFFFF;
        double intensityMod = clamp (double (battery) / (MaxBatteryCharge / 4.), 0., 1.);

        if (battery <= 0) // We shouldn't get here in the first place, but whatever.
            intensityMod = 0.;

        int r = int (lightColor.R * intensityMod),
            g = int (lightColor.G * intensityMod),
            b = int (lightColor.B * intensityMod);

        if (infraredMode) {
            r = g = b = int (128 * intensityMod);
            pPawn.shaderData.nightvisionIntensityMod = intensityMod;
        }

        int beamInner = 10;
        int beamOuter = 15;
        int beamRadius = 640 * 2.5;
        int spillInner = 15;
        int spillOuter = 75;
        int spillRadius = 256;

        if (!mountCVar)
            mountCVar = CVar.GetCVar ("S7_FlashlightMount", pPawn.player);

        int mount = mountCVar ? mountCVar.GetInt () : 0;
        double pViewZ = (owner.player.viewZ - owner.pos.Z);

        double offsetAngle, offsetZ;
        int inertia;
        double spring, damping;

        switch (mount) {
        default:
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
            selfLight1 = S7_Flashlight_Spotlight (Spawn ('S7_Flashlight_Spotlight', pPawn.pos, NO_REPLACE));
            selfLight1.followTarget = pPawn;
            selfLight1.angle = pPawn.angle;
            selfLight1.pitch = pPawn.pitch;
        }
        if (!selfLight2) {
            selfLight2 = S7_Flashlight_Spotlight (Spawn ('S7_Flashlight_Spotlight', pPawn.pos, NO_REPLACE));
            selfLight2.followTarget = pPawn;
            selfLight2.angle = pPawn.angle;
            selfLight2.pitch = pPawn.pitch;
        }

        if (selfLight1) {
            selfLight1.bDormant = (infraredMode && (players [consoleplayer] != pPawn.player));
            selfLight1.infrared = infraredMode;
            selfLight1.args [0] = r; // R
            selfLight1.args [1] = g; // G
            selfLight1.args [2] = b; // B
            selfLight1.args [3] = beamRadius; // Radius
            selfLight1.SpotInnerAngle = beamInner;
            selfLight1.SpotOuterAngle = beamOuter;
            selfLight1.spring = spring;
            selfLight1.damping = damping;
            selfLight1.inertia = inertia;
            selfLight1.offsetAngle = offsetAngle;
            selfLight1.offsetZ = offsetZ;
        }
        if (selfLight2) {
            selfLight2.bDormant = (infraredMode && (players [consoleplayer] != pPawn.player));
            selfLight2.infrared = infraredMode;
            selfLight2.args [0] = int (r * .75); // R
            selfLight2.args [1] = int (g * .75); // G
            selfLight2.args [2] = int (b * .75); // B
            selfLight2.args [3] = spillRadius; // Radius
            selfLight2.SpotInnerAngle = spillInner;
            selfLight2.SpotOuterAngle = spillOuter;
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
    bool infrared;
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
        if (!followTarget)
            return;

        if (inertia == 0)
            inertia = 1;

        targetPos = followTarget.Vec3Angle (
            2 + (6 * abs (sin (offsetAngle))),
            followTarget.angle + offsetAngle,
            offsetZ,
            false
        );

        vel.x += S7_Math.DampedSpring (pos.x, targetPos.x, vel.x, 1, 1);
        vel.y += S7_Math.DampedSpring (pos.y, targetPos.y, vel.y, 1, 1);
        vel.z += S7_Math.DampedSpring (pos.z, targetPos.z, vel.z, 1, 1);
        vela  += S7_Math.DampedSpring (angle, followTarget.angle, vela, spring, damping);
        velp  += S7_Math.DampedSpring (pitch, followTarget.pitch, velp, spring, damping);

        S7_ActorExtensions.SetActorPosition (self, pos + vel);

        A_SetAngle (angle + (vela / inertia), SPF_Interpolate);
        A_SetPitch (pitch + (velp / inertia), SPF_Interpolate);
    }
}