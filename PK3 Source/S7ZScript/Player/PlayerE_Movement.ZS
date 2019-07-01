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

extend class S7_BasePlayer {
    // Crouching
    bool crouching_DoCrouch;

    // Dodging
    int dodge_Cooldown;

    // Multi-jumping
    int multiJump_Count;

    // Wall-jumping
    const WallJumpHitCount = 12.0;
    const WallJumpHitInterval = 45.0 / WallJumpHitCount;
    int wallJump_JustJumped;

    // Ledge grabbing
    const LedgeGrab_MaxReach = 8.0;
    const LedgeGrab_MaxHeight = 48.0;
    const LedgeGrab_DropKeys = BT_USE | BT_JUMP;

    Actor ledgeGrab_Marker;
    bool  ledgeGrab_Grabbed;
    bool  ledgeGrab_DoClimb;

    // Sprinting
    bool   sprint_Sprinting;
    int    sprint_Tics; // sprintTics: Used to remove stamina. If this is -1, stamina was depleted by sprinting.
    double sprint_OldAgility; // oldAgility: This is used for checking if the agility stat changed.
    double sprint_SpeedFactor, sprint_SpdFacPproc; // sprintSpdFacPproc: This is here to store the speed factor to avoid having to make lots of expensive log calls.

    // Teching
    const Teching_MaxPressTime = 35 / 4;
    const Teching_MaxHorzSpeed = 50.0;

    bool   teching_Active;
    bool   teching_HorzVelKilled;
    double teching_VelXKillSpeed;
    double teching_VelYKillSpeed;

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

            double sprintFactor = 1.0 + (sprint_Sprinting ? sprint_SpeedFactor : 0.0);
            forwardmove = fm * movefactor * (35 / TICRATE) * sprintFactor;
            sidemove = sm * movefactor * (35 / TICRATE) * sprintFactor;

            if (forwardmove) {
                Bob (Angle, cmd.forwardmove * bobfactor / 256., true);
                ForwardThrust (forwardmove, Angle);
            }
            if (sidemove) {
                let a = Angle - 90;
                Bob (a, cmd.sidemove * bobfactor / 256., false);
                Thrust (sidemove, a);
            }

            if (!(player.cheats & CF_PREDICTING) && !(forwardmove ~== 0 && sidemove ~== 0))
                PlayRunning ();

            if (player.cheats & CF_REVERTPLEASE) {
                player.cheats &= ~CF_REVERTPLEASE;
                player.camera = player.mo;
            }
        }
    }
    override void CheckCrouch (bool totallyfrozen) {
        UserCmd cmd = player.cmd;

        if (player.onground && cmd.buttons & BT_JUMP)
            crouching_DoCrouch = false;

        if (CanCrouch () && player.health > 0 && level.IsCrouchingAllowed ()) {
            if (!totallyfrozen) {
                if ((cmd.buttons & BT_CROUCH) && !(player.oldbuttons & BT_CROUCH))
                    crouching_DoCrouch = player.onground;
                else if (!(cmd.buttons & BT_CROUCH) && (player.oldbuttons & BT_CROUCH))
                    crouching_DoCrouch = false;

                int crouchdir = player.crouching;

                if (crouchdir == 0)
                    crouchdir = crouching_DoCrouch ? -1 : 1;
                else if (crouching_DoCrouch)
                    player.crouching = 0;

                if (crouchdir == 1 && player.crouchfactor < 1 && pos.Z + height < ceilingz)
                    CrouchMove (1);
                else if (crouchdir == -1 && player.crouchfactor > 0.5)
                    CrouchMove (-1);
            }
        } else
            player.Uncrouch ();

        player.crouchoffset = -(ViewHeight) * (1 - player.crouchfactor);
    }

    void Movement_Dodging () {
        if (health > 0) {
            // Dodging
            if (dodge_Cooldown <= 0) { // If dodge_Cooldown is less than or equal to 0...
                // If the player tapped user2, isn't sprinting, didn't have his Soul Lance beam grabbed and has at least S7C_DodgeStamina stamina...
                if ((player.cmd.buttons & BT_USER2) && !(player.oldbuttons & BT_USER2) && (pos.Z - floorZ) <= 0 &&
                    !(self is 'S7_DracoPlayer') && !sprint_Sprinting && CheckInventory ('S7_Stamina', S7C_DodgeStamina) &&
                    !CheckInventory ('S7_SoulLance_BeamGrabbed', 1) && !ledgeGrab_Grabbed
                ) {
                    Vector3 movementInput = S7_ActorExtensions.ConvertPlayerMovementInput (player.cmd.forwardmove, player.cmd.sidemove);

                    if (!(movementInput.XY dot movementInput.XY ~== 0)) { // If the player is trying to move
                        if (!(player.cheats & CF_PREDICTING))
                            TakeInventory ('S7_Stamina', S7C_DodgeStamina); // Take S7C_DodgeStamina stamina

                        A_PlaySound ("Player/Dodge", CHAN_Body); // Play the dodge sound

                        if (!(player.cheats & CF_PREDICTING))
                            GiveInventory ('S7_PowerDodgeEffects', 1);
                        vel.X = vel.Y = 0.;
                        Thrust (32, angle + VectorAngle (movementInput.X, -movementInput.Y));

                        if (!(player.cheats & CF_PREDICTING))
                            dodge_Cooldown = S7_DodgeCooldown;
                    }
                }
            } else if (!(player.cheats & CF_PREDICTING))
                dodge_Cooldown--;
        } else if (!(player.cheats & CF_PREDICTING))
            TakeInventory ('S7_PowerDodgeEffects', 0x7FFFFFFF);
    }

    void Movement_MultiJump () {
        if (player.cheats & CF_PREDICTING)
            return;
        if (!level.IsJumpingAllowed () || health <= 0 || ledgeGrab_Grabbed || wallJump_JustJumped || CheckInventory ('S7_SoulLance_BeamGrabbed', 1))
            return;
        if (teching_Active)
            return;

        if (player.onground || bOnMobj) {
            multiJump_Count = 0;
            return;
        }

        int mJumpMax = CountInv ('S7_MultiJump_Max');
        if (mJumpMax < 1 || multiJump_Count >= mJumpMax)
            return;

        double force = (JumpZ * 35 / TICRATE) * S7_MultiJumpZMul;
        if (force <= 0.0)
            return;

        if ((player.cmd.buttons & BT_JUMP) && !(player.oldbuttons & BT_JUMP) && abs (pos.Z - GetZAt ()) >= S7C_MJumpMinDiff && vel.Z <= 16.0) {
            let marker = Spawn ('S7_MultiJump_Marker', pos); // Spawn the multijump effect
            marker.angle = angle;
            vel.Z = force;
            multiJump_Count++; // Increment the jump counter by 1
        }
    }

    void Movement_WallJump_DoJump (Line l, Vector3 normal) {
        normal = normal.Unit ();

        Vector2 lineAngle = AngleToVector (VectorAngle (l.delta.X, l.delta.Y) - 90., 1.);
        Vector3 wallNormal = (lineAngle.X, lineAngle.Y, 0).Unit ();

        if ((wallNormal dot normal) > 0)
            wallNormal = -wallNormal;

        Vector3 velChange = -normal;
        velChange.XY *= 15;
        velChange.Z = (JumpZ * 35 / TICRATE);

        velChange *= max ((-normal) dot wallNormal, .75);

        if (!(player.cheats & CF_PREDICTING))
            wallJump_JustJumped = S7C_WJumpDelay;

        vel = velChange;

        A_SetPitch (-VectorAngle (velChange.XY.Length (), velChange.Z) * .125, SPF_ForceClamp);
        A_SetAngle (VectorAngle (velChange.X, velChange.Y), SPF_ForceClamp);

        if (ledgeGrab_Grabbed && !(player.cheats & CF_PREDICTING))
            ledgeGrab_Grabbed = false;
    }

    void Movement_WallJump () {
        if (wallJump_JustJumped && !(player.cheats & CF_PREDICTING))
            wallJump_JustJumped--;

        if (health <= 0 || (self is 'S7_DracoPlayer') || wallJump_JustJumped || CheckInventory ('S7_SoulLance_BeamGrabbed', 1))
            return;

        // Return if the player isn't trying to move backwards and isn't holding onto a ledge
        if (player.cmd.forwardmove >= 0 && !ledgeGrab_Grabbed)
            return;
        // Return if the player didn't just press the jump key
        if (!((player.cmd.buttons & BT_JUMP) && !(player.oldbuttons & BT_JUMP)))
            return;
        // Return if the player isn't 16 mu above the ground
        if (!ledgeGrab_Grabbed && (pos.Z - GetZAt ()) < 16.0)
            return;

        let normal = S7_Math.GetAxisAngles (angle, -pitch, roll);
        normal = normal.Unit ();

        FLineTraceData traceData;
        for (int i = 0; i < WallJumpHitCount + 1; i++) {
            double hitAngle = angle + (WallJumpHitInterval * ((-1) ^ ((i+1) & 1) * ((i+1) >> 1)));

            double angSin = sin (hitAngle);
            double angCos = cos (hitAngle);

            Vector2 distVec = ((angCos, angSin) * (radius * 2)) / max (abs (angCos), abs (angSin));
            double dist = distVec.Length ();

            for (int j = 0; j < WallJumpHitCount + 1; j++) {
                double hitPitch = pitch + (WallJumpHitInterval * ((-1) ^ ((j+1) & 1) * ((j+1) >> 1)));
                LineTrace (hitAngle, dist, hitPitch, flags: TRF_ThruHitscan | TRF_NoSky, offsetz: (height / 2) + (AttackZOffset * player.crouchfactor), data: traceData);

                if (traceData.HitType != TRACE_HitWall || !traceData.HitLine)
                    continue;

                Movement_WallJump_DoJump (traceData.HitLine, normal);
                return;
            }
        }
    }

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

        if (player.ReadyWeapon is 'S7_SSG')
            weapFlags = WF_WeaponSwitchOK;

        return (
            ((player.WeaponState & weapFlags) == weapFlags)
        );
    }
    void Movement_LedgeGrabbing () {
        double spRadius = ceil (radius * sqrt (2.));

        if (ledgeGrab_Grabbed && ledgeGrab_Marker) {
            let marker = S7_LedgeMarker (ledgeGrab_Marker);

            bool crushFingers = ((marker.ceilingZ - marker.floorZ) < 1 || marker.floorZ >= self.ceilingZ);

            if (crushFingers || !Movement_LGrab_CanHold (marker, spRadius) ||
                ((player.cmd.buttons & LedgeGrab_DropKeys) == LedgeGrab_DropKeys) ||
                S7_ActorExtensions.IsInVoid (marker)
            ) {
                if (player.cheats & CF_PREDICTING)
                    return;

                if (crushFingers)
                    DamageMobj (null, null, 4, 'Crush', DMG_No_Armor | DMG_Thrustless);

                if (player.ReadyWeapon is 'S7_LedgeGrabWeapon' && weapBinds.LastWeapon)
                    player.PendingWeapon = weapBinds.LastWeapon;

                marker.Destroy ();
                ledgeGrab_Marker = null;
                ledgeGrab_Grabbed = false;
                ledgeGrab_DoClimb = false;

                return;
            }

            double angleToMarker = AngleTo (marker);
            double angleDiff = DeltaAngle (angleToMarker, angle);
            if (angleDiff < -90)
                A_SetAngle (angleToMarker - 90, SPF_Interpolate);
            if (angleDiff >  90)
                A_SetAngle (angleToMarker + 90, SPF_Interpolate);

            let destPos = (marker.pos.XY, marker.floorZ);
            double xyStiffness = .25, xyDamping = .5 ;
            double  zStiffness = .75,  zDamping = .25;

            if ((player.cmd.buttons & BT_CROUCH) && !(player.oldbuttons & BT_CROUCH))
                ledgeGrab_DoClimb = true;

            if (ledgeGrab_DoClimb) {
                destPos.Z = marker.floorZ + (player.viewZ - pos.Z);
                xyStiffness = .1 ; xyDamping = .5;
                zStiffness  = .25;  zDamping = .5;
            }

            double viewZ = pos.Z + player.viewHeight;
            Vector3 newVel = (
                S7_Math.DampedSpring (pos.X, destPos.X, vel.X, xyStiffness, xyDamping),
                S7_Math.DampedSpring (pos.Y, destPos.Y, vel.Y, xyStiffness, xyDamping),
                S7_Math.DampedSpring (viewZ, destPos.Z, vel.Z,  zStiffness,  zDamping)
            );

            vel = newVel;
        } else if ((!ledgeGrab_Grabbed && ledgeGrab_Marker) || (ledgeGrab_Grabbed && !ledgeGrab_Marker)) {
            if (!(player.cheats & CF_PREDICTING)) {
                if (ledgeGrab_Marker)
                    ledgeGrab_Marker.Destroy ();

                if (player.ReadyWeapon is 'S7_LedgeGrabWeapon' && weapBinds.LastWeapon)
                    player.PendingWeapon = weapBinds.LastWeapon;

                ledgeGrab_Marker = null;
                ledgeGrab_Grabbed = false;
                ledgeGrab_DoClimb = false;
            }

            return;
        }

        if (!ledgeGrab_Grabbed && vel.Z < 0.0 && vel.xy.Length () < 5 && Movement_LGrab_CheckWeap () && !(player.cheats & CF_PREDICTING)) {
            let oldPos = pos;
            SetXYZ (pos + (0, 0, height));
            double ledgeHeight = GetZAt (spRadius + LedgeGrab_MaxReach, 0) - oldPos.Z;
            SetXYZ (oldPos);

            if (ledgeHeight > maxStepHeight && ledgeHeight <= LedgeGrab_MaxHeight) {
                bool MUDA;
                [MUDA, ledgeGrab_Marker] = A_SpawnItemEx ('S7_LedgeMarker', spRadius + LedgeGrab_MaxReach, zofs: ledgeHeight);

                if (ledgeGrab_Marker) {
                    let marker = S7_LedgeMarker (ledgeGrab_Marker);

                    if (Movement_LGrab_CanHold (marker, spRadius) && (marker.ceilingZ - marker.floorZ) >= 1 && marker.floorZ < self.ceilingZ &&
                        !S7_ActorExtensions.IsInVoid (marker)) {
                        vel = (0, 0, vel.Z);

                        if (!wallJump_JustJumped)
                            wallJump_JustJumped = 1;

                        GiveInventory ('S7_LedgeGrabWeapon', 1);
                        player.PendingWeapon = Weapon (FindInventory ('S7_LedgeGrabWeapon'));

                        ledgeGrab_Grabbed = true;
                    } else {
                        marker.Destroy ();
                        ledgeGrab_Marker = null;
                        ledgeGrab_Grabbed = false;
                    }
                }
            }
        }

        if (!(player.cheats & CF_PREDICTING)) {
            if (player.ReadyWeapon is 'S7_LedgeGrabWeapon' && !ledgeGrab_Grabbed && weapBinds.LastWeapon)
                player.PendingWeapon = weapBinds.LastWeapon;
            else if (!ledgeGrab_Grabbed && CheckInventory ('S7_LedgeGrabWeapon', 1))
                TakeInventory ('S7_LedgeGrabWeapon', 0x7FFFFFFF);
        }
    }

    void Movement_Sprinting () {
        Vector3 movementInput = S7_ActorExtensions.ConvertPlayerMovementInput (player.cmd.forwardmove, player.cmd.sidemove);

        if (health > 0) {
            if (!(player.cheats & CF_PREDICTING)) {
                if (sprint_Tics == -1 && CheckInventory ('S7_Stamina', 75))
                    sprint_Tics = 0;

                // Start/stop sprinting
                if (!sprint_Sprinting && sprint_Tics != -1 &&
                    (player.cmd.buttons & BT_USER1) && !playerData.dying && CheckInventory ('S7_Stamina', S7C_SprintStamina) &&
                    !CheckInventory ('S7_SoulLance_BeamGrabbed', 1) && !(self is 'S7_DracoPlayer') && !ledgeGrab_Grabbed
                ) {
                    sprint_Sprinting = true;
                    sprint_SpeedFactor = sprint_SpdFacPproc = 0.0;
                    sprint_Tics = 0;
                    sprint_OldAgility = double.NaN;
                } else if (sprint_Sprinting &&
                    (!(player.cmd.buttons & BT_USER1) || playerData.dying || CountInv ('S7_Stamina') < S7C_SprintStamina ||
                    CheckInventory ('S7_SoulLance_BeamGrabbed', 1) || ledgeGrab_Grabbed || (self is 'S7_DracoPlayer'))
                ) {
                    if (sprint_Tics < 5)
                        TakeInventory ('S7_Stamina', sprint_Tics);

                    sprint_Sprinting = false;
                    sprint_SpeedFactor = sprint_SpdFacPproc = 0.0;
                    sprint_Tics = (!CheckInventory ('S7_Stamina', 5)) ? -1 : 0;
                }

                if (sprint_Sprinting) {
                    if (player.onground) {
                        bool isMoving = !(movementInput.XY dot movementInput.XY ~== 0.);

                        if (sprint_Tics++ >= 5 && isMoving) {
                            sprint_Tics = 0;

                            TakeInventory ('S7_Stamina', S7C_SprintStamina);
                        } else if (isMoving && !(vel.XY dot vel.XY ~== 0.))
                            sprint_Tics++;
                    }
                }

                double newAgility = xpSys.GetStat (S7Stat_Agility);
                if (newAgility != sprint_OldAgility) {
                    if (newAgility > 0) // Just so it doesn't explode
                        sprint_SpdFacPproc = 0.1 * log (newAgility);
                    else
                        sprint_SpdFacPproc = 0;
                    sprint_OldAgility = newAgility;
                }
            }

            if (movementInput.Z ~== 1)
                sprint_SpeedFactor = Clamp (0.5 + sprint_SpdFacPproc, 0.0, 2.5);
            else
                sprint_SpeedFactor = Clamp (0.5 + (0.5 + sprint_SpdFacPproc) * 2, 0.0, 2.5);
        }
    }

    void Movement_FallTeching () {
        if (player.cheats & CF_PREDICTING)
            return;

        double horzSpeedMax = Teching_MaxHorzSpeed * Teching_MaxHorzSpeed;
        if (teching_Active && teching_HorzVelKilled)
            horzSpeedMax = 5 * 5;
        bool horzSpeedOverMax = (vel.XY dot vel.XY) > horzSpeedMax;

        if (teching_Active) {
            if (!(player.cmd.buttons & BT_CROUCH) || player.onground || horzSpeedOverMax || ledgeGrab_Grabbed)
                teching_Active = false;
            else {
                if (vel.Z < -0.5)
                    vel.Z *= 0.25;

                if (vel.XY ~== (0, 0))
                    teching_HorzVelKilled = true;

                vel.XY += (
                    teching_VelXKillSpeed = S7_Math.DampedSpring (vel.X, 0, teching_VelXKillSpeed, 0.25, 0.5),
                    teching_VelYKillSpeed = S7_Math.DampedSpring (vel.Y, 0, teching_VelYKillSpeed, 0.25, 0.5)
                );
                player.vel = vel.XY;
            }
        }

        if ((player.cmd.buttons & BT_CROUCH) && !(player.oldbuttons & BT_CROUCH)) {
            if (!teching_Active && !player.onground && !horzSpeedOverMax && !ledgeGrab_Grabbed) {
                teching_Active = true;
                teching_HorzVelKilled = false;
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