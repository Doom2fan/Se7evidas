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
}