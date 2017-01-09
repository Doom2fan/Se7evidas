/*
**  Se7evidas - A GZDoom mod
**  Copyright (C) 2015-???  Chronos Ouroboros
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License along
**  with this program; if not, write to the Free Software Foundation, Inc.,
**  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#include "includes.h"
#include "save_system/save_invdata.h"

SaveInv_InvInfo importantInvInfo [] = {
    { .name = s"S7_BackpackToken", .callback = &InvUpdAmmoMax,  },
};

SaveInv_InvDef importantInv = {
    .cvarName = SD_IMPINV,
    .maxCVars = 5,
    .cvarMaxLen = (MAXCVARSIZ) - 25,
    .invArrSize = ArraySize (importantInvInfo),
    .invInfoArr = &importantInvInfo [0],
};

SaveInv_InvInfo normalInvInfo [] = {
    { .name = s"S7_9mmCartridges",                              }, // 9x19mm Parabellum cartridges
    { .name = s"S7_45ACPCartridges",                            }, // .45 ACP cartridges
    { .name = s"S7_44MCartridges",                              }, // .44 Magnum cartridges
    { .name = s"S7_762x39Cartridges",                           }, // 7.62x39mm cartridges
    { .name = s"S7_12gaShells",                                 }, // 12ga shotgun shells
    { .name = s"S7_20gaShells",                                 }, // 20ga shotgun shells
    { .name = s"S7_Cells",                                      }, // Type A cells
    { .name = s"S7_FBSysCells",                                 }, // Firebrand Systems cells
    { .name = s"S7_Thumper_PExp",                               }, // Thumper normal grenades
    { .name = s"S7_Thumper_PFrag",                              }, // Thumper fragmentation grenades
    { .name = s"S7_Thumper_PTherm",                             }, // Thumper incendiary grenades
    { .name = s"S7_Thumper_PFlare",                             }, // Thumper flare grenades
    { .name = s"S7_Thumper_PCluster",                           }, // Thumper clusterbomb grenades
    { .name = s"S7_Thumper_PNail",                              }, // Thumper nailbomb grenades
    { .name = s"S7_Thumper_PNGas",                              }, // Thumper nerve gas grenades
    { .name = s"S7_AMG",                                        }, // Mars Assault Rifle
    { .name = s"S7_AMGMag",                                     },
    { .name = s"S7_HitterSMG",                                  }, // Hitter SMG
    { .name = s"S7_HitterSMGClip",                              },
    { .name = s"S7_HitterSMGUpperJammed",                       },
    { .name = s"S7_HitterSMGLowerJammed",                       },
    { .name = s"S7_ManxCarbine",                                }, // Manx Carbine
    { .name = s"S7_ManxCarbineClip",                            },
    { .name = s"S7_PlasmaGun",                                  }, // Plasma MG
    { .name = s"S7_PlasmaGunMag",                               },
    { .name = s"S7_PlasmaGun_Charge",                           },
    { .name = s"S7_Fauchard",                                   }, // Fauchard Laser Rifle
    { .name = s"S7_FauchardMag",                                },
    { .name = s"S7_PrettyShootyIonCannonGun",                   }, // Mjolnir Ion Cannon
    { .name = s"S7_Shotgun",                                    }, // Lucifer Combat Shotgun
    { .name = s"S7_ShotgunMag",                                 },
    { .name = s"S7_ShotgunLoaded",                              },
    { .name = s"S7_SSG",                                        }, // 12ga Super Shotgun
    { .name = s"S7_SSGLeftLoaded",                              },
    { .name = s"S7_SSGRightLoaded",                             },
    { .name = s"S7_Thumper",                                    }, // Thumper 50mm GL
    { .name = s"S7_ThumperSelectedPool",                        },
    { .name = s"S7_ThumperChambered",                           },
    { .name = s"S7_Raptor",                                     }, // Raptor Pistol
    { .name = s"S7_RaptorClip",                                 },
    { .name = s"S7_Revolver",                                   }, // Deathbringer Revolver
    { .name = s"S7_RevolverClip",                               },
    { .name = s"S7_TEC9",                                       }, // Kronos SMG
    { .name = s"S7_TEC9Clip",                                   },
    { .name = s"S7_GrenadeWeap",                                }, // Grenades
    { .name = s"S7_GrenadeCount",                               },
    { .name = s"S7_HellwarriorBladeForm1",                      }, // Hellwarrior Blade
    { .name = s"S7_Medikit",                                    }, // Medikits
    { .name = s"S7_Stimpack",                                   }, // Stimpacks
    { .name = s"S7_Canteen",                                    }, // Canteen
    { .name = s"S7_Berserk",                                    }, // Berserk
    { .name = s"S7_Thumper_Used",                               }, // Used 50mm grenades
    { .name = s"S7_LaserPewPew",                                }, // Butterfly SMG
    { .name = s"S7_LaserPewPewClipSecond",                      },
    { .name = s"S7_LaserPewPewHasTwo",                          },
    { .name = s"S7_MultiJump_Max",                              }, // Max multijumps token
    { .name = s"S7_ConquerorRifle",                             }, // Conqueror Sniper Rifle
    { .name = s"S7_ConquerorRifleClip",                         },
};

SaveInv_InvDef normalInv = {
    .cvarName = SD_INV,
    .maxCVars = 25,
    .cvarMaxLen = (MAXCVARSIZ) - 18,
    .invArrSize = ArraySize (normalInvInfo),
    .invInfoArr = &normalInvInfo [0],
};