/** Credits:
 ** Normal/visor HUD:
 **   Code: Chronos "phantombeta" Ouroboros
 **   Graphics: Nintendo/Retro Studios, Patrik, LanHikariDS, Chronos "phantombeta" Ouroboros
 ** Fullscreen HUD:
 **   Code: Chronos "phantombeta" Ouroboros
 **   Graphics: Chronos "phantombeta" Ouroboros, Captain J (Cartridges sprites)
**/
class Se7evidasStatusBar : S7_BaseS7HUD {
    // Constants
    const RADAR_SCALE = 10.0;
    const RADAR_MAXDIST = 750.0;
    const RADAR_RADIUS = 50.0;

    // Fonts
    HUDFont mSmallFont;
    HUDFont mBigFont;
    HUDFont mNormalHUDFont;
    HUDFont mFscreenHUDFont;
    HUDFont mRadarMarkers;
    // Interpolators
    DynamicValueInterpolator mHealthInterpolator;
    DynamicValueInterpolator mArmorInterpolator;
    DynamicValueInterpolator mStaminInterpolator;
    DynamicValueInterpolator mCashInterpolator;
    DynamicValueInterpolator mLsrRfInterpolator;
    DynamicValueInterpolator mLPPInterpolator1;
    DynamicValueInterpolator mLPPInterpolator2;
    // Misc
    InventoryBarState diparms;
    Array<S7_FScreenSBarAmmoBar> FScreenAmmoBars;

