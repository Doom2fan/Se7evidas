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

extend class S7_BaseWeapon {
    //-------------------------------------------------------------------------------------------
    //
    // GetOwnerXPSystem
    //
    //-------------------------------------------------------------------------------------------
    S7_XPSystem GetOwnerXPSystem () {
        if (!Owner || !(Owner is 'S7_BasePlayer'))
            return null;

        let xpSystem = S7_XPSystem (Owner.FindInventory ('S7_XPSystem', true));

        if (!xpSystem)
            return null;

        return xpSystem;
    }

    //-------------------------------------------------------------------------------------------
    //
    // DoSelectOffset
    //
    //-------------------------------------------------------------------------------------------
    virtual Vector2 DoSelectOffset_InitialOffset () {
        return (0, 0);
    }

    action void DoSelectOffset (Vector2 offs, int overlay = int.min, bool forceNoInterpolate = false) {
        let initOffs = invoker.DoSelectOffset_InitialOffset ();

        CVar iws = CVar.GetCVar ("S7_InterpolateWeaponSwitch", player);
        int doInterpolate = ((!forceNoInterpolate && iws && iws.GetInt ()) ? WOF_Interpolate : 0);

        offs = (initOffs.X + offs.X, 32 + initOffs.Y + offs.Y);

        if (overlay == int.min)
            A_WeaponOffset (offs.X, offs.Y, doInterpolate);
        else
            A_OverlayOffset (overlay, offs.X, offs.Y, doInterpolate);
    }

    //-------------------------------------------------------------------------------------------
    //
    // CanReload
    //
    //-------------------------------------------------------------------------------------------
    bool CanReload () {
        let pPawn = S7_BasePlayer (Owner);
        bool sprinting = pPawn ? pPawn.sprint_Sprinting : false;

        return (!sprinting || reloadWhileSprinting);
    }

    protected bool CheckButton (int mode, int button) {
        let plr = Owner.player;

        switch (mode) {
        case CB_Down: return  (plr.cmd.buttons & button);
        case CB_Up  : return !(plr.cmd.buttons & button);
        case CB_Pressed : return !(plr.oldbuttons & button) &&  (plr.cmd.buttons & button);
        case CB_Released: return  (plr.oldbuttons & button) && !(plr.cmd.buttons & button);
        default: ThrowAbortException ("Invalid value passed to CheckButton parameter \"mode\"");
        }

        return false;
    }

    //-------------------------------------------------------------------------------------------
    //
    // S7_WeaponReady
    //
    //-------------------------------------------------------------------------------------------
    action void S7_WeaponReady (StateLabel reloadState, StateLabel fireModeState, StateLabel quickMeleeState = "QuickMelee", int flags = 0, int wrFlags = 0) {
        wrFlags &= ~(WRF_AllowReload | WRF_AllowUser1 | WRF_AllowUser2 | WRF_AllowUser3 | WRF_AllowUser4);

        let pPawn = S7_BasePlayer (self);
        bool sprinting = pPawn ? pPawn.sprint_Sprinting : false;

        if (reloadState && CheckInventory ('S7_Reloading', 1) && invoker.CanReload ())
            player.SetPSprite (PSP_Weapon, ResolveState (reloadState));
        else
            TakeInventory ('S7_Reloading', 0x7FFFFFFF);

        if (fireModeState && CheckInventory ('S7_ChangeFireMode', 1) && (!sprinting || (flags & S7WRF_ChangeModeWhileSprinting)))
            player.SetPSprite (PSP_Weapon, ResolveState (fireModeState));
        else
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

        if (quickMeleeState && CheckInventory ('S7_DoMelee', 1) && (!sprinting || (flags & S7WRF_MeleeWhileSprinting)))
            player.SetPSprite (PSP_Weapon, ResolveState (quickMeleeState));
        else
            TakeInventory ('S7_DoMelee', 0x7FFFFFFF);

        if (wrFlags & WRF_AllowZoom) {
            wrFlags &= ~WRF_AllowZoom;

            let zoomState = ResolveState ("Zoom");
            if (zoomState && invoker.CheckButton (CB_Pressed, BT_Zoom))
                player.SetPSprite (PSP_Weapon, zoomState);
        }

        A_WeaponReady (wrFlags);
    }

    //-------------------------------------------------------------------------------------------
    //
    // S7_Internal_SetAnim
    //
    //-------------------------------------------------------------------------------------------
    protected action void S7_Internal_SetAnim (int animLayer, StateLabel animState, int setFlags, int unsetFlags) {
        A_Overlay (animLayer, "DummyState");
        A_OverlayFlags (animLayer, PSPF_AddWeapon | PSPF_AddBob | PSPF_PowDouble | PSPF_CvarFast | PSPF_RenderStyle | PSPF_Alpha, true);
        A_OverlayFlags (animLayer, PSPF_Flip | PSPF_Mirror | PSPF_ForceAlpha | PSPF_ForceStyle, false);
        A_OverlayFlags (animLayer, setFlags, true);
        A_OverlayFlags (animLayer, unsetFlags, false);

        let psp = player.FindPSprite (animLayer);
        if (!psp)
            ThrowAbortException ("This should never happen.");
        psp.SetState (ResolveState (animState));
    }

    //-------------------------------------------------------------------------------------------
    //
    // S7_SetSprite
    //
    //-------------------------------------------------------------------------------------------
    action void S7_SetSprite (name spriteName, int frameNum = -1, int overlayNum = PSP_Weapon) {
        let psp = player.FindPSprite (overlayNum);

        if (!psp)
            return;

        psp.sprite = GetSpriteIndex (spriteName);
        if (frameNum > -1)
            psp.frame = frameNum;
    }

    //-------------------------------------------------------------------------------------------
    //
    // DropAmmo
    //
    //-------------------------------------------------------------------------------------------
    Inventory DropAmmo (Class<Inventory> itemClass, Actor act, int amt, Vector3 offs = (0, 0, 0), double angleOffs = 0) {
        let drop = Inventory (Spawn (itemClass, act.Vec3Offset (0 + offs.X, 0 + offs.Y, 10. + offs.Z)));

        if (drop) {
            drop.amount = amt;

            drop.angle = act.angle + angleOffs;
            drop.VelFromAngle (5.);
            drop.vel.Z = 1.;
            drop.vel += act.vel;
        }

        return drop;
    }
}