class S7_ActorExtensions : Actor {
    /* Summary:
    **  Checks if an actor is in the "void".
    **
    ** Arguments:
    **  mo: The actor to be checked.
    **
    ** Returns:
    **  Returns a bool indicating whether the actor is in the "void".
    */
    static bool IsInVoid (Actor mo) {
        let secPoly = new ("S7_Polygon");

        Sector sec = mo.CurSector;
        for (int i = 0; i < sec.lines.Size (); i++) {
            let line = new ("S7_Line");

            line.v1 = sec.lines [i].v1.p;
            line.v2 = sec.lines [i].v2.p;

            secPoly.lines.Push (line);
        }
        
        return !S7_Math.PointInPolygon (mo.pos.XY, secPoly);
    }

    /* Summary:
    **  Checks if an actor can be ripped by a projectile.
    **
    ** Arguments:
    **  victim: The actor to be checked.
    **  projectile: The projectile doing the ripping.
    **
    ** Returns:
    **  Returns a bool indicating whether the actor can be ripped through.
    */
    static clearscope bool CanRip (Actor victim, Actor projectile) {
        if (!projectile.bRipper || victim.bDontRip)
            return false;
        if (projectile.bNoBossRip && victim.bBoss)
            return false;
        if (victim.RipLevelMin > 0 && projectile.RipperLevel < victim.RipLevelMin)
            return false;
        if (victim.RipLevelMax > 0 && projectile.RipperLevel > victim.RipLevelMax)
            return false;

        return true;
    }

    // This only exists because P_RipperBlood wasn't exported to ZScript.
    static void RipperBlood (Actor mo, Actor bleeder) {
        class<Actor> bloodcls = bleeder.GetBloodType (0);

        double xo = random2 [RipperBlood] () / 16.;
        double yo = random2 [RipperBlood] () / 16.;
        double zo = random2 [RipperBlood] () / 16.;
        Vector3 pos = mo.Vec3Offset (xo, yo, zo);

        if (bloodcls) {
            Actor th;
            th = Spawn (bloodcls, pos, NO_REPLACE); // GetBloodType already performed the replacement
            // [NG] Applying PUFFGETSOWNER to the blood will make it target the owner

            if (th.bPuffGetsOwner)
                th.target = bleeder;

            if (gameinfo.gametype == GAME_Heretic)
                th.bNoGravity = true;

            th.vel.X = mo.vel.X / 2;
            th.vel.Y = mo.vel.Y / 2;
            th.tics += random [RipperBlood] () & 3;

            // colorize the blood!
            if (!th.bDontTranslate)
                th.Translation = bleeder.BloodTranslation;
        }
    }
}