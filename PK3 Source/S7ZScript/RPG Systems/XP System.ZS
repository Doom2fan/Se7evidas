//-------------------------------------------------------------------------------------------
//
// XP System
//
//-------------------------------------------------------------------------------------------
class S7_XP_System_Experience             : S7_Counter                     { default { inventory.maxAmount 0x7FFFFFFF; } }
class S7_XP_System_Level                  : S7_Counter                     { default { inventory.maxAmount 0x0000FFFF; } }
class S7_XP_System_AttributePoints        : S7_Counter                     { default { inventory.maxAmount 0x0000FFFF; } }

//-------------------------------------------------------------------------------------------
//
// Stat System
//
//-------------------------------------------------------------------------------------------
class S7_Stats_System_BaseStat            : S7_Counter                     { default { inventory.maxAmount 0x00007FFF; } }
class S7_Stats_System_Strength            : S7_Stats_System_BaseStat       { }
class S7_Stats_System_Agility             : S7_Stats_System_BaseStat       { }
class S7_Stats_System_Vitality            : S7_Stats_System_BaseStat       { }
class S7_Stats_System_Defense             : S7_Stats_System_BaseStat       { }
class S7_Stats_System_Will                : S7_Stats_System_BaseStat       { } // Willpower
class S7_Stats_System_Magic               : S7_Stats_System_BaseStat       { } // Magic mastery
class S7_Stats_System_Technology          : S7_Stats_System_BaseStat       { } // Tech-savvyness (For hacking, mainly)