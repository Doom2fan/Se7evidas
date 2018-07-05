//-------------------------------------------------------------------------------------------
//
// Shadow
//
//-------------------------------------------------------------------------------------------
class S7_ShadowDemon : S7_Mechdemon {
    default {
        RenderStyle "Translucent";
        Alpha .25;

        Obituary "$OBSHADOW";
        Species "Mechdemon";
        Tag "$SHADOWTAG";
    }

    override void Tick () {
        bool attacking = InStateSequence (CurState, ResolveState ("Melee"));
        bool dead = (bKilled || health <= 0);

        if (attacking && alpha < 1.)
            alpha += 2./TICRATE;
        else if (dead && alpha < 1.)
            alpha += .15/TICRATE;
        else if (!attacking && !dead && health > 0 && alpha > .25) 
            alpha -= 1.5/TICRATE;

        alpha = clamp (alpha, .25, 1.);

        Super.Tick ();
    }
}