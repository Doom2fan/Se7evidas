/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2019 Chronos "phantombeta" Ouroboros
 *  Copyright (C) 2018      Gutawer (Circle-Line intersection code)
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

/** Credits:
 ** Normal/visor HUD:
 **   Code: Chronos "phantombeta" Ouroboros
 **   Graphics: Nintendo/Retro Studios, Patrik, LanHikariDS, Chronos "phantombeta" Ouroboros
 ** Fullscreen HUD:
 **   Code: Chronos "phantombeta" Ouroboros
 **   Graphics: Chronos "phantombeta" Ouroboros, Captain J (Cartridges sprites)
**/
class Se7evidasStatusBar : S7_BaseStatusbar {
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
    DynamicValueInterpolator mPlsmMGInterpolator;
    DynamicValueInterpolator mIonCannonInterpolator;
    DynamicValueInterpolator mLPPInterpolator1;
    DynamicValueInterpolator mLPPInterpolator2;
    DynamicValueInterpolator mThrowableForce;
    // Misc
    InventoryBarState diparms;
    Array<S7_FScreenSBarAmmoBar> FScreenAmmoBars;

    override void Init () {
        // Initialize the statusbar
        Super.Init ();
        SetSize (0, 320, 200);
        fullscreenOffsets = true;

        // Initialize the fonts
        mSmallFont = HUDFont.Create ('SmallFont');
        mBigFont = HUDFont.Create ('BigFont');
        Font fnt = 'S7HUDFONT';
        mNormalHUDFont = HUDFont.Create (fnt, fnt.GetCharWidth ("0"), true, 1, 1);
        fnt = 'S7FSHUDFNT.lmp';
        mFscreenHUDFont = HUDFont.Create (fnt, 0, false, 1, 1);
        fnt = 'Fonts/MapMarkers.FON2';
        mRadarMarkers = HUDFont.Create (fnt, fnt.GetCharWidth ("A"), true, 1, 1);
        // Initialize the interpolators
        mHealthInterpolator = DynamicValueInterpolator.Create (0, 0.25, 1, 8);
        mArmorInterpolator  = DynamicValueInterpolator.Create (0, 0.25, 1, 8);
        mStaminInterpolator = DynamicValueInterpolator.Create (0, 0.25, 1, 8);
        mCashInterpolator   = DynamicValueInterpolator.Create (0, 0.25, 1, 1 << 28);
        mLsrRfInterpolator = DynamicValueInterpolator.Create (0, 0.25, 1, 25);
        mPlsmMGInterpolator = DynamicValueInterpolator.Create (0, 0.25, 1, 25);
        mIonCannonInterpolator = DynamicValueInterpolator.Create (0, 0.25, 1, 25);
        mLPPInterpolator1  = DynamicValueInterpolator.Create (0, 0.25, 1, 25);
        mLPPInterpolator2  = DynamicValueInterpolator.Create (0, 0.25, 1, 25);
        mThrowableForce    = DynamicValueInterpolator.Create (0, 0.25, 1,  8);
        // Initialize the inventory bar
        diparms = InventoryBarState.Create ();
        // Populate the fullscreen statusbar ammo bars list
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ('S7_Raptor', 'S7_RaptorClip', "Inventory", 24, "graphics/HUD/Cartridges/S7H9MM.png", -10, -5, -20, -18));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ('S7_TEC9', 'S7_TEC9Clip', "Inventory", 32, "graphics/HUD/Cartridges/S7H9MM.png", -10, -4, -20, -18));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ('S7_Revolver', 'S7_RevolverClip', "Inventory", 6, "graphics/HUD/Cartridges/S7H44M.png", -11, -7, -23));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ('S7_AMG', 'S7_AMGMag', "Inventory", 35, "graphics/HUD/Cartridges/S7H762MM.png", -11, -4, -27, -26, -25));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ('S7_ManxCarbine', 'S7_ManxCarbineClip', "Inventory", 32, "graphics/HUD/Cartridges/S7H9MM.png", -10, -4, -20, -18));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ('S7_Shotgun', 'S7_ShotgunMag', "Inventory", 10, "graphics/HUD/Cartridges/S7H20GA.png", -16, -8, -32, -31));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ('S7_HitterSMG', 'S7_HitterSMGClip', "Inventory", 62, "graphics/HUD/Cartridges/S7H45ACP.png", -10, -2, -20, -19, -18));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ('S7_GrenadeWeap', 'S7_GrenadeCount', "Inventory", 15, "graphics/HUD/Throwables/S7TGRICN.png", -15, -8, -24, -22));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ('S7_ConquerorRifle', 'S7_ConquerorRifleClip', "Inventory", 15, "graphics/HUD/Cartridges/S7H45WW.png", -14, -7, -43, -41));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ('S7_AK47', 'S7_AK47Clip', "Inventory", 30, "graphics/HUD/Cartridges/S7H762MM.png", -11, -4, -27, -26));
        FScreenAmmoBars.Push (S7_FScreenSBarAmmoBar.GenerateBar ('S7_CaesarChaingun', 'S7_CaesarChaingunMag', "Inventory", 100, "graphics/HUD/Cartridges/S7H45WW.png", -14, -3, -43, -42, -41, scale: (0.75, 1.0)));
    }

    override void NewGame () {
        Super.NewGame ();

        mHealthInterpolator.Reset (0);
        mArmorInterpolator.Reset  (0);
        mStaminInterpolator.Reset (0);
        mCashInterpolator.Reset   (0);
        mLsrRfInterpolator.Reset (0);
        mPlsmMGInterpolator.Reset (0);
        mIonCannonInterpolator.Reset (0);
        mLPPInterpolator1.Reset  (0);
        mLPPInterpolator2.Reset  (0);
        mThrowableForce.Reset  (0);
    }

    override void Tick () {
        Super.Tick ();

        mHealthInterpolator.Update (CPlayer.health);
        mArmorInterpolator.Update  (GetS7ArmorAmount ());
        mStaminInterpolator.Update (GetStamina (false));
        mCashInterpolator.Update   (GetAmount ('S7_Cash'));
        mLsrRfInterpolator.Update (GetAmount ('S7_FauchardMag'));
        mPlsmMGInterpolator.Update (GetAmount ('S7_PlasmaGunMag'));
        mIonCannonInterpolator.Update (GetAmount ('S7_PrettyShootyIonCannonGunMag'));
        mLPPInterpolator1.Update  (GetAmount ('S7_LaserPewPewClip'));
        mLPPInterpolator2.Update  (GetAmount ('S7_LaserPewPewClipSecond'));

        if (CPlayer && CPlayer.ReadyWeapon is 'S7_ThrowWeapon') {
            let throwWeap = S7_ThrowWeapon (CPlayer.ReadyWeapon);
            mThrowableForce.Update (throwWeap.throwForce);
        } else
            mThrowableForce.Update (0);
    }

    enum HUDTypes {
        HUDType_None = 0,
        HUDType_Minimal = 1,
        HUDType_Helmet = 2,
    }

    transient CVar selectedHUDCvar;
    override void Draw (int state, double TicFrac) {
        Super.Draw (state, TicFrac);

        if (!CPlayer || !CPlayer.mo || !S7_BasePlayer (CPlayer.mo))
            return;

        let pPawn = S7_BasePlayer (CPlayer.mo);

        if (!selectedHUDCvar)
            selectedHUDCvar = CVar.GetCvar ("S7_HUDType", CPlayer);

        if (!selectedHUDCvar)
            return;

        int selectedHUD = selectedHUDCvar.GetInt ();
        bool drawHUD = (
            (state == HUD_StatusBar || state == HUD_Fullscreen) &&
            selectedHUD != HUDType_None
        );

        if (!drawHUD)
            return;

        if (selectedHUD == HUDType_Minimal) {
            BeginHUD (1.0, false, 320, 200);
            DrawMinimalHUD (TicFrac, pPawn);
        } else if (selectedHUD == HUDType_Helmet) {
            BeginHUD (1.0, true, 320, 200);
            DrawHelmetHUD (TicFrac, pPawn);
        }
    }

    protected void DrawRadar (S7_BasePlayer pPawn, Vector2 radarPos, double TicFrac) {
        if (!CheckInventory ('S7_UpgradeRadar', 1))
            return;

        DrawImage ("graphics/HUD/Radar/S7RDR0.png", radarPos, DI_SCREEN_RIGHT_TOP | DI_ITEM_RIGHT_TOP);

        double angleCos = Cos (-pPawn.angle), angleSin = Sin (-pPawn.angle);
        Vector3 pPawnXYPos = (pPawn.prev + (TicFrac * (pPawn.pos - pPawn.prev)));
        Vector2 radarOffs = (radarPos.x - RADAR_RADIUS, radarPos.y + RADAR_RADIUS);
        let mapData = S7_MapData.GetSpecial ();

        if (CheckInventory ('S7_UpgradeRadarMinimap')) {
            let lineIterator = BlockLinesIterator.Create (pPawn, RADAR_MAXDIST);
            while (lineIterator.Next ()) {
                let curLine = lineIterator.CurLine;

                // Skip self-referencing sectors and intra-sector lines
                if (curLine.frontsector == curLine.backsector)
                    continue;
                // Skip double-sided lines without height differences
                if (curLine.frontsector && curLine.backsector &&
                    curLine.frontsector.floorPlane.isEqual   (curLine.backsector.floorPlane) &&
                    curLine.frontsector.ceilingPlane.isEqual (curLine.backsector.ceilingPlane)
                ) {
                    continue;
                }

                // Coords
                Vector2 v1WorldPos = (pPawnXYPos.XY - curLine.v1.p), v2WorldPos = pPawnXYPos.XY - curLine.v2.p;

                Vector2 pos = v1WorldPos;
                Vector2 dir = v2WorldPos - v1WorldPos;
                Vector2 circleCentre = (0, 0);
                Vector2 adjustedPos = pos - circleCentre;
                double a = dir dot dir;
                double b = 2 * (adjustedPos dot dir);
                double c = adjustedPos dot adjustedPos - (RADAR_RADIUS * RADAR_SCALE) ** 2;

                double discriminant = b*b - 4 * a * c;
                if (discriminant >= 0) {
                    discriminant = sqrt (discriminant);
                    double t0 = (-b + discriminant) / (2 * a);
                    double t1 = (-b - discriminant) / (2 * a);

                    if ((t0 > 1 && t1 > 1) || (t0 < 0 && t1 < 0))
                        continue;
                    else if ((t0 < 0 && t1 > 1) || (t1 < 0 && t0 > 1))
                        ;
                    else {
                        double t0 = clamp (t0, 0., 1.);
                        double t1 = clamp (t1, 0., 1.);
                        Vector2 intersectionPos0 = pos + t0 * dir;
                        Vector2 intersectionPos1 = pos + t1 * dir;
                        // New line segment is intersectionPos0 + t * newDir
                        Vector2 newDir = intersectionPos1 - intersectionPos0;

                        v1WorldPos = intersectionPos0;
                        v2WorldPos = intersectionPos1;
                    }
                } else
                    continue;

                Vector2 v1ScreenPos, v2ScreenPos;
                v1ScreenPos.x = (v1WorldPos.x * angleSin + v1WorldPos.y * angleCos); v1ScreenPos.y = (v1WorldPos.x * angleCos - v1WorldPos.y * angleSin);
                v2ScreenPos.x = (v2WorldPos.x * angleSin + v2WorldPos.y * angleCos); v2ScreenPos.y = (v2WorldPos.x * angleCos - v2WorldPos.y * angleSin);
                v1ScreenPos /= RADAR_SCALE; v2ScreenPos /= RADAR_SCALE;

                DrawLine (radarOffs, v1ScreenPos, v2ScreenPos, "Black");
            }
        }

        double markerYOffs = mRadarMarkers.mFont.GetHeight () / 2.0;

        bool showKeys = CheckInventory ('S7_UpgradeRadarKeys', 1);

        let actorFinder = BlockThingsIterator.Create (pPawn, RADAR_MAXDIST);
        Actor curActor;
        while (actorFinder.Next ()) {
            curActor = actorFinder.thing;

            int colour;
            if (curActor.bIsMonster) {
                if (curActor.health > 0)
                    colour = (curActor.isFriend (pPawn)) ? Font.CR_GREEN : Font.CR_RED;
                else
                    colour = Font.CR_DARKGRAY;
            } else if (showKeys && curActor.bSpecial && curActor is 'Key')
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
            DrawString (mRadarMarkers, "B", radarOffs + screenPos - (0, markerYOffs), DI_SCREEN_RIGHT_TOP | DI_TEXT_ALIGN_CENTER | DI_NOSHADOW, colour);
        }//level.time
        DrawString (mRadarMarkers, "A", radarOffs - (0, markerYOffs), DI_SCREEN_RIGHT_TOP | DI_TEXT_ALIGN_CENTER | DI_NOSHADOW, Font.CR_BLUE);
    }

    protected void DrawHelmetHUD (double TicFrac, S7_BasePlayer pPawn) {
        DrawImage ("HELMTOP", (0, 0), DI_ITEM_TOP | DI_SCREEN_HCENTER);
        DrawImage ("HELMBTML", (0, 0), DI_ITEM_LEFT_BOTTOM | DI_SCREEN_LEFT_BOTTOM);
        DrawImage ("HELMBTMR", (0, 0), DI_ITEM_RIGHT_BOTTOM | DI_SCREEN_RIGHT_BOTTOM);
        if (!CheckInventory ('S7_DisableHud', 1)) {
            alpha = 0.75;

            DrawImage ("graphics/HUD/Normal/HOLOBARSNONE.png", (0, 27), DI_ITEM_TOP | DI_SCREEN_HCENTER);

            int maxHealth = pPawn.GetMaxHealth (true);

            string energyImg;
            if (CheckHealth (int (maxHealth * .75), true))
                energyImg = "graphics/HUD/Normal/HOLOBARSGREEN.png";
            else if (CheckHealth (int (maxHealth * .50), true))
                energyImg = "graphics/HUD/Normal/HOLOBARSYELLOW.png";
            else if (CheckHealth (int (maxHealth * .25), true))
                energyImg = "graphics/HUD/Normal/HOLOBARSORANGE.png";
            else
                energyImg = "graphics/HUD/Normal/HOLOBARSRED.png";
            DrawImage (energyImg, (0, 29), DI_ITEM_TOP | DI_SCREEN_HCENTER);

            // Draw health/armor bars
            DrawBar ("HOLOBR00", "HOLOBR01", mHealthInterpolator.GetValue (), maxHealth, (0, 36), 0, 0, DI_ITEM_TOP | DI_SCREEN_HCENTER);
            DrawBar ("HOLOBR10", "HOLOBR01", mArmorInterpolator.GetValue (), GetS7ArmorSaveAmount (), (0, 41), 0, 0, DI_ITEM_TOP | DI_SCREEN_HCENTER);
            // Draw health/armor numbers
            DrawString (mNormalHUDFont, FormatNumber (mHealthInterpolator.GetValue (), 1, 3), (-33, 50), DI_SCREEN_HCENTER | DI_NOSHADOW, Font.FindFontColor ('HUD_Health'));
            DrawString (mNormalHUDFont, FormatNumber (mArmorInterpolator.GetValue (), 1, 3), (33, 50), DI_TEXT_ALIGN_RIGHT | DI_SCREEN_HCENTER | DI_NOSHADOW, Font.FindFontColor ('HUD_Armour'));
        }
    }

    transient CVar enHPBar_HPDisp, enHPBar_Nametag;
    protected void DrawMinimalHUD (double TicFrac, S7_BasePlayer pPawn) {
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

        // Level up indicator
        if (pPawn.xpSys && pPawn.xpSys.attrPoints > 0) {
            int attrPts = pPawn.xpSys.attrPoints;
            string fmtStr = attrPts == 1 ? "%d attribute point available" : "%d attribute points available";
            DrawString (mFScreenHUDFont, String.Format (fmtStr, attrPts), (111, -18), DI_TEXT_ALIGN_LEFT | DI_NOSHADOW, Font.CR_GREEN);
        }

        // Enemy health bar
        bool enHPBarOn = CheckInventory ('S7_UpgradeEnemyHPBar', 1);
        if (enHPBarOn) {
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

                    if (!enHPBar_HPDisp)
                        enHPBar_HPDisp = CVar.GetCvar ("S7_EnemyHPBar_HPDisp", CPlayer);

                    if (enHPBar_HPDisp) {
                        if (enHPBar_HPDisp.GetInt () >= 2)
                            DrawString (mSmallFont, String.Format ("%d%%", (double (health) / maxHealth) * 100), (0, 8.0), DI_SCREEN_HCENTER | DI_TEXT_ALIGN_CENTER | DI_NOSHADOW, Font.CR_DARKGRAY);
                        else if (enHPBar_HPDisp.GetInt () == 1) {
                            DrawString (mSmallFont, FormatNumber (maxHealth, 0, 10), (4, 8.0), DI_SCREEN_HCENTER | DI_TEXT_ALIGN_LEFT | DI_NOSHADOW, Font.CR_DARKGRAY);
                            DrawString (mSmallFont, "/", (0, 8.0), DI_SCREEN_HCENTER | DI_TEXT_ALIGN_CENTER | DI_NOSHADOW, Font.CR_DARKGRAY);
                            DrawString (mSmallFont, FormatNumber (health, 0, 10), (-4, 8.0), DI_SCREEN_HCENTER | DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_DARKGRAY);
                        }
                    }

                    if (!enHPBar_Nametag)
                        enHPBar_Nametag = CVar.GetCvar ("S7_EnemyHPBar_NametagOn", CPlayer);
                    if (enHPBar_Nametag && enHPBar_Nametag.GetInt ())
                        DrawString (mSmallFont, nameTag, (0, 20.0), DI_SCREEN_HCENTER | DI_ITEM_TOP | DI_TEXT_ALIGN_CENTER | DI_NOSHADOW, Font.CR_DARKGRAY);
                }
            }
        }

        DrawRadar (pPawn, (-40, 2), TicFrac);

        // Ammo bars
        if (CPlayer.ReadyWeapon) {
            if (CheckWeaponSelected ('S7_SSG')) {
                // Draw ammo pool count
                DrawString (mFScreenHUDFont, "Pool:      ", (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                DrawString (mFScreenHUDFont, FormatNumber (GetAmount (CPlayer.ReadyWeapon.AmmoType2), 1, 5), (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);

                // Draw shells
                if (CheckInventory ("S7_SSGRightLoadedToken", 1)) DrawImage ("graphics/HUD/Cartridges/S7H12GA.png", (-17, -29), DI_ITEM_LEFT_TOP);
                if (CheckInventory ("S7_SSGLeftLoadedToken",  1)) DrawImage ("graphics/HUD/Cartridges/S7H12GA.png", (-31, -29), DI_ITEM_LEFT_TOP);
            } else if (CheckWeaponSelected ('S7_Fauchard')) {
                // Draw ammo pool count
                DrawString (mFScreenHUDFont, "Pool:      ", (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                DrawString (mFScreenHUDFont, FormatNumber (GetAmount (CPlayer.ReadyWeapon.AmmoType2), 1, 5), (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);

                // Draw ammo bar
                DrawBar ("graphics/HUD/Fullscreen/S7LRABFG.png", "graphics/HUD/Fullscreen/S7LRABBG.png",
                    mLsrRfInterpolator.GetValue (), GetMaxAmount ('S7_FauchardMag'), (-5, -5), 0, SHADER_REVERSE, DI_ITEM_RIGHT_BOTTOM);
            } else if (CheckWeaponSelected ('S7_PlasmaGun')) {
                // Draw ammo pool count
                DrawString (mFScreenHUDFont, "Pool:      ", (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                DrawString (mFScreenHUDFont, FormatNumber (GetAmount (CPlayer.ReadyWeapon.AmmoType2), 1, 5), (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);

                // Draw ammo bar
                DrawBar ("graphics/HUD/Fullscreen/S7LRABFG.png", "graphics/HUD/Fullscreen/S7LRABBG.png",
                    mPlsmMGInterpolator.GetValue (), GetMaxAmount ('S7_PlasmaGunMag'), (-5, -5), 0, SHADER_REVERSE, DI_ITEM_RIGHT_BOTTOM);
            } else if (CheckWeaponSelected ('S7_PrettyShootyIonCannonGun')) {
                // Draw ammo pool count
                DrawString (mFScreenHUDFont, "Pool:      ", (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                DrawString (mFScreenHUDFont, FormatNumber (GetAmount (CPlayer.ReadyWeapon.AmmoType2), 1, 5), (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);

                // Draw ammo bar
                DrawBar ("graphics/HUD/Fullscreen/S7LRABFG.png", "graphics/HUD/Fullscreen/S7LRABBG.png",
                    mIonCannonInterpolator.GetValue (), GetMaxAmount ('S7_PrettyShootyIonCannonGunMag'), (-5, -5), 0, SHADER_REVERSE, DI_ITEM_RIGHT_BOTTOM);
            } else if (CheckWeaponSelected ('S7_LaserPewPew')) {
                // Draw ammo pool count
                DrawString (mFScreenHUDFont, "Pool:      ", (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                DrawString (mFScreenHUDFont, FormatNumber (GetAmount (CPlayer.ReadyWeapon.AmmoType2), 1, 5), (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);

                // Draw ammo bar(s)
                let lppWeap = S7_LaserPewPew (CPlayer.ReadyWeapon);
                bool hasTwo = lppWeap.amount > 1;

                if (hasTwo && lppWeap.akimbo) {
                    DrawImage ("graphics/HUD/Fullscreen/FireMode/BLSDual.png", (5, 5), DI_ITEM_LEFT_TOP);

                    DrawBar ("S7LPPDFG", "S7LPPDBG", mLPPInterpolator1.GetValue (), GetMaxAmount ('S7_LaserPewPewClip'), (-5, -5), 0, SHADER_REVERSE, DI_ITEM_RIGHT_BOTTOM);
                    DrawBar ("S7LPPDFG", "S7LPPDBG", mLPPInterpolator2.GetValue (), GetMaxAmount ('S7_LaserPewPewClipSecond'), (-5, -23), 0, SHADER_REVERSE, DI_ITEM_RIGHT_BOTTOM);
                } else {
                    if (hasTwo)
                        DrawImage ("graphics/HUD/Fullscreen/FireMode/BLSCycle.png", (5, 5), DI_ITEM_LEFT_TOP);

                    DrawBar ("graphics/HUD/Fullscreen/S7LRABFG.png", "graphics/HUD/Fullscreen/S7LRABBG.png",
                        mLPPInterpolator1.GetValue (), GetMaxAmount ('S7_LaserPewPewClip'), (-5, -5), 0, SHADER_REVERSE, DI_ITEM_RIGHT_BOTTOM);
                }
            } else if (CheckWeaponSelected ('S7_Thumper')) {
                static const string ThumperGrenNames [] = { "", "Explosive", "Fragmentation", "Incendiary", "Flare", "Clusterbomb", "Nailbomb", "Nerve Gas" };
                static const int ThumperGrenColors [] = { Font.CR_WHITE, Font.CR_ORANGE, Font.CR_GREEN, Font.CR_DARKRED, Font.CR_WHITE, Font.CR_BLUE, Font.CR_YELLOW, Font.CR_BLACK };

                // Draw ammo pools count
                DrawString (mFScreenHUDFont, "Pool:      ", (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                DrawString (mFScreenHUDFont, FormatNumber (GetAmount ('S7_Thumper_PUnified'), 1, 5), (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);

                for (int i = 1; i < ThumperGrenNames.Size (); i++) {
                    bool selected = GetAmount ('S7_ThumperSelectedPool') == (i - 1);
                    string poolText = String.Format (selected ? ">%s:      " : "%s:      ", ThumperGrenNames [i]);
                    int colour = (selected ? Font.CR_RED : ThumperGrenColors [i]);
                    DrawString (mFScreenHUDFont, poolText, (-6, -50 - (7 * (8-i))), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, colour);
                    DrawString (mFScreenHUDFont, FormatNumber (GetAmount (S7_Thumper.PoolNames [i]), 1, 5), (-6, -50 - (7 * (8-i))), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, colour);
                }
                for (int i = 0; i < 5; i++) {
                    int grenType = GetAmount (String.Format ('S7_ThumperMag%d', i + 1));
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
                        if (bar.poolType == 'Inventory' && CPlayer.ReadyWeapon.AmmoType2)
                            poolAmount = GetAmount (CPlayer.ReadyWeapon.AmmoType2);
                        else if (bar.poolType != 'Inventory' && bar.poolType)
                            poolAmount = GetAmount (bar.poolType);

                        if (poolAmount >= 0) {
                            DrawString (mFScreenHUDFont, "Pool:      ", (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                            DrawString (mFScreenHUDFont, FormatNumber (poolAmount, 1, 5), (-6, -50), DI_TEXT_ALIGN_RIGHT | DI_NOSHADOW, Font.CR_WHITE);
                        }

                        // Draw in-mag count
                        int maxX = min (bar.xPositions.Size (), GetAmount (bar.magType));
                        for (int x = maxX-1; x >= 0; x--)
                            DrawImage (bar.sprite, (bar.xPositions [x], bar.yPositions [x]), DI_ITEM_LEFT_TOP, scale: bar.scale);

                        break;
                    }
                }
            }

            if (CPlayer.ReadyWeapon is 'S7_ThrowWeapon') {
                let throwWeap = S7_ThrowWeapon (CPlayer.ReadyWeapon);
                DrawImage ("graphics/HUD/Fullscreen/S7BARFR0.png", (-6, -50), DI_ITEM_RIGHT_BOTTOM);
                DrawBar ("graphics/HUD/Fullscreen/S7HLTHBR.png", "S7BARBK0", mThrowableForce.GetValue (), throwWeap.maxForce, (-7, -51), 0, SHADER_REVERSE, DI_ITEM_RIGHT_BOTTOM);

                if (CPlayer.ReadyWeapon is 'S7_GrenadeWeap') {
                    let grenWeap = S7_GrenadeWeap (throwWeap);

                    bool drawFuseBar = false;

                    if (grenWeap.cooking && grenWeap.fuse >= 0) {
                        drawFuseBar = true;

                        if (grenWeap.fuse >= 35 && grenWeap.fuse < 70 && (level.time % 4) == 0)
                            drawFuseBar = false;
                        else if (grenWeap.fuse >= 0 && grenWeap.fuse < 35 && (level.time % 2) == 0)
                            drawFuseBar = false;
                    }

                    if (drawFuseBar) {
                        DrawImage ("graphics/HUD/Fullscreen/S7ProgressBarBG.png", (0, -50), DI_ITEM_CENTER_BOTTOM | DI_SCREEN_CENTER_BOTTOM);
                        DrawBar ("graphics/HUD/Fullscreen/S7ProgressBarFG.png", "graphics/HUD/Fullscreen/S7ProgressBarFakeBG.png",
                            grenWeap.fuse, grenWeap.fuseLength, (0, -51), 0, 0, DI_ITEM_CENTER_BOTTOM | DI_SCREEN_CENTER_BOTTOM
                        );
                    }
                }
            } else if (CPlayer.ReadyWeapon is 'S7_HealWeap') {
                let app = S7_HealWeap (CPlayer.ReadyWeapon);
                int progress = app.healProgress;
                int maxProgress = app.healTime;

                if (progress >= 0) {
                    DrawImage ("graphics/HUD/Fullscreen/S7ProgressBarBG.png", (0, -50), DI_ITEM_CENTER_BOTTOM | DI_SCREEN_CENTER_BOTTOM);
                    DrawBar ("graphics/HUD/Fullscreen/S7ProgressBarFG.png", "graphics/HUD/Fullscreen/S7ProgressBarFakeBG.png",
                        progress, maxProgress, (0, -51), 0, 0, DI_ITEM_CENTER_BOTTOM | DI_SCREEN_CENTER_BOTTOM
                    );
                }
            }
        }

        if (isInventoryBarVisible ())
            DrawInventoryBar (diparms, (0, 0), 8, DI_SCREEN_CENTER_BOTTOM, HX_SHADOW);

        {
            double initialKeyY = -115;

            Vector2 keyPos = (15, initialKeyY);
            int rowCount = 0;
            double rowWidth = 0;

            for (let i = CPlayer.mo.Inv; i != null; i = i.Inv) {
                if (i is 'Key' && i.Icon.IsValid ()) {
                    DrawTexture (i.Icon, keyPos, DI_SCREEN_LEFT_BOTTOM | DI_ITEM_LEFT_TOP);

                    Vector2 size = TexMan.GetScaledSize (i.Icon);
                    keyPos.Y -= size.Y + 2;
                    rowWidth = max (rowWidth, size.X);

                    if (++rowCount >= 3) {
                        keyPos.Y = initialKeyY;
                        keyPos.X += rowWidth + 2;

                        rowWidth = 0;
                        rowCount = 0;
                    }
                }
            }
        }
    }
}