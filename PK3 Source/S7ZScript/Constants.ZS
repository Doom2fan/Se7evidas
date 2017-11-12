// Map events
enum MapEventTypes {
    MEVNT_None            = 0, // This is here just in case you need to check it for some reason.
    MEVNT_GhostTown          ,
    MEVNT_PowerOutage        ,
    MEVNT_NuclearMeltdown    ,
    MEVNT_PerfectHatred      ,
    MEVNT_LastToken          , // This is here just so you don't have to keep track of the last event, it's not an actual event.
};

// Firing mode icons
enum FiringModeIcon {
    FMI_None      = 0,
    FMI_SemiAuto  = 1,
    FMI_BurstFire = 2,
    FMI_FullAuto  = 3,
};

// ACS helper script
enum S7_ACSHelper_Funcs {
    S7_ACS_ChangeSky = 0,
};

// Player data
const S7C_DodgeStamina = 30;
const S7C_SprintStamina = 5;
const S7C_BaseSprintFactor = 0.5;
const S7C_MJumpMinDiff = 15;
const S7C_WJumpDelay = 5;

class S7_Constants {
    static const String S7_AmmoTypesData [] = {
        "S7_9mmCartridges:75",
        "S7_45ACPCartridges:62",
        "S7_44MCartridges:6",
        "S7_762x39Cartridges:35",
        "S7_45WWCartridges:75",
        "S7_20gaShells:10",
        "S7_12gaShells:12",
        "S7_Cells:36",
        "S7_FBSysCells:32",
        "S7_AntimatterShells:1",
        "S7_Thumper_PUnified:5",
        "S7_Thumper_PExp:5",
        "S7_Thumper_PFrag:5",
        "S7_Thumper_PTherm:5",
        "S7_Thumper_PFlare:5",
        "S7_Thumper_PCluster:5",
        "S7_Thumper_PNail:5",
        "S7_Thumper_PNGas:5"
    };
}