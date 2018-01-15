extend class S7_BasePlayer {
    void Movement_Dodging () {
        if (health > 0) {
            // Dodging
            if (playerData.dodgeCooldown <= 0) { // If dodgeCooldown is less than or equal to 0...
                // If the player tapped user2, isn't sprinting, didn't have his Soul Lance beam grabbed and has at least S7C_DodgeStamina stamina...
                if ((player.cmd.buttons & BT_USER2) && !(player.oldbuttons & BT_USER2) &&
                    !playerData.sprinting && !CheckInventory ("S7_SoulLance_BeamGrabbed", 1) && CheckInventory ("S7_Stamina", S7C_DodgeStamina)) {
                    int forwardMove = Clamp (player.cmd.forwardmove / 12800, -1.0, 1.0);
                    int sideMove = Clamp (player.cmd.sidemove / 10240, -1.0, 1.0);

                    if (forwardMove != 0 || sideMove != 0) { // If the player is trying to move
                        TakeInventory ("S7_Stamina", S7C_DodgeStamina); // Take S7C_DodgeStamina stamina

                        A_PlaySound ("Player/Dodge", CHAN_Body); // Play the dodge sound

                        GiveInventory ("S7_PowerDodgeEffects", 1);
                        Thrust (18, (angle - 90) + atan2 (forwardMove, sideMove));
                        vel.Z += -85;

                        playerData.dodgeCooldown = S7_DodgeCooldown;
                    }
                }
            } else
                playerData.dodgeCooldown--;
        } else
            TakeInventory ("S7_PowerDodgeEffects", 0x7FFFFFFF);
    }

    void Movement_MultiJump () {
        if (!level.IsJumpingAllowed () || health <= 0 || playerData.wjumpJustJumped || CheckInventory ("S7_SoulLance_BeamGrabbed", 1))
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
    const WallJumpZVel = 10.0;
    void Movement_WallJump () {
        if (playerData.wjumpJustJumped)
            playerData.wjumpJustJumped--;

        if (health <= 0 || playerData.wjumpJustJumped || CheckInventory ("S7_SoulLance_BeamGrabbed", 1))
            return;

        Actor marker, puff;
        if (player.cmd.forwardmove < 0 && (player.cmd.buttons & BT_JUMP) && !(player.oldbuttons & BT_JUMP) && (pos.Z - GetZAt ()) >= 16.0) {
            Vector3 normal, randomVec;
            double xyLen = cos (-pitch);
            normal.x = xyLen * cos (-angle);
            normal.y = xyLen * sin (angle);
            normal.z = sin (-pitch);
            normal = normal.Unit ();
            do {
                randomVec = (frandom (-1, 1), frandom (-1, 1), frandom (-1, 1)).Unit();
            } while (randomVec == normal);
            Vector3 normalPerp1 = (normal cross randomVec).Unit ();
            Vector3 normalPerp2 = (normal cross normalPerp1).Unit ();
            Vector3 center = pos + (0, 0, (height / 2) + attackZOffset);
            Vector3 point1, point2;
            point1 = center + cos (45) * normalPerp1 + sin (45) * normalPerp2;
            point2 = center + cos (-90) * normalPerp1 + sin (-90) * normalPerp2;

            for (int i = 0; i < WallJumpHitCount + 1; i++) {
                double hitAngle = angle + (WallJumpHitInterval * ((-1) ^ ((i+1) & 1) * ((i+1) >> 1)));

                for (int j = 0; j < WallJumpHitCount + 1; j++) {
                    double hitPitch = pitch + (WallJumpHitInterval * ((-1) ^ ((j+1) & 1) * ((j+1) >> 1)));
                    puff = LineAttack (hitAngle, 24, hitPitch, 0, "None", "S7_WallCheckPuff", LAF_NoRandomPuffZ | LAF_NoImpactDecal, null);
                    if (puff && (puff.pos.Z - puff.GetZAt ()) >= 0.5) {
                        Vector3 hitPos1, hitPos2, hitPos3;
                        // Get hit position 1
                        hitPos1 = puff.pos;
                        puff.Destroy ();

                        // Get hit position 2
                        marker = Spawn ("S7_WalljumpMarker", point1);
                        puff = marker.LineAttack (hitAngle, 32, hitPitch, 0, "None", "S7_WallCheckPuff", LAF_NoRandomPuffZ | LAF_NoImpactDecal, null);
                        if (!puff) { marker.Destroy (); continue; }
                        hitPos2 = puff.pos; puff.Destroy ();
                        marker.Destroy ();

                        // Get hit position 3
                        marker = Spawn ("S7_WalljumpMarker", point2);
                        puff = marker.LineAttack (hitAngle, 32, hitPitch, 0, "None", "S7_WallCheckPuff", LAF_NoRandomPuffZ | LAF_NoImpactDecal, null);
                        if (!puff) { marker.Destroy (); continue; }
                        hitPos3 = puff.pos; puff.Destroy ();
                        marker.Destroy ();

                        Vector3 wallNormal = ((hitPos3 - hitPos2) cross (hitPos1 - hitPos2)).Unit ();
                        if (wallNormal dot normal > 0) wallNormal = -wallNormal;
                        Vector3 velChange = wallNormal;
                        velChange.X *= 10; velChange.Y *= 10;

                        if (velChange.Z == 0.0)     velChange.Z  =  WallJumpZVel;
                        else if (velChange.Z < 0.0) velChange.Z *= -WallJumpZVel;
                        else                        velChange.Z *=  WallJumpZVel;

                        playerData.wjumpJustJumped = S7C_WJumpDelay;
                        vel = velChange;
                        A_SetPitch (VectorAngle (wallNormal.XY.Length (), wallNormal.Z), SPF_ForceClamp | SPF_Interpolate);
                        A_SetAngle (VectorAngle (wallNormal.X, wallNormal.Y), SPF_ForceClamp | SPF_Interpolate);
                        return;
                    }
                }
            }
        }
    }

    void Movement_Sprinting () {
        double forwardMove = abs (player.cmd.forwardmove) / 12800;
        double sideMove = abs (player.cmd.sidemove) / 10240;

        if (health > 0) {
            // This is here just in case something fucks up and the player keeps the sprint "weapon" for some reason.
            if (player.ReadyWeapon is "S7_SprintWeapon" && !playerData.sprinting)
                player.PendingWeapon = weapBinds.LastWeapon;
            else if (!playerData.sprinting && CheckInventory ("S7_SprintWeapon", 1))
                TakeInventory ("S7_SprintWeapon", 0x7FFFFFFF);

            if (playerData.sprintTics == -1 && CheckInventory ("S7_Stamina", 75))
                playerData.sprintTics = 0;

            // Start/stop sprinting
            if (!playerData.sprinting && playerData.sprintTics != -1 &&
                (player.cmd.buttons & BT_USER1) && !playerData.dying && CheckInventory ("S7_Stamina", S7C_SprintStamina) && !CheckInventory ("S7_SoulLance_BeamGrabbed", 1)
                ) {
                playerData.sprinting = true;
                playerData.sprintSpeedFactor = playerData.sprintSpdFacPproc = 0.0;
                playerData.sprintTics = 0;
                playerData.oldAgility = double.NaN;

                GiveInventory ("S7_SprintWeapon", 1);
                player.PendingWeapon = Weapon (FindInventory ("S7_SprintWeapon"));
            } else if (playerData.sprinting &&
                (!(player.cmd.buttons & BT_USER1) || playerData.dying || CountInv ("S7_Stamina") < S7C_SprintStamina) || CheckInventory ("S7_SoulLance_BeamGrabbed", 1)
                ) {
                if (playerData.sprintTics < 5)
                    TakeInventory ("S7_Stamina", playerData.sprintTics);

                playerData.sprinting = false;
                playerData.sprintSpeedFactor = playerData.sprintSpdFacPproc = 0.0;
                playerData.sprintTics = (!CheckInventory ("S7_Stamina", 5)) ? -1 : 0;

                player.PendingWeapon = weapBinds.LastWeapon;
            }
            if (playerData.sprinting && player.ReadyWeapon is "S7_SprintWeapon") {
                if (playerData.sprintTics++ >= 5 && (forwardMove != 0.0 || sideMove != 0.0)) {
                    playerData.sprintTics = 0;
                    TakeInventory ("S7_Stamina", S7C_SprintStamina);
                } else if ((forwardMove != 0.0 || sideMove != 0.0) && (vel.X != 0.0 || vel.Y != 0.0))
                    playerData.sprintTics++;

                double newAgility = xpSys.GetStat (S7Stat_Agility);
                if (newAgility != playerData.oldAgility) {
                    if (newAgility > 0) // Just so it doesn't explode
                        playerData.sprintSpdFacPproc = 0.1 * log (newAgility);
                    else
                        playerData.sprintSpdFacPproc = 0;
                    playerData.oldAgility = newAgility;
                }

                if (forwardMove > 0.5 || sideMove > 0.5)
                    playerData.sprintSpeedFactor = Clamp (0.5 + playerData.sprintSpdFacPproc, 0.0, 2.5);
                else
                    playerData.sprintSpeedFactor = Clamp (0.5 + (0.5 + playerData.sprintSpdFacPproc) * 2, 0.0, 2.5);
            }
        }
    }
}