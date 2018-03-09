//-------------------------------------------------------------------------------------------
//
// Multijump marker
//
//-------------------------------------------------------------------------------------------
class S7_MultiJump_Marker : S7_EffectsBase {
    default {
        Height 2;
        Radius 2;
        Alpha 1.0;
        RenderStyle "add";

        +NOTELEPORT +NOINTERACTION  +NOGRAVITY +FORCEXYBILLBOARD
        +CANNOTPUSH +CLIENTSIDEONLY
        -NOBLOCKMAP
    }

    states {
    Spawn:
        MJMP A 10 bright light ("MJMPMARKER");
        #### #  1 bright light ("MJMPMARKER") A_FadeOut (0.05);
        wait;
    }
}