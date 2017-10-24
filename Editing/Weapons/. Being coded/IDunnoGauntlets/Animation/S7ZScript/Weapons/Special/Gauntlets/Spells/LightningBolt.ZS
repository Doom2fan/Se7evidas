class S7_GauntletsLightningPuff : S7_BulletPuff {
    default {
        damageType "Lightning";

        +puffOnActors +alwaysPuff +noExtremeDeath
    }

    states {
    Crash:
    Death:
    XDeath:
    Melee:
    Spawn:
        TNT1 A 1;
        stop;
    }
}

class S7_GauntletsLightning : actor {
    default {
        renderStyle "add";

        +noBlockmap +noGravity +noTeleport +cannotPush
        +noInteraction +forceXYBillboard +clientsideOnly
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            vel.y = fRandom (-0.5, 0.5);
            vel.z = fRandom (-0.5, 0.5);
            A_SetScale (fRandom (.07, .08));

            return A_Jump (256, "SpriteA", "SpriteB", "SpriteC");
        }
    SpriteA:
        PLSE B 1 bright;
        goto Loople;
    SpriteB:
        PLSE C 1 bright;
        goto Loople;
    SpriteC:
        PLSE D 1 bright;
        goto Loople;
    Loople:
        #### # 1 bright {
            if (scale.x <= .01 || alpha <= 0.8) // Disappear if too small or alpha is too low. Should help with framerate, I think...
                return ResolveState ("Null");

            A_SetScale (scale.X - .009);
            A_FadeOut (.045);

            return ResolveState (null);
        }
        loop;
    }
}