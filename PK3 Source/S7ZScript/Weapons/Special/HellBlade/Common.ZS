// Stuff that's common to all forms
class S7_HellhunterBladeLust : S7_Counter { default { Inventory.MaxAmount 150; } } // For special attacks
class S7_HellhunterBladeExperience : S7_Counter { } // For increasing affinity
class S7_HellhunterBladeAffinity : S7_Counter { default { Inventory.MaxAmount 10; } } // Controls the blade's damage

enum HellWarriorBladeForms {
    HELLBLADE_FORM1 = 1,
    HELLBLADE_FORM2 = 2,
    HELLBLADE_FORM3 = 3,
};

class S7_HBPuff_Base : Actor {
    default {
        Radius 0;
        Height 1;

        +PUFFONACTORS   +PUFFGETSOWNER +FORCEXYBILLBOARD +BLOODSPLATTER
        +NOEXTREMEDEATH
    }

    states {
    Spawn:
        TNT1 A 3 noDelay {
            A_GiveToTarget ("S7_HellhunterBladeExperience", 4);
            A_GiveToTarget ("S7_HellhunterBladeLust", 5);
        }
        stop;
    Crash:
        TNT1 A 3;
        stop;
    }
}