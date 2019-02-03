/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
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
// Life essence
//
//-------------------------------------------------------------------------------------------
/* Credits:
** Sprites: Eriance
*/
class S7_HeartSphere : Inventory { // I am not good at naming things
    double maxHealFactor;
    property MaxHealFactor: maxHealFactor;

    default {
        Inventory.MaxAmount 0;
        Inventory.PickupMessage "$HEARTSPHERE_PICKUP";
        S7_HeartSphere.MaxHealFactor 1.5;

        +INVENTORY.AUTOACTIVATE +INVENTORY.ALWAYSPICKUP +INVENTORY.FANCYPICKUPSOUND +COUNTITEM
    }

    override bool TryPickup (in out Actor toucher) {
        bool alwaysPickup = false;

        if (toucher && toucher.player) {
            CVar alwaysPickupCVar = CVar.GetCVar ("S7_AlwaysPickupHealthSpheres", toucher.player);
            alwaysPickup = alwaysPickupCVar.GetInt ();
        }

        if (!alwaysPickup) {
            let pPawn = PlayerPawn (toucher);
            if (pPawn && pPawn.health >= (pPawn.GetMaxHealth () * maxHealFactor)) {
                bAlwaysPickup = false;
                return false;
            }
        }

        bAlwaysPickup = true;
        return Super.TryPickup (toucher);
    }

    override bool Use (bool pickup) {
        let pPawn = PlayerPawn (Owner);
        if (!pPawn || pPawn.health <= 0 || pPawn.bKilled)
            return true;

        int maxHealth = pPawn.GetMaxHealth ();
        pPawn.GiveBody (maxHealth, int (maxHealth * maxHealFactor));
        
        return true;
    }

    states {
    Spawn:
        SPWR A   23 bright;
        SPWR BCD  4 bright;
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Soulsphere
//
//-------------------------------------------------------------------------------------------
/* Credits:
** Sprites: Eriance
*/
class S7_SoulSphere : S7_HeartSphere {
    default {
        Inventory.PickupMessage "$SOULSPHERE_PICKUP";
        S7_HeartSphere.MaxHealFactor 2.;
    }

    override bool Use (bool pickup) {
        Super.Use (pickup);

        Owner.GiveInventory ('S7_ArmorBonus', random [invSpc] (25, 35));
        let armor = S7_BasicArmor (Owner.FindInventory ('S7_BasicArmor'));
        if (armor && armor.armorData)
            armor.armorData.FixArmor (armor, 0x7FFFFFFF);
        
        return true;
    }

    states {
    Spawn:
        SPWR EFGH 4 bright;
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Demon eyes
//
//-------------------------------------------------------------------------------------------
class S7_DemonEyes_Power : PowerLightAmp {
    default {
        Powerup.Duration -120;
    }

    override void DoEffect () {
        Super.DoEffect ();

        if (Owner.player) {
            if (!isBlinking ())
                Shader.SetEnabled (Owner.player, "S7_DemonEyes", true);
            else
                Shader.SetEnabled (Owner.player, "S7_DemonEyes", false);
        }
    }

    override void EndEffect () {
        Super.EndEffect ();

        if (Owner && Owner.player)
            Shader.SetEnabled (Owner.player, "S7_DemonEyes", false);
    }

    override void DetachFromOwner () {
        if (Owner && Owner.player)
            Shader.SetEnabled (Owner.player, "S7_DemonEyes", false);

        Super.DetachFromOwner ();
    }

    override void OnDestroy () {
        if (Owner && Owner.player)
            Shader.SetEnabled (Owner.player, "S7_DemonEyes", false);

        Super.OnDestroy ();
    }
}

class S7_DemonEyes : PowerupGiver {
    default {
        Inventory.MaxAmount 0;
        Inventory.PickupMessage "$DEMONEYES_PICKUP";
        Powerup.Type "S7_DemonEyes_Power";

        +INVENTORY.AUTOACTIVATE +INVENTORY.ALWAYSPICKUP +COUNTITEM
    }

    states {
    Spawn:
        S7DE ABCD 4 bright;
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Map
//
//-------------------------------------------------------------------------------------------
class S7_MapPowerup : MapRevealer {
    default {
        Inventory.MaxAmount 0;
        Inventory.PickupMessage "$MAP_PICKUP";
        Scale 0.5;

        +INVENTORY.AUTOACTIVATE +INVENTORY.ALWAYSPICKUP +INVENTORY.FANCYPICKUPSOUND +COUNTITEM
    }

    states {
    Spawn:
        S7MP ABCDCB 4 bright;
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Biosphere
//
//-------------------------------------------------------------------------------------------
class S7_BiospherePower : PowerIronFeet {
    default {
        Powerup.Duration -80;
        Powerup.Colormap 0, 0, 0, 0.2, 1.5, 0.2;
    }

    override void DoEffect () {
        Powerup.DoEffect ();
        Super.DoEffect ();
    }
}

class S7_Biosphere : PowerupGiver {
    default {
        Inventory.MaxAmount 0;
        Inventory.PickupMessage "$BIOSPHERE_PICKUP";
        Powerup.Type 'S7_BiospherePower';

        +INVENTORY.AUTOACTIVATE +INVENTORY.ALWAYSPICKUP
    }

    states {
    Spawn:
        BIOS AB 12 bright;
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Invisibility
//
//-------------------------------------------------------------------------------------------
class S7_Invisibility_Power : PowerInvisibility {
    default {
        Powerup.Duration -90;
        Powerup.Mode "Fuzzy";

        -SHADOW
    }
}

class S7_Invisibility : PowerupGiver {
    default {
        Inventory.MaxAmount 0;
        Inventory.PickupMessage "$INVISIBILITY_PICKUP";
        Powerup.Type 'S7_Invisibility_Power';

        +INVENTORY.AUTOACTIVATE +INVENTORY.ALWAYSPICKUP +COUNTITEM
    }

    int fuzzyTics;

    override void Tick () {
        Super.Tick ();

        if (Owner)
            return;

        if (fuzzyTics-- > 0)
            A_SetRenderStyle (1.0, STYLE_Fuzzy);
        else {
            A_SetRenderStyle (1.0, STYLE_Normal);

            if (fuzzyTics <= -17) {
                if (random [invMisc] (0, 255) < 32) {
                    if (random [invMisc] (0, 255) < 16)
                        fuzzyTics = random [invMisc] (17, 35);
                    else
                        fuzzyTics = random [invMisc] (3, 5);
                } else
                    fuzzyTics = random [invMisc] (-8, 0);
            }
        }

        if (globalfreeze || level.frozen)
            return;
        
        let act = Spawn ('S7_InvulnerabilityEffect', pos);
        if (act) {
            act.A_SetRenderStyle (act.Alpha, STYLE_Translucent);
            act.vel = vel + (frandom [sfx] (-1.5, 1.5), frandom [sfx] (-1.5, 1.5), frandom [sfx] (-1.5, 1.5));
            act.sprite = sprite;
            act.frame = frame;
        }
    }

    states {
    Spawn:
        SPWR IJIK 6 bright;
        loop;
    }
}