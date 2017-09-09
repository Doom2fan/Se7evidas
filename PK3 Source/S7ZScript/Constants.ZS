// Map events
enum MapEventTypes {
    MEVNT_None            = 0, // This is here just in case you need to check it for some reason.
    MEVNT_GhostTown       = 1,
    MEVNT_PowerOutage     = 2,
    MEVNT_NuclearMeltdown = 3,
    MEVNT_PerfectHatred   = 4,
};

// Firing mode icons
enum FiringModeIcon {
    FMI_None      = 0,
    FMI_SemiAuto  = 1,
    FMI_BurstFire = 2,
    FMI_FullAuto  = 3,
}