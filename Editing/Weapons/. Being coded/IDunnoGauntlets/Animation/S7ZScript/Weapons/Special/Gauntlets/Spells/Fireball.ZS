class S7_Gauntlets_Fireball : actor {
    default {
        speed 20;
        scale 0.5;
        damageFunction (random (1, 3) * 30);
        damageType "Fire2";
        gravity 0.25;

        projectile;
        +noExtremeDeath +forceXYBillboard
        -noGravity
    }

	states {
	Spawn:
		GPFB AABBCCCCCCCCCCBBAA 1 bright A_SpawnItemEx ("S7_Gauntlets_Fireball_FireTrailSpawner", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, SXF_NoCheckPosition | SXF_Clientside);
		loop;
	Death:
		GPFE A 2 bright {
            bNoGravity = true;
            A_Explode (32, 64);

            for (int i = 0; i < 5; i++)
                A_SpawnProjectile ("S7_Gauntlets_Fireball_Ember", 1.5, 0.0, fRandom (0, 359), CMF_TrackOwner | CMF_AimDirection, fRandom (-90, -45));
            A_SpawnItemEx ("S7_Gauntlets_Fireball_ExplosionFireSpawner", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, SXF_NoCheckPosition | SXF_Clientside);

            bNoDamageThrust = true;
        }
		GPFE BCDE 2 bright A_Explode (12, 64);
		TNT1 AAAA 2 A_Explode (12, 64);
		stop;
	}
}

class S7_Gauntlets_Fireball_FireTrailSpawner : actor {
    default {
        +clientsideOnly +noInteraction
    }

	states {
	Spawn:
		TNT1 AAA 0 noDelay A_SpawnItemEx ("S7_Gauntlets_Fireball_FireTrail", 0.0, fRandom (-3.5, 3.5), fRandom (-3.5, 3.5),
            0.0, 0.0, fRandom (2.5, 3.0), 0.0, SXF_NoCheckPosition | SXF_Clientside);
		stop;
	}
}

class S7_Gauntlets_Fireball_FireTrail : actor {
    default {
        renderStyle "add";
        alpha 0.99;
        scale 0.35;

        +clientsideOnly +noInteraction +forceXYBillboard
    }

	states {
	Spawn:
		FRFX FGHIJKLMNOP 1 bright;
		stop;
	}
}

class S7_Gauntlets_Fireball_Ember : S7_Gauntlets_Fireball {
    default {
        radius 16;
        height 16;
        speed 10;
        damageFunction (random (2, 5) * 5);
        damageType "Fire";
        scale 0.25;
        gravity 1;

        projectile;
        +noExtremeDeath +forceXYBillboard
        -noGravity
    }

	states {
	Spawn:
		TNT1 A 0;
	Loople:
		GPFT AABBCCCCCCCCCCBBAA 2 bright A_SpawnItemEx ("S7_Gauntlets_Fireball_Ember_FireTrailSpawner", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, SXF_NoCheckPosition | SXF_Clientside);
		loop;

	Death:
		GPFE A 2 bright {
            bNoGravity = true;
            bNoDamageThrust = true;
            A_Explode (8, 32);

            for (int i = 0; i < 9; i++) {
                A_SpawnItemEx ("S7_Gauntlets_Fireball_Ember_FireTrail", 0.0, fRandom (0, 2.5), fRandom (0, 2.5),
                    0.0, fRandom (1.5, 3.2), fRandom (1.5, 3.2), fRandom (0, 359), SXF_NoCheckPosition | SXF_Clientside);
            }
        }
		GPFE BCDE 2 bright A_Explode (8, 32);
		stop;
	}
}

class S7_Gauntlets_Fireball_Ember_FireTrailSpawner : S7_Gauntlets_Fireball_FireTrailSpawner {
	states {
	Spawn:
		TNT1 A 0;
		TNT1 AA 0 A_SpawnItemEx ("S7_Gauntlets_Fireball_Ember_FireTrail", 0.0, fRandom (-3.5, 3.5), fRandom (-3.5, 3.5), 0.0, 0.0, 0.5, 0.0, SXF_NoCheckPosition | SXF_Clientside);
		stop;
	}
}

class S7_Gauntlets_Fireball_Ember_FireTrail : S7_Gauntlets_Fireball_FireTrail {
    default {
        scale 0.25;
    }

	states {
	Spawn:
		FRFX FGHIJKLMNOP 1 bright;
		stop;
	}
}

class S7_Gauntlets_Fireball_ExplosionFireSpawner : S7_Gauntlets_Fireball_FireTrailSpawner {
    default {
        reactionTime 8;
    }

	states {
	Spawn:
		TNT1 A 2;
	Loople:
		TNT1 AAA 0 A_SpawnItemEx ("S7_Gauntlets_Fireball_ExplosionFire", 0.0, fRandom (0, 2.5), fRandom (0, 2.5),
								0.0, fRandom (1.5, 3.2), fRandom (1.5, 3.2), fRandom (0, 359), SXF_NoCheckPosition | SXF_Clientside);
		TNT1 A 2 A_Countdown;
		loop;
	Death:
		stop;
	}
}

class S7_Gauntlets_Fireball_ExplosionFire : S7_Gauntlets_Fireball_FireTrail {
    default {
        scale 0.65;
        alpha 0.5;
    }

	states {
	Spawn:
		FRFX ABCDEFGHIJKLMNOP 1 bright;
		stop;
	}
}