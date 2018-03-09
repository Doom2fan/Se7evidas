class S7_HealingSystem : Inventory {
    const baseRegenAmount = 2.0;
    const baseRegenTime = 3;

    int regenPoints;
    protected int regenTimer;

    override void AttachToOwner (Actor other) {
        Super.AttachToOwner (other);

        regenPoints = 0;
    }

    override void DoEffect () {
        if (!Owner || !(Owner is "S7_BasePlayer"))
            return;

        let pPawn = S7_BasePlayer (Owner);
        if (!pPawn || !pPawn.xpSys)
            return;

        if (regenTimer > 0 && regenPoints > 0)
            regenTimer--;

        if (regenTimer == 0 && regenPoints > 0) {
            double regenRateAmount, regenRateTime;

            [regenRateTime, regenRateAmount] = pPawn.xpSys.GetStatMod (S7Stat_Special, specialName: "regenRate");
            regenRateAmount += baseRegenAmount;

            int giveCount = min (regenRateAmount, regenPoints);

            pPawn.GiveBody (giveCount);
            regenPoints -= giveCount;

            regenTimer = baseRegenTime * regenRateTime;
        } else if (regenPoints < 0) {
            Console.PrintF ("S7 Error: What the hell? S7_HealingSystem.regenPoints became negative!");
            regenPoints = 0;
            regenTimer = 0;
        } else if (regenPoints == 0 && regenTimer > 0)
            regenTimer = 0;
    }
}