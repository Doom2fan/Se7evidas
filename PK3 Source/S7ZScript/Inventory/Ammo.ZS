/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2019 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

//-------------------------------------------------------------------------------------------
//
// Backpack
//
//-------------------------------------------------------------------------------------------
class S7_BackpackToken : Ammo {
    default {
        Inventory.MaxAmount 1;

        +INVENTORY.UNDROPPABLE
        -INVENTORY.INVBAR
    }
}
class S7_Backpack : Inventory replaces Backpack {
    default {
        Height 26;

        Tag "$BACKPACK";
        Inventory.PickupSound "Inventory/BackpackPickup";
        Inventory.PickupMessage "$BACKPACK";
        Inventory.Amount 1;
        Inventory.MaxAmount 0;
    }

    static const string ItemChoices [] = {
        "S7_9mmCartridges:S7_45ACPCartridges:S7_44MCartridges",
        "S7_20gaShells:S7_12gaShells",
        "S7_762x39Cartridges:S7_45WWCartridges",
        "S7_Cells:S7_FBSysCells"
    };

    Array<string> items;
    Array<int>    itemAmounts;

    override void PostBeginPlay () {
        for (int i = 0; i < ItemChoices.Size (); i++) {
            Array<string> options;
            Array<int> amounts;
            options.Clear ();
            amounts.Clear ();

            ItemChoices [i].Split (options, ":");
            amounts.Reserve (options.Size ());
            for (int i = options.Size () - 1; i >= 0; i--) {
                let itemDef = GetDefaultByType ((class<Inventory>) (options [i]));
                if (!itemDef) {
                    options.Delete (i, 1);
                    amounts.Delete (i, 1);
                    continue;
                }

                amounts [i] = itemDef.Amount * 2;
            }

            int num = random [invSpc] (0, options.Size () - 1);
            if (random [invSpc] (0, 255) < 192)
                continue;
            items.Push (options [num]);
            itemAmounts.Push (amounts [num]);
        }
    }

    override bool TryPickup (in out Actor toucher) {
        if (Super.CanPickup (toucher)) {
            if (!toucher.CheckInventory ('S7_BackpackToken', 1))
                toucher.GiveInventory ('S7_BackpackToken', 1);
            else
                A_DropItem ('S7_BackpackNoAmmo');

            for (int i = 0; i < items.Size (); i++)
                toucher.GiveInventory (items [i], itemAmounts [i]);

            GoAwayAndDie ();

            return true;
        }

        return false;
    }

    states {
    Spawn: // Credits to Id Software, BloodyAcid, Chronos "phantombeta" Ouroboros (edit)
        BKPK A -1;
        stop;
    }
}

class S7_BackpackNoAmmo : Inventory {
    default {
        Height 26;

        Tag "$EMPTBACKPACK";
        Inventory.PickupSound "Inventory/BackpackPickup";
        Inventory.PickupMessage "$EMPTBACKPACK";
        Inventory.Amount 1;
        Inventory.MaxAmount 0;
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        bXFlip = !!(random [invMisc] (0, 1));
        bYFlip = bXFlip;
    }

    override bool TryPickup (in out Actor toucher) {
        if (!toucher.CheckInventory ('S7_BackpackToken', 1) && Super.CanPickup (toucher)) {
            toucher.GiveInventory ('S7_BackpackToken', 1);
            GoAwayAndDie ();

            return true;
        }

        return false;
    }