    override void Init () {
        // Initialize the statusbar
        Super.Init ();
        SetSize (0, 320, 200);
        fullscreenOffsets = true;

        // Initialize the fonts
        mSmallFont = HUDFont.Create ("SmallFont");
        mBigFont = HUDFont.Create ("BigFont");
        Font fnt = "S7HUDFONT";
        mNormalHUDFont = HUDFont.Create (fnt, fnt.GetCharWidth ("0"), true, 1, 1);
        fnt = "S7FSHUDFNT.lmp";
        mFscreenHUDFont = HUDFont.Create (fnt, 0, false, 1, 1);
        fnt = "Fonts/MapMarkers.FON2";
        mRadarMarkers = HUDFont.Create (fnt, fnt.GetCharWidth ("A"), true, 1, 1);
        // Initialize the interpolators
        mHealthInterpolator = DynamicValueInterpolator.Create (0, 0.25, 1, 8);
        mArmorInterpolator  = DynamicValueInterpolator.Create (0, 0.25, 1, 8);
        mStaminInterpolator = DynamicValueInterpolator.Create (0, 0.25, 1, 8);
        mCashInterpolator   = DynamicValueInterpolator.Create (0, 0.25, 1, 1 << 28);
        mLsrRfInterpolator = DynamicValueInterpolator.Create (0, 0.25, 1, 25);
        mLPPInterpolator1  = DynamicValueInterpolator.Create (0, 0.25, 1, 25);
        mLPPInterpolator2  = DynamicValueInterpolator.Create (0, 0.25, 1, 25);
        // Initialize the inventory bar
        diparms = InventoryBarState.Create ();
        // Populate the fullscreen statusbar ammo bars list
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ("S7_Raptor", "S7_RaptorClip", "Inventory", 16, "graphics/HUD/Cartridges/S7H9MM.png", -10, -5, -20, -18));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ("S7_TEC9", "S7_TEC9Clip", "Inventory", 32, "graphics/HUD/Cartridges/S7H9MM.png", -10, -4, -20, -18));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ("S7_Revolver", "S7_RevolverClip", "Inventory", 6, "graphics/HUD/Cartridges/S7H44M.png", -11, -7, -23));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ("S7_AMG", "S7_AMGMag", "Inventory", 35, "graphics/HUD/Cartridges/S7H762MM.png", -11, -4, -27, -26, -25));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ("S7_ManxCarbine", "S7_ManxCarbineClip", "Inventory", 23, "graphics/HUD/Cartridges/S7H9MM.png", -10, -4, -20, -18));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ("S7_Shotgun", "S7_ShotgunMag", "Inventory", 10, "graphics/HUD/Cartridges/S7H20GA.png", -16, -8, -32, -31));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ("S7_HitterSMG", "S7_HitterSMGClip", "Inventory", 62, "graphics/HUD/Cartridges/S7H45ACP.png", -10, -2, -20, -19, -18));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ("S7_GrenadeWeap", "S7_GrenadeCount", "Inventory", 15, "graphics/HUD/Throwables/S7TGRICN.png", -15, -8, -22, -24));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ("S7_ConquerorRifle", "S7_ConquerorRifleClip", "Inventory", 15, "graphics/HUD/Cartridges/S7H45WW.png", -14, -7, -43, -41));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ("S7_AK47", "S7_AK47Clip", "Inventory", 30, "graphics/HUD/Cartridges/S7H762MM.png", -11, -4, -27, -26));
    }

    override void NewGame () {
        Super.NewGame ();

        mHealthInterpolator.Reset (0);
        mArmorInterpolator.Reset  (0);
        mStaminInterpolator.Reset (0);
        mCashInterpolator.Reset   (0);
        mLsrRfInterpolator.Reset (0);
        mLPPInterpolator1.Reset  (0);
        mLPPInterpolator2.Reset  (0);
    }

    override void Tick () {
        super.Tick ();

        mHealthInterpolator.Update (CPlayer.health);
        mArmorInterpolator.Update  (GetS7ArmorAmount ());
        mStaminInterpolator.Update (GetStamina (false));
        mCashInterpolator.Update   (GetAmount ("S7_Cash"));
        mLsrRfInterpolator.Update (GetAmount ("S7_FauchardMag"));
        mLPPInterpolator1.Update  (GetAmount ("S7_LaserPewPewClip"));
        mLPPInterpolator2.Update  (GetAmount ("S7_LaserPewPewClipSecond"));
    }

    override void Draw (int state, double TicFrac) {
        Super.Draw (state, TicFrac);

        if (!CPlayer)
            return;

        if (state == HUD_StatusBar) {
            BeginHUD (1.0, true, 320, 200);
            DrawMainBar (TicFrac, S7_BasePlayer (CPlayer.mo));
        } else if (state == HUD_Fullscreen) {
            BeginHUD (1.0, false, 320, 200);
            DrawFullScreenBar (TicFrac, S7_BasePlayer (CPlayer.mo));
        }
    }

    protected void DrawRadar (S7_BasePlayer pPawn, Vector2 radarPos, double TicFrac) {
        if (CheckInventory ("S7_UpgradeRadar", 1)) {
            DrawImage ("graphics/HUD/Radar/S7RDR0.png", radarPos, DI_SCREEN_RIGHT_TOP | DI_ITEM_RIGHT_TOP);

            ThinkerIterator actorFinder = ThinkerIterator.Create ("Actor", Thinker.STAT_DEFAULT);
            Actor curActor;

            double angleCos = Cos (-pPawn.angle), angleSin = Sin (-pPawn.angle);
            Vector3 pPawnXYPos = (pPawn.prev + (TicFrac * (pPawn.pos - pPawn.prev)));
            while (curActor = Actor (actorFinder.Next ())) {
                if (abs (pPawn.Distance2D (curActor)) > RADAR_MAXDIST) // Skip any actors that are too far away
                    continue;

                int colour;
                if (curActor.bIsMonster) {
                    if (curActor.health > 0)
                        colour = (curActor.isFriend (pPawn)) ? Font.CR_GREEN : Font.CR_RED;
                    else
                        colour = Font.CR_DARKGRAY;
                } else if (curActor.bSpecial && curActor is "Key")
                    colour = Font.CR_GOLD;
                else
                    continue;

                // Coords
                Vector3 actorPos = (curActor.prev + (TicFrac * (curActor.pos - curActor.prev)));
                Vector2 worldPos = pPawnXYPos.xy - actorPos.xy, screenPos;
                worldPos /= RADAR_SCALE;
                screenPos.x = (worldPos.x * angleSin + worldPos.y * angleCos);
                screenPos.y = (worldPos.x * angleCos - worldPos.y * angleSin);

                if (screenPos.Length () >= RADAR_RADIUS)
                    continue;

                // Draw
                DrawString (mRadarMarkers, "B", (radarPos.x - 50, radarPos.y + 50) + screenPos, DI_SCREEN_RIGHT_TOP | DI_ITEM_CENTER | DI_TEXT_ALIGN_CENTER | DI_NOSHADOW, colour);
            }//level.time
            DrawString (mRadarMarkers, "A", (radarPos.x - 50, radarPos.y + 50), DI_SCREEN_RIGHT_TOP | DI_ITEM_CENTER | DI_TEXT_ALIGN_CENTER | DI_NOSHADOW, Font.CR_BLUE);
        }
    }

    protected void DrawMainBar (double TicFrac, S7_BasePlayer pPawn) {
        DrawImage ("HELMTOP", (0, 0), DI_ITEM_TOP | DI_SCREEN_HCENTER);
        DrawImage ("HELMBTML", (0, 0), DI_ITEM_LEFT_BOTTOM | DI_SCREEN_LEFT_BOTTOM);
        DrawImage ("HELMBTMR", (0, 0), DI_ITEM_RIGHT_BOTTOM | DI_SCREEN_RIGHT_BOTTOM);
        if (!CheckInventory ("S7_DisableHud", 1)) {
            alpha = 0.75;

            DrawImage ("graphics/HUD/Normal/HOLOBARSNONE.png", (0, 27), DI_ITEM_TOP | DI_SCREEN_HCENTER);

            string energyImg;
            if (CheckHealth (75, true))
                energyImg = "graphics/HUD/Normal/HOLOBARSGREEN.png";
            else if (CheckHealth (50, true))
                energyImg = "graphics/HUD/Normal/HOLOBARSYELLOW.png";
            else if (CheckHealth (25, true))
                energyImg = "graphics/HUD/Normal/HOLOBARSORANGE.png";
            else
                energyImg = "graphics/HUD/Normal/HOLOBARSRED.png";
            DrawImage (energyImg, (0, 29), DI_ITEM_TOP | DI_SCREEN_HCENTER);

            // Draw health/armor bars
            DrawBar ("HOLOBR00", "HOLOBR01", mHealthInterpolator.GetValue (), pPawn.GetMaxHealth (true), (0, 36), 0, 0, DI_ITEM_TOP | DI_SCREEN_HCENTER);
            DrawBar ("HOLOBR10", "HOLOBR01", mArmorInterpolator.GetValue (), GetS7ArmorSaveAmount (), (0, 41), 0, 0, DI_ITEM_TOP | DI_SCREEN_HCENTER);
            // Draw health/armor numbers
            DrawString (mNormalHUDFont, FormatNumber (mHealthInterpolator.GetValue (), 1, 3), (-33, 50), DI_SCREEN_HCENTER | DI_NOSHADOW, Font.FindFontColor ("HUD_Health"));
            DrawString (mNormalHUDFont, FormatNumber (mArmorInterpolator.GetValue (), 1, 3), (33, 50), DI_TEXT_ALIGN_RIGHT | DI_SCREEN_HCENTER | DI_NOSHADOW, Font.FindFontColor ("HUD_Armour"));
        }
    }

    protected void DrawFullScreenBar (double TicFrac, S7_BasePlayer pPawn) {
        // Icons
        DrawImage ("graphics/HUD/Fullscreen/S7HLTH.png", (11,  -7), DI_ITEM_LEFT_BOTTOM);
        DrawImage ("graphics/HUD/Fullscreen/S7ARMR.png", (11, -25), DI_ITEM_LEFT_BOTTOM);
        DrawImage ("graphics/HUD/Fullscreen/S7STMN.png", (11, -42), DI_ITEM_LEFT_BOTTOM);
        // Bar frames
        DrawImage ("graphics/HUD/Fullscreen/S7BARFR0.png", (28, -12), DI_ITEM_LEFT_BOTTOM);
        DrawImage ("graphics/HUD/Fullscreen/S7BARFR0.png", (28, -30), DI_ITEM_LEFT_BOTTOM);
        DrawImage ("graphics/HUD/Fullscreen/S7BARFR0.png", (28, -47), DI_ITEM_LEFT_BOTTOM);
        // Bars
        DrawBar ("graphics/HUD/Fullscreen/S7HLTHBR.png", "S7BARBK0", mHealthInterpolator.GetValue (), pPawn.GetMaxHealth (true),   (29, -13), 0, 0, DI_ITEM_LEFT_BOTTOM);
        DrawBar ("graphics/HUD/Fullscreen/S7ARMRBR.png", "S7BARBK0", mArmorInterpolator.GetValue  (), GetS7ArmorSaveAmount (),     (29, -31), 0, 0, DI_ITEM_LEFT_BOTTOM);
        DrawBar ("graphics/HUD/Fullscreen/S7STMNBR.png", "S7BARBK0", mStaminInterpolator.GetValue (), GetStamina (true),           (29, -48), 0, 0, DI_ITEM_LEFT_BOTTOM);
        // Strings
        DrawString (mFScreenHUDFont, "Cash: ", (11, -66), DI_TEXT_ALIGN_LEFT | DI_NOSHADOW, Font.CR_WHITE);
        // Numbers
        DrawString (mFScreenHUDFont, FormatNumber (mHealthInterpolator.GetValue (), 1,  5), (81, -18), DI_TEXT_ALIGN_LEFT  | DI_NOSHADOW, Font.CR_WHITE);
        DrawString (mFScreenHUDFont, FormatNumber (mArmorInterpolator.GetValue  (), 1,  5), (81, -36), DI_TEXT_ALIGN_LEFT  | DI_NOSHADOW, Font.CR_WHITE);
        DrawString (mFScreenHUDFont, FormatNumber (mStaminInterpolator.GetValue (), 1,  5), (81, -53), DI_TEXT_ALIGN_LEFT  | DI_NOSHADOW, Font.CR_WHITE);
        DrawString (mFScreenHUDFont, FormatNumber (mCashInterpolator.GetValue   (), 1, 10), (77, -66), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
        // Selected inv
        if (pPawn.InvSel) {
            DrawInventoryIcon (pPawn.InvSel, (24, -70));
            DrawString (mFscreenHUDFont, FormatNumber (pPawn.InvSel.Amount), (37, -76), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
        }

        // Enemy health bar
        CVar enHPBarOn = CVar.GetCvar ("S7_EnemyHPBar_On", CPlayer);
        if (enHPBarOn && enHPBarOn.GetInt ()) {
            let enemy = pPawn.playerLineTarget;

            if (enemy) {
                bool drawHPBar = false;
                int health, maxHealth;
                string nameTag;

                if (enemy.bIsMonster && enemy.health > 0 && enemy.bShootable && !enemy.bNoDamage && !enemy.bInvulnerable) {
                    health = enemy.health;
                    maxHealth = enemy.SpawnHealth ();
                    nameTag = enemy.GetTag ();

                    drawHPBar = true;
                }

                if (drawHPBar) {
                    DrawBar ("ENHPBFG1", "ENHPBBG1", enemy.health, enemy.SpawnHealth (), (0, 4), 0, 0, DI_ITEM_TOP | DI_SCREEN_HCENTER);

                    CVar enHPBar_HPDisp = CVar.GetCvar ("S7_EnemyHPBar_HPDisp", CPlayer);
                    if (enHPBar_HPDisp) {
                        if (enHPBar_HPDisp.GetInt () >= 2)
                            DrawString (mSmallFont, String.Format ("%d%%", (double (health) / maxHealth) * 100), (0, 8.0), DI_SCREEN_HCENTER | DI_TEXT_ALIGN_CENTER | DI_NOSHADOW, Font.CR_DARKGRAY);
                        else if (enHPBar_HPDisp.GetInt () == 1) {
                            DrawString (mSmallFont, FormatNumber (maxHealth, 0, 10), (4, 8.0), DI_SCREEN_HCENTER | DI_TEXT_ALIGN_LEFT | DI_NOSHADOW, Font.CR_DARKGRAY);
                            DrawString (mSmallFont, "/", (0, 8.0), DI_SCREEN_HCENTER | DI_TEXT_ALIGN_CENTER | DI_NOSHADOW, Font.CR_DARKGRAY);
                            DrawString (mSmallFont, FormatNumber (health, 0, 10), (-4, 8.0), DI_SCREEN_HCENTER | DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_DARKGRAY);
                        }
                    }

                    CVar enHPBar_Nametag = CVar.GetCvar ("S7_EnemyHPBar_NametagOn", CPlayer);
                    if (enHPBar_Nametag && enHPBar_Nametag.GetInt ())
                        DrawString (mSmallFont, nameTag, (0, 20.0), DI_SCREEN_HCENTER | DI_ITEM_TOP | DI_TEXT_ALIGN_CENTER | DI_NOSHADOW, Font.CR_DARKGRAY);
                }
            }
        }

        DrawRadar (pPawn, (-40, 2), TicFrac);

        // Ammo bars
        if (CPlayer.ReadyWeapon) {
            if (CheckWeaponSelected ("S7_SSG")) {
                // Draw ammo pool count
                DrawString (mFScreenHUDFont, "Pool:      ", (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                DrawString (mFScreenHUDFont, FormatNumber (GetAmount (CPlayer.ReadyWeapon.AmmoType2), 1, 5), (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);

                // Draw shells
                if (CheckInventory ("S7_SSGRightLoadedToken", 1)) DrawImage ("graphics/HUD/Cartridges/S7H12GA.png", (-17, -29), DI_ITEM_LEFT_TOP);
                if (CheckInventory ("S7_SSGLeftLoadedToken",  1)) DrawImage ("graphics/HUD/Cartridges/S7H12GA.png", (-31, -29), DI_ITEM_LEFT_TOP);
            } else if (CheckWeaponSelected ("S7_Fauchard")) {
                // Draw ammo pool count
                DrawString (mFScreenHUDFont, "Pool:      ", (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                DrawString (mFScreenHUDFont, FormatNumber (GetAmount (CPlayer.ReadyWeapon.AmmoType2), 1, 5), (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);

                // Draw ammo bar
                DrawBar ("graphics/HUD/Fullscreen/S7LRABFG.png", "graphics/HUD/Fullscreen/S7LRABBG.png",
                    mLsrRfInterpolator.GetValue (), GetMaxAmount ("S7_FauchardMag"), (-5, -5), 0, SHADER_REVERSE, DI_ITEM_RIGHT_BOTTOM);
            } else if (CheckWeaponSelected ("S7_LaserPewPew")) {
                // Draw ammo pool count
                DrawString (mFScreenHUDFont, "Pool:      ", (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                DrawString (mFScreenHUDFont, FormatNumber (GetAmount (CPlayer.ReadyWeapon.AmmoType2), 1, 5), (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);

                // Draw ammo bar(s)
                let lppWeap = S7_LaserPewPew (CPlayer.ReadyWeapon);
                bool hasTwo = CheckInventory ("S7_LaserPewPewSecond", 1);

                if (hasTwo && lppWeap.akimbo) {
                    DrawImage ("graphics/HUD/Fullscreen/FireMode/BLSDual.png", (5, 5), DI_ITEM_LEFT_TOP);

                    DrawBar ("S7LPPDFG", "S7LPPDBG", mLPPInterpolator1.GetValue (), GetMaxAmount ("S7_LaserPewPewClip"), (-5, -5), 0, SHADER_REVERSE, DI_ITEM_RIGHT_BOTTOM);
                    DrawBar ("S7LPPDFG", "S7LPPDBG", mLPPInterpolator2.GetValue (), GetMaxAmount ("S7_LaserPewPewClipSecond"), (-5, -23), 0, SHADER_REVERSE, DI_ITEM_RIGHT_BOTTOM);
                } else {
                    if (hasTwo)
                        DrawImage ("graphics/HUD/Fullscreen/FireMode/BLSCycle.png", (5, 5), DI_ITEM_LEFT_TOP);

                    DrawBar ("graphics/HUD/Fullscreen/S7LRABFG.png", "graphics/HUD/Fullscreen/S7LRABBG.png",
                        mLPPInterpolator1.GetValue (), GetMaxAmount ("S7_LaserPewPewClip"), (-5, -5), 0, SHADER_REVERSE, DI_ITEM_RIGHT_BOTTOM);
                }
            } else if (CheckWeaponSelected ("S7_Thumper")) {
                static const string ThumperGrenNames [] = { "", "Explosive", "Fragmentation", "Incendiary", "Flare", "Clusterbomb", "Nailbomb", "Nerve Gas" };
                static const int ThumperGrenColors [] = { Font.CR_WHITE, Font.CR_ORANGE, Font.CR_GREEN, Font.CR_DARKRED, Font.CR_WHITE, Font.CR_BLUE, Font.CR_YELLOW, Font.CR_BLACK };

                // Draw ammo pools count
                DrawString (mFScreenHUDFont, "Pool:      ", (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                DrawString (mFScreenHUDFont, FormatNumber (GetAmount ("S7_Thumper_PUnified"), 1, 5), (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);

                for (int i = 1; i < ThumperGrenNames.Size (); i++) {
                    bool selected = GetAmount ("S7_ThumperSelectedPool") == (i - 1);
                    string poolText = String.Format (selected ? ">%s:      " : "%s:      ", ThumperGrenNames [i]);
                    int colour = (selected ? Font.CR_RED : ThumperGrenColors [i]);
                    DrawString (mFScreenHUDFont, poolText, (-6, -50 - (7 * (8-i))), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, colour);
                    DrawString (mFScreenHUDFont, FormatNumber (GetAmount (S7_Thumper.PoolNames [i]), 1, 5), (-6, -50 - (7 * (8-i))), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, colour);
                }
                for (int i = 0; i < 5; i++) {
                    int grenType = GetAmount (String.Format ("S7_ThumperMag%d", i + 1));
                    if (grenType == S7_TH_None)
                        continue;

                    DrawImage ("graphics/HUD/Cartridges/S7H50M0.png", (-26 - 22 * i, -43), DI_ITEM_LEFT_TOP);
                    DrawImage (String.Format ("graphics/HUD/Cartridges/S7H50M%d.png", grenType), (-26 - 22 * i, -17), DI_ITEM_LEFT_TOP);
                }
            } else {
                let weap = S7_BaseWeapon (CPlayer.ReadyWeapon);
                if (weap && weap.fireModeIcon != FMI_None) {
                    string icon;

                    if (weap.fireModeIcon == FMI_SemiAuto)
                        icon = "graphics/HUD/Fullscreen/FireMode/SemiAuto.png";
                    else if (weap.fireModeIcon == FMI_BurstFire)
                        icon = "graphics/HUD/Fullscreen/FireMode/BrstFire.png";
                    else if (weap.fireModeIcon == FMI_FullAuto)
                        icon = "graphics/HUD/Fullscreen/FireMode/FullAuto.png";
                    else
                        icon = "";

                    if (!(icon == ""))
                        DrawImage (icon, (5, 5), DI_ITEM_LEFT_TOP);
                }

                for (int i = 0; i < FScreenAmmoBars.Size (); i++) {
                    if (CheckWeaponSelected (FScreenAmmoBars [i].weap)) {
                        let bar = FScreenAmmoBars [i];

                        // Draw ammo pool count
                        int poolAmount = -1;
                        if (bar.poolType == "Inventory" && CPlayer.ReadyWeapon.AmmoType2)
                            poolAmount = GetAmount (CPlayer.ReadyWeapon.AmmoType2);
                        else if (bar.poolType != "Inventory" && bar.poolType)
                            GetAmount (bar.poolType);

                        if (poolAmount >= 0) {
                            DrawString (mFScreenHUDFont, "Pool:      ", (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                            DrawString (mFScreenHUDFont, FormatNumber (poolAmount, 1, 5), (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                        }

                        // Draw in-mag count
                        int maxX = min (bar.xPositions.Size (), GetAmount (bar.magType));
                        for (int x = 0; x < maxX; x++)
                            DrawImage (bar.sprite, (bar.xPositions [x], bar.yPositions [x]), DI_ITEM_LEFT_TOP);

                        break;
                    }
                }
            }
        }
    }
}