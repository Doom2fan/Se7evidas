//-------------------------------------------------------------------------------------------
//
// Multijump marker
//
//-------------------------------------------------------------------------------------------
class S7_MultiJump_Marker : actor {
    default {
        height 2;
        radius 2;
        alpha 1.0;
        renderStyle "add";

        +noBlockmap +noGravity +noTeleport +cannotPush
        +noInteraction +clientsideOnly +forceXYBillboard
        -noBlockmap
    }

    states {
    Spawn:
        MJMP A 10 bright light ("MJMPMARKER");
        #### #  1 bright light ("MJMPMARKER") A_FadeOut (0.05);
        wait;
    }
}