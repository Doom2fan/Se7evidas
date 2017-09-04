class S7_FScreenSBarAmmoBar {
    Class<Weapon> weap;
    Class<Inventory> magType;
    Class<Inventory> poolType;
    string sprite;
    Array<double> xPositions;
    Array<double> yPositions;

    static S7_FScreenSBarAmmoBar GenerateBar (Class<Weapon> weap, Class<Inventory> magType, Class<Inventory> poolType, int ammoMax, string sprite, double initialX, double xIncrAmount, double yPos1, double yPos2 = double.Infinity, double yPos3 = double.Infinity) {
        let bar = new ("S7_FScreenSBarAmmoBar");
        bar.weap     = weap;
        bar.magType  = magType;
        bar.poolType = poolType;
        bar.sprite   = sprite;

        int curX = initialX, curY = 0;
        Array<double> yPos; // This is dumb, but whatever.
        yPos.Push (yPos1);
        if (yPos2 != double.Infinity)
            yPos.Push (yPos2);
        if (yPos3 != double.Infinity)
            yPos.Push (yPos3);

        for (int i = 0; i < ammoMax; i++) {
            bar.xPositions.Push (curX);
            bar.yPositions.Push (yPos [curY]);
            curX += xIncrAmount;
            curY++;
            if (curY >= yPos.Size ())
                curY = 0;
        }

        return bar;
    }
}