    states {
    Spawn: // Credits to Id Software, BloodyAcid, Chronos "phantombeta" Ouroboros (edit)
        BKPK B -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// 9x19mm
//
//-------------------------------------------------------------------------------------------
class S7_9mmCartridges : Ammo {
    default {
        Tag "$9MM";
        Inventory.PickupMessage "$9MMMAG";
        Inventory.Amount 15;
        Inventory.MaxAmount 90;
        // Ammo.BackpackMaxAmount 120;
        Inventory.Icon "CLIPA0";
        Inventory.PickupSound "misc/ammopickup";
    }

    states {
    Spawn:
        CLIP A -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// .45 ACP
//
//-------------------------------------------------------------------------------------------
class S7_45ACPCartridges : Ammo {
    default {
        Tag "$45ACP";
        Inventory.PickupMessage "$45ACP_DRUMMAG";
        Inventory.Amount 62;
        Inventory.MaxAmount 372;
        // Ammo.BackpackMaxAmount 496;
        Inventory.Icon "CLIPC0";
        Inventory.PickupSound "misc/ammopickup";
    }

    states {
    Spawn:
        CLIP C -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// .44 Magnum
//
//-------------------------------------------------------------------------------------------
class S7_44MCartridges : Ammo {
    default {
        Tag "$44M";
        Inventory.PickupMessage "$44M_SPEEDLOADER";
        Inventory.Amount 6;
        Inventory.MaxAmount 36;
        // Ammo.BackpackMaxAmount 48;
        //Inventory.Icon "44MP0";
        Inventory.PickupSound "misc/ammopickup";
    }

    states {
    Spawn:
        44MP A -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// 7.62x39mm
//
//-------------------------------------------------------------------------------------------
class S7_762x39Cartridges : Ammo {
    default {
        Tag "$762X39";
        Inventory.PickupMessage "$762X39_MAG";
        Inventory.Amount 35;
        Inventory.MaxAmount 210;
        // Ammo.BackpackMaxAmount 280;
        //Inventory.Icon "CLIPE0";
        Inventory.PickupSound "misc/ammopickup";
    }

    states {
    Spawn:
        CLIP E -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// .45 WW
//
//-------------------------------------------------------------------------------------------
class S7_45WWCartridges : Ammo {
    default {
        Tag "$45WW";
        Inventory.PickupMessage "$45WW_PACK";
        Inventory.Amount 15;
        Inventory.MaxAmount 450;
        //Inventory.Icon "CLIPG0";
        Inventory.PickupSound "misc/ammopickup";
    }

    states {
    Spawn:
        CLIP G -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// 20 gauge buckshot
//
//-------------------------------------------------------------------------------------------
class S7_20gaShells : Ammo {
    default {
        Tag "$20GA";
        Inventory.PickupMessage "$20GA_BOX";
        Inventory.Amount 10;
        Inventory.MaxAmount 60;
        // Ammo.BackpackMaxAmount 80;
        Inventory.Icon "SHELA0";
        Inventory.PickupSound "misc/ammopickup";
    }

    override String PickupMessage () {
        if (amount == 1)
            return "$20GA_SINGLE";

        return PickupMsg;
    }

    states {
    Spawn:
        SHEL A -1 noDelay {
            let ownClass = GetClass ();

            if (ownClass == 'S7_20gaShells') {
                if (amount == 1)
                    return ResolveState ("Spawn.Single");
                else if (amount > 0 && amount != 10) {
                    int amt = Amount;
                    amount = 1;
                    return ResolveState ("Spawn.Single");

                    for (int i = amt - 1; i > 0; i--) {
                        let act = Inventory (Spawn (ownClass, pos));

                        if (!act)
                            continue;

                        act.Amount = 1;
                        act.vel = (vel + AngleToVector (fRandom [invSpc] (0, 360), fRandom [invSpc] (1, 5)));
                        act.target = target;
                        act.master = master;
                        act.tracer = tracer;
                        act.ChangeTID (TID);
                    }
                }
            }

            return ResolveState (null);
        }
        stop;
    Spawn.Single:
        TNT1 A  0 A_SetScale (0.25);
        SHEL E -1;
        stop;
    }
}

class S7_20gaShellsSmall : S7_20gaShells {
    default {
        Inventory.PickupMessage "$20GASMALL";
        Inventory.Amount 4;
    }

    states {
    Spawn:
        SHEL C -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// 12 gauge buckshot
//
//-------------------------------------------------------------------------------------------
class S7_12gaShells : Ammo {
    default {
        Tag "$12GA";
        Inventory.PickupMessage "$12GA_BOX";
        Inventory.Amount 6;
        Inventory.MaxAmount 72;
        // Ammo.BackpackMaxAmount 96;
        Inventory.Icon "SHELB0";
        Inventory.PickupSound "misc/ammopickup";
    }

    override String PickupMessage () {
        if (amount == 1)
            return "$12GA_SINGLE";

        return PickupMsg;
    }

    states {
    Spawn:
        SHEL B -1 noDelay {
            let ownClass = GetClass ();

            if (ownClass == 'S7_12gaShells') {
                if (amount == 1)
                    return ResolveState ("Spawn.Single");
                else if (amount > 0 && amount != 6) {
                    int amt = Amount;
                    amount = 1;
                    return ResolveState ("Spawn.Single");

                    for (int i = amt - 1; i > 0; i--) {
                        let act = Inventory (Spawn (ownClass, pos));

                        if (!act)
                            continue;

                        act.Amount = 1;
                        act.vel = (vel + AngleToVector (fRandom [invSpc] (0, 360), fRandom [invSpc] (1, 5)));
                        act.target = target;
                        act.master = master;
                        act.tracer = tracer;
                        act.ChangeTID (TID);
                    }
                }
            }

            return ResolveState (null);
        }
        stop;
    Spawn.Single:
        TNT1 A  0 A_SetScale (0.25);
        SHEL F -1;
        stop;
    }
}

class S7_12gaShellsSmall : S7_12gaShells {
    default {
        Inventory.PickupMessage "$12GASMALL";
        Inventory.Amount 3;
    }

    states {
    Spawn:
        SHEL D -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Type A Energy Cells
//
//-------------------------------------------------------------------------------------------
class S7_Cells : Ammo {
    default {
        Tag "$CELLS";
        Inventory.PickupMessage "$CELLS";
        Inventory.Amount 18;
        Inventory.MaxAmount 216;
        // Ammo.BackpackMaxAmount 288;
        Inventory.Icon "CELLA0";
        Inventory.PickupSound "misc/ammopickup";
    }

    states {
    Spawn:
        CELL A -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Firebrand Systems Energy Cells
//
//-------------------------------------------------------------------------------------------
class S7_FBSysCells : Ammo {
    default {
        Tag "$FBSYSCELLS";
        Inventory.PickupMessage "$FBSYSCELLS";
        Inventory.Amount 32;
        Inventory.MaxAmount 192;
        // Ammo.BackpackMaxAmount 184;
        Inventory.Icon "CELLC0";
        Inventory.PickupSound "misc/ammopickup";
    }

    states {
    Spawn:
        CELL C -1;
        stop;
    }
}

class S7_FBSysCellPack : S7_FBSysCells {
    default {
        Tag "$FBSYSCELLPACK";
        Inventory.PickupMessage "$FBSYSCELLPACK";
        Inventory.Amount 64;
        Inventory.PickupSound "misc/ammopickup";
    }

    states {
    Spawn:
        CELL D -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Antimatter shells
//
//-------------------------------------------------------------------------------------------
class S7_AntimatterShells : Ammo {
    default {
        Tag "$ANTISHELLS";
        Inventory.PickupMessage "$ANTISHELLS";
        Inventory.Amount 1;
        Inventory.MaxAmount 4;
        //Inventory.Icon "ANSHA0";
        Inventory.PickupSound "misc/ammopickup";
    }

    states {
    Spawn:
        ANSH A -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Thumper. AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
//
//-------------------------------------------------------------------------------------------
class S7_Thumper_PExp     : Ammo { default { Inventory.Amount 0; Inventory.MaxAmount 40; +INVENTORY.IGNORESKILL } }
class S7_Thumper_PFrag    : Ammo { default { Inventory.Amount 0; Inventory.MaxAmount 40; +INVENTORY.IGNORESKILL } }
class S7_Thumper_PTherm   : Ammo { default { Inventory.Amount 0; Inventory.MaxAmount 40; +INVENTORY.IGNORESKILL } }
class S7_Thumper_PFlare   : Ammo { default { Inventory.Amount 0; Inventory.MaxAmount 40; +INVENTORY.IGNORESKILL } }
class S7_Thumper_PCluster : Ammo { default { Inventory.Amount 0; Inventory.MaxAmount 40; +INVENTORY.IGNORESKILL } }
class S7_Thumper_PNail    : Ammo { default { Inventory.Amount 0; Inventory.MaxAmount 40; +INVENTORY.IGNORESKILL } }
class S7_Thumper_PNGas    : Ammo { default { Inventory.Amount 0; Inventory.MaxAmount 40; +INVENTORY.IGNORESKILL } }
class S7_Thumper_PUnified : Ammo {
    default {
        Inventory.Amount 0;
        Inventory.MaxAmount 40;

        +INVENTORY.IGNORESKILL
    }

    static clearscope int CalculateUnifiedAmount (Actor act) {
        return (
            act.CountInv ('S7_Thumper_PExp'    ) +
            act.CountInv ('S7_Thumper_PFrag'   ) +
            act.CountInv ('S7_Thumper_PTherm'  ) +
            act.CountInv ('S7_Thumper_PFlare'  ) +
            act.CountInv ('S7_Thumper_PCluster') +
            act.CountInv ('S7_Thumper_PNail'   ) +
            act.CountInv ('S7_Thumper_PNGas'   )
        );
    }

    override void DoEffect () {
        Super.DoEffect ();

        amount = CalculateUnifiedAmount (Owner);
    }
}