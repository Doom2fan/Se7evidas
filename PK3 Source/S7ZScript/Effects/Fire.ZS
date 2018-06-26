//-------------------------------------------------------------------------------------------
//
// Fire
//
//-------------------------------------------------------------------------------------------
class S7_FireBase : S7_EffectsBase {
    default {
        RenderStyle "add";
        Alpha 1.0;
        Scale 0.25;

        +NOGRAVITY +NOTELEPORT +NOBLOCKMAP +FORCEXYBILLBOARD
    }

    states {
    Spawn:
        FIR1 ABCDEFHIJKL 1;
        stop;
    }
}