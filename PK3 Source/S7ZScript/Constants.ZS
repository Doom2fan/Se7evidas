// Version
const S7C_MajorVersion = 0;
const S7C_MinorVersion = 1;

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

// Weapon binding slots
enum S7_WeaponSlots {
    WpSlot_Medium = 1,
    WpSlot_Light,
    WpSlot_Heavy,
    WpSlot_AreaDMG,
    WpSlot_Special,
};

// Player data
const S7C_DodgeStamina = 30;
const S7C_SprintStamina = 5;
const S7C_BaseSprintFactor = 0.5;
const S7C_MJumpMinDiff = 15;
const S7C_WJumpDelay = 5;