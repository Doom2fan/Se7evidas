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
    override void MovePlayer () {
        let player = self.player;
        UserCmd cmd = player.cmd;

        // [RH] 180-degree turn overrides all other yaws
        if (player.turnticks) {
            player.turnticks--;
            angle += (180. / TURN180_TICKS);
        } else
            angle += cmd.yaw * (360./65536.);

        player.onground = (pos.z <= floorz) || bOnMobj || bMBFBouncer || (player.cheats & CF_NOCLIP2);

        ActualMovePlayer (player, cmd);
    }

    virtual void ActualMovePlayer (PlayerInfo player, UserCmd cmd) {
        // killough 10/98:
        //
        // We must apply thrust to the player and bobbing separately, to avoid anomalies. The thrust
        // applied to bobbing is always the same strength on ice, because the player still "works just
        // as hard" to move, while the thrust applied to the movement varies with 'movefactor'.
        if (cmd.forwardmove | cmd.sidemove) {
            double forwardmove, sidemove;
            double bobfactor;
            double friction, movefactor;
            double fm, sm;

            [friction, movefactor] = GetFriction ();
            bobfactor = friction < ORIG_FRICTION ? movefactor : ORIG_FRICTION_FACTOR;
            if (!player.onground && !bNoGravity && !waterlevel) {
                // [RH] allow very limited movement if not on ground.
                movefactor *= level.aircontrol;
                bobfactor*= level.aircontrol;
            }

            fm = cmd.forwardmove;
            sm = cmd.sidemove;
            [fm, sm] = TweakSpeeds (fm, sm);
            fm *= Speed / 256;
            sm *= Speed / 256;

            // When crouching, speed and bobbing have to be reduced
            if (CanCrouch () && player.crouchfactor != 1) {
                fm *= player.crouchfactor;
                sm *= player.crouchfactor;
                bobfactor *= player.crouchfactor;
            }

            forwardmove = fm * movefactor * (35 / TICRATE);
            sidemove = sm * movefactor * (35 / TICRATE);

            if (forwardmove) {
                Bob (Angle, cmd.forwardmove * bobfactor / 256., true);
                ForwardThrust (forwardmove, Angle);
            }
            if (sidemove) {
                let a = Angle - 90;
                Bob (a, cmd.sidemove * bobfactor / 256., false);
                Thrust (sidemove, a);
            }

            if (!(player.cheats & CF_PREDICTING) && (forwardmove != 0 || sidemove != 0))
                PlayRunning ();

            if (player.cheats & CF_REVERTPLEASE) {
                player.cheats &= ~CF_REVERTPLEASE;
                player.camera = player.mo;
            }
        }
    }

    void Movement_Dodging () {
        if (health > 0) {
            // Dodging
            if (playerData.dodgeCooldown <= 0) { // If dodgeCooldown is less than or equal to 0...
                // If the player tapped user2, isn't sprinting, didn't have his Soul Lance beam grabbed and has at least S7C_DodgeStamina stamina...
                if ((player.cmd.buttons & BT_USER2) && !(player.oldbuttons & BT_USER2) && (pos.Z - floorZ) <= 0 &&
                    !(self is "S7_DracoPlayer") && !playerData.sprinting && CheckInventory ("S7_Stamina", S7C_DodgeStamina) &&
                    !CheckInventory ("S7_SoulLance_BeamGrabbed", 1) && !playerData.lGrabGrabbed
                ) {
                    double forwardMove = Clamp (player.cmd.forwardmove / 12800, -1.0, 1.0);
                    double sideMove = Clamp (player.cmd.sidemove / 10240, -1.0, 1.0);

                    if (forwardMove != 0 || sideMove != 0) { // If the player is trying to move
                        TakeInventory ("S7_Stamina", S7C_DodgeStamina); // Take S7C_DodgeStamina stamina

                        A_PlaySound ("Player/Dodge", CHAN_Body); // Play the dodge sound

                        GiveInventory ("S7_PowerDodgeEffects", 1);
                        vel.X = vel.Y = 0.;
                        Thrust (32, (angle - 90) + atan2 (forwardMove, sideMove));

                        playerData.dodgeCooldown = S7_DodgeCooldown;
                    }
                }
            } else
                playerData.dodgeCooldown--;
        } else
            TakeInventory ("S7_PowerDodgeEffects", 0x7FFFFFFF);
    }

    void Movement_MultiJump () {
        if (!level.IsJumpingAllowed () || health <= 0 || playerData.lGrabGrabbed || playerData.wjumpJustJumped || CheckInventory ("S7_SoulLance_BeamGrabbed", 1))
            return;

        if (player.onground || bOnMobj) {
            playerData.mjumpCount = 0;
            return;
        }

        int mJumpMax = CountInv ("S7_MultiJump_Max");
        if (mJumpMax < 1 || playerData.mjumpCount >= mJumpMax)
            return;

        double force = (JumpZ * 35 / TICRATE) * S7_MultiJumpZMul;
        if (force <= 0.0)
            return;

        if ((player.cmd.buttons & BT_JUMP) && !(player.oldbuttons & BT_JUMP) && abs (pos.Z - GetZAt ()) >= S7C_MJumpMinDiff && vel.Z <= 16.0) {
            let marker = Spawn ("S7_MultiJump_Marker", pos); // Spawn the multijump effect
            marker.angle = angle;
            vel.Z = force;
            playerData.mjumpCount++; // Increment the jump counter by 1
        }
    }

    const WallJumpHitCount = 12.0;
    const WallJumpHitInterval = 45.0 / WallJumpHitCount;
    void Movement_WallJump () {
        if (playerData.wjumpJustJumped)
            playerData.wjumpJustJumped--;

        if (health <= 0 || (self is "S7_DracoPlayer") || playerData.wjumpJustJumped || CheckInventory ("S7_SoulLance_BeamGrabbed", 1))
            return;

        if ((player.cmd.forwardmove < 0 || playerData.lGrabGrabbed) && (player.cmd.buttons & BT_JUMP) && !(player.oldbuttons & BT_JUMP) && (pos.Z - GetZAt ()) >= 16.0) {
            Vector3 normal;
            double xyLen = cos (-pitch);
            normal.x = xyLen * cos (-angle);
            normal.y = xyLen * sin (angle);
            normal.z = sin (-pitch);
            normal = normal.Unit ();
            
            FLineTraceData traceData;
            for (int i = 0; i < WallJumpHitCount + 1; i++) {
                double hitAngle = angle + (WallJumpHitInterval * ((-1) ^ ((i+1) & 1) * ((i+1) >> 1)));

                for (int j = 0; j < WallJumpHitCount + 1; j++) {
                    double hitPitch = pitch + (WallJumpHitInterval * ((-1) ^ ((j+1) & 1) * ((j+1) >> 1)));
                    LineTrace (hitAngle, 24, hitPitch, flags: TRF_ThruHitscan | TRF_NoSky, offsetz: (height / 2) + (AttackZOffset * player.crouchfactor), data: traceData);

                    if (traceData.HitType == TRACE_HitWall && traceData.HitLine) {
                        Vector2 lineAngle = AngleToVector (VectorAngle (traceData.HitLine.delta.X, traceData.HitLine.delta.Y) - 90., 1.);
                        Vector3 wallNormal = (lineAngle.X, lineAngle.Y, 0).Unit ();

                        if (wallNormal dot normal > 0)
                            wallNormal = -wallNormal;

                        Vector3 velChange = wallNormal;
                        velChange.X *= 15; velChange.Y *= 15;

                        double wallJumpZVel = (JumpZ * 35 / TICRATE);
                        if (velChange.Z == 0.0)     velChange.Z  = wallJumpZVel;
                        else if (velChange.Z < 0.0) velChange.Z  = wallJumpZVel * -velChange.Z;
                        else                        velChange.Z *= wallJumpZVel;

                        playerData.wjumpJustJumped = S7C_WJumpDelay;
                        vel = velChange;
                        A_SetPitch (VectorAngle (wallNormal.XY.Length (), wallNormal.Z), SPF_ForceClamp | SPF_Interpolate);
                        A_SetAngle (VectorAngle (wallNormal.X, wallNormal.Y), SPF_ForceClamp | SPF_Interpolate);

                        if (playerData.lGrabGrabbed)
                            playerData.lGrabGrabbed = false;

                        return;
                    }
                }
            }
        }
    }

    const LedgeGrab_MaxReach = 8.0;
    const LedgeGrab_MaxHeight = 48.0;
    bool Movement_LGrab_CanHold (Actor marker, double spRadius) {
        double hDist = marker.Distance2D (self);
        double vDist = marker.pos.Z - player.viewZ;

        return (
            abs (vDist) <= LedgeGrab_MaxHeight && abs (hDist) <= (spRadius + LedgeGrab_MaxReach + 2) &&
            (marker.pos.Z - viewHeight) >= (floorZ + 4) && !bOnMobj && !player.onground
        );
    }
    bool Movement_LGrab_CheckWeap () {
        int weapFlags = WF_WeaponReady | WF_WeaponSwitchOK;

        return (
            ((player.WeaponState & weapFlags) == weapFlags) || player.ReadyWeapon is "S7_SprintWeapon"
        );
    }
    void Movement_LedgeGrabbing () {
        double spRadius = ceil (radius * sqrt (2.0));

        if (playerData.lGrabGrabbed && playerData.lGrabMarker) {
            let marker = S7_LedgeMarker (playerData.lGrabMarker);

            bool crushFingers = ((marker.ceilingZ - marker.floorZ) < 1 || marker.floorZ >= self.ceilingZ);
            if (!Movement_LGrab_CanHold (marker, spRadius) || crushFingers || player.cmd.forwardmove < 0 ||
                S7_ActorExtensions.IsInVoid (marker)) {
                if (crushFingers)
                    DamageMobj (null, null, 4, "Crush", DMG_No_Armor | DMG_Thrustless);

                if (player.ReadyWeapon is "S7_LedgeGrabWeapon" && weapBinds.LastWeapon)
                    player.PendingWeapon = weapBinds.LastWeapon;

                marker.Destroy ();
                playerData.lGrabMarker = null;
                playerData.lGrabGrabbed = false;

                return;
            }

            double angleToMarker = AngleTo (marker);
            double angleDiff = DeltaAngle (angleToMarker, angle);
            if (angleDiff < -90)
                A_SetAngle (angleToMarker - 90);
            if (angleDiff >  90)
                A_SetAngle (angleToMarker + 90);

            double viewZ = pos.Z + player.viewHeight;
            Vector3 newVel = (
                S7_Math.DampedSpring (pos.X, marker.pos.X, vel.X, 0.25, 0.5 ),
                S7_Math.DampedSpring (pos.Y, marker.pos.Y, vel.Y, 0.25, 0.5 ),
                S7_Math.DampedSpring (viewZ, marker.pos.Z, vel.Z, 0.75, 0.25)
            );

            vel = newVel;
        } else if ((!playerData.lGrabGrabbed && playerData.lGrabMarker) || (playerData.lGrabGrabbed && !playerData.lGrabMarker)) {
            if (playerData.lGrabMarker)
                playerData.lGrabMarker.Destroy ();

            if (player.ReadyWeapon is "S7_LedgeGrabWeapon" && weapBinds.LastWeapon)
                player.PendingWeapon = weapBinds.LastWeapon;

            playerData.lGrabMarker = null;
            playerData.lGrabGrabbed = false;

            return;
        }

        if (!playerData.lGrabGrabbed && vel.Z < 0.0 && vel.xy.Length () < 5 && Movement_LGrab_CheckWeap ()) {
            let oldPos = pos;
            SetXYZ (pos + (0, 0, height));
            double ledgeHeight = GetZAt (spRadius + LedgeGrab_MaxReach, 0) - oldPos.Z;
            SetXYZ (oldPos);

            if (ledgeHeight > maxStepHeight && ledgeHeight <= LedgeGrab_MaxHeight) {
                bool MUDA;
                [MUDA, playerData.lGrabMarker] = A_SpawnItemEx ("S7_LedgeMarker", spRadius + LedgeGrab_MaxReach, zofs: ledgeHeight);

                if (playerData.lGrabMarker) {
                    let marker = S7_LedgeMarker (playerData.lGrabMarker);

                    if (Movement_LGrab_CanHold (marker, spRadius) && (marker.ceilingZ - marker.floorZ) >= 1 && marker.floorZ < self.ceilingZ &&
                        !S7_ActorExtensions.IsInVoid (marker)) {
                        vel = (0, 0, vel.Z);

                        if (!playerData.wjumpJustJumped)
                            playerData.wjumpJustJumped = 1;

                        GiveInventory ("S7_LedgeGrabWeapon", 1);
                        player.PendingWeapon = Weapon (FindInventory ("S7_LedgeGrabWeapon"));

                        playerData.lGrabGrabbed = true;
                    } else {
                        marker.Destroy ();
                        playerData.lGrabMarker = null;
                        playerData.lGrabGrabbed = false;
                    }
                }
            }
        }

        if (player.ReadyWeapon is "S7_LedgeGrabWeapon" && !playerData.lGrabGrabbed && weapBinds.LastWeapon)
            player.PendingWeapon = weapBinds.LastWeapon;
        else if (!playerData.lGrabGrabbed && CheckInventory ("S7_LedgeGrabWeapon", 1))
            TakeInventory ("S7_LedgeGrabWeapon", 0x7FFFFFFF);
    }

    void Movement_Sprinting () {
        double forwardMove = abs (player.cmd.forwardmove) / 12800;
        double sideMove = abs (player.cmd.sidemove) / 10240;

        if (health > 0) {
            // This is here just in case something fucks up and the player keeps the sprint "weapon" for some reason.
            if (player.ReadyWeapon is "S7_SprintWeapon" && !playerData.sprinting && weapBinds.LastWeapon)
                player.PendingWeapon = weapBinds.LastWeapon;
            else if (!playerData.sprinting && CheckInventory ("S7_SprintWeapon", 1))
                TakeInventory ("S7_SprintWeapon", 0x7FFFFFFF);

            if (playerData.sprintTics == -1 && CheckInventory ("S7_Stamina", 75))
                playerData.sprintTics = 0;

            // Start/stop sprinting
            if (!playerData.sprinting && playerData.sprintTics != -1 &&
                (player.cmd.buttons & BT_USER1) && !playerData.dying && CheckInventory ("S7_Stamina", S7C_SprintStamina) &&
                !CheckInventory ("S7_SoulLance_BeamGrabbed", 1) && !(self is "S7_DracoPlayer") && !playerData.lGrabGrabbed
                ) {
                playerData.sprinting = true;
                playerData.sprintSpeedFactor = playerData.sprintSpdFacPproc = 0.0;
                playerData.sprintTics = 0;
                playerData.oldAgility = double.NaN;

                GiveInventory ("S7_SprintWeapon", 1);
                player.PendingWeapon = Weapon (FindInventory ("S7_SprintWeapon"));
            } else if (playerData.sprinting &&
                (!(player.cmd.buttons & BT_USER1) || playerData.dying || CountInv ("S7_Stamina") < S7C_SprintStamina ||
                CheckInventory ("S7_SoulLance_BeamGrabbed", 1) || playerData.lGrabGrabbed || (self is "S7_DracoPlayer"))
                ) {
                if (playerData.sprintTics < 5)
                    TakeInventory ("S7_Stamina", playerData.sprintTics);

                playerData.sprinting = false;
                playerData.sprintSpeedFactor = playerData.sprintSpdFacPproc = 0.0;
                playerData.sprintTics = (!CheckInventory ("S7_Stamina", 5)) ? -1 : 0;

                if (!playerData.lGrabGrabbed && weapBinds.LastWeapon)
                    player.PendingWeapon = weapBinds.LastWeapon;
            }
            if (playerData.sprinting && player.ReadyWeapon is "S7_SprintWeapon") {
                if (player.onground) {
                    if (playerData.sprintTics++ >= 5 && (forwardMove != 0.0 || sideMove != 0.0)) {
                        playerData.sprintTics = 0;
                        TakeInventory ("S7_Stamina", S7C_SprintStamina);
                    } else if ((forwardMove != 0.0 || sideMove != 0.0) && (vel.X != 0.0 || vel.Y != 0.0))
                        playerData.sprintTics++;
                }

                double newAgility = xpSys.GetStat (S7Stat_Agility);
                if (newAgility != playerData.oldAgility) {
                    if (newAgility > 0) // Just so it doesn't explode
                        playerData.sprintSpdFacPproc = 0.1 * log (newAgility);
                    else
                        playerData.sprintSpdFacPproc = 0;
                    playerData.oldAgility = newAgility;
                }

                if (!player.onground)
                    playerData.sprintSpeedFactor = 0.0;
                else if ((forwardMove > 0.5 || sideMove > 0.5))
                    playerData.sprintSpeedFactor = Clamp (0.5 + playerData.sprintSpdFacPproc, 0.0, 2.5);
                else
                    playerData.sprintSpeedFactor = Clamp (0.5 + (0.5 + playerData.sprintSpdFacPproc) * 2, 0.0, 2.5);
            }
        }
    }
}

class S7_LedgeMarker : S7_PositionMarkerPersistent {
    default {
        Radius 4;

        +MOVEWITHSECTOR
    }
}