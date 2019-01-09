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

version "3.7.1"

/* Info
** You can use anything from here. Just make sure to credit the author(s).
**
** Credits for the ZScript code are in the files or in the CREDITS file
** contained in the same folder as the file.
**
** Credits for the sound files are in the SNDINFO files.
** Credits for a lot of shit is in the Credits folder.
** Credits for the final muzzle flashes goes to me, Chronos "phantombeta"
** Ouroboros.
**
** Credits for the sprites are usually in "CREDITS.txt" files contained in
** the same folder as the ZScript code for the actor or in a comment in
** the ZScript code.
** Credits for sprites used in various actors should be in the file
** "Sprites.TXT" located in the "Credits" folder.
*/

/* Highest free DoomEdNums:
** Weapons: 30014
** Ammo: 31012
** Inventory: 32006
** Monster: 32509
*/

/* Some random units:
** 32 mapunits (Physical) = 1 meter
** 38.4 Z mapunits (Visual) = 1 meter
*/

// So maps and other mods can check for S7
class S7_IsLoaded : Actor {
    default {
        +NOCLIP +NOBLOCKMAP +THRUACTORS +NOINTERACTION
    }

    states {
    Spawn:
        TNT1 A 2;
        stop;
    }
}

// Common stuff
#include "S7ZScript/ZForms/ZF_Include.ZS"
#include "S7ZScript/TZKsUtils/TZK_Include.ZS"
#include "S7ZScript/Constants.ZS"
#include "S7ZScript/Defaults.ZS"
#include "S7ZScript/Common/Hashmaps.ZS"
#include "S7ZScript/Common/ErrorHandling.ZS"
#include "S7ZScript/Common/Extensions.ZS"
#include "S7ZScript/Common/MathExtensions.ZS"
#include "S7ZScript/Common/ActorExtensions.ZS"
#include "S7ZScript/Common/Utils.ZS"
#include "S7ZScript/Common/ServerData.ZS"
#include "S7ZScript/Common/CommonTokens.ZS"
#include "S7ZScript/Common/S7Data.ZS"
#include "S7ZScript/EventHandlers.ZS"
#include "S7ZScript/Weapons/WeapData.ZS"
#include "S7ZScript/MD5.ZS"

// Bases
#include "S7ZScript/Bases/Base Parser.ZS"
#include "S7ZScript/Bases/Base Actors.ZS"
#include "S7ZScript/Bases/Base Weapon.ZS"
#include "S7ZScript/Bases/Bullets.ZS"

// Effects
#include "S7ZScript/Effects/Smoke.ZS"
#include "S7ZScript/Effects/Casings.ZS"
#include "S7ZScript/Effects/Shrapnel.ZS"
#include "S7ZScript/Effects/Blood.ZS"
#include "S7ZScript/Effects/Teleport.ZS"
#include "S7ZScript/Effects/Parkour.ZS"
#include "S7ZScript/Effects/Gore.ZS"
#include "S7ZScript/Effects/Fire.ZS"

// RPG Systems
#include "S7ZScript/RPG Systems/Shop System.ZS"
#include "S7ZScript/RPG Systems/XP System.ZS"
#include "S7ZScript/RPG Systems/Upgrades.ZS"

// Map event stuff
#include "S7ZScript/MapEvents/MapEventThinker.ZS"
#include "S7ZScript/MapEvents/PerfectHatred.ZS"

// Menus
#include "S7ZScript/GUI/Menus/XPSystemMenu.ZS"
#include "S7ZScript/GUI/Menus/WeapAssignmentMenu/WeapSelList.ZS"
#include "S7ZScript/GUI/Menus/WeapAssignmentMenu/Main.ZS"
#include "S7ZScript/GUI/Menus/ShopMenu/List.ZS"
#include "S7ZScript/GUI/Menus/ShopMenu/BuySellPopup.ZS"
#include "S7ZScript/GUI/Menus/ShopMenu/Main.ZS"
#include "S7ZScript/GUI/Menus/PlayerMenu.ZS"
#include "S7ZScript/GUI/Menus/PlayerclassMenu.ZS"
#include "S7ZScript/GUI/Menus/AutogunMenu.ZS"

// Monsters
#include "S7ZScript/Monsters/Base Monsters.ZS"
#include "S7ZScript/Monsters/MonsterBase_Aiming.ZS"
#include "S7ZScript/Monsters/MonsterBase_Look.ZS"
#include "S7ZScript/Monsters/MonsterBase_Chase.ZS"
#include "S7ZScript/Monsters/MonsterBase_Movement.ZS"
#include "S7ZScript/Monsters/MonsterBase_AI_Searching.ZS"
#include "S7ZScript/Monsters/Spawners.ZS"
#include "S7ZScript/Monsters/ScorpsTrooper/ScorpsTrooper.ZS"
#include "S7ZScript/Monsters/Hellion/Hellion.ZS"
#include "S7ZScript/Monsters/Succubus/Succubus.ZS"
#include "S7ZScript/Monsters/BlackPanther/BlackPanther.ZS"
#include "S7ZScript/Monsters/Empress/Empress.ZS"
#include "S7ZScript/Monsters/Empress/Effects.ZS"
#include "S7ZScript/Monsters/Empress/Invuln.ZS"
#include "S7ZScript/Monsters/FatFuck/FatFuck.ZS"
#include "S7ZScript/Monsters/Terminator/Terminator.ZS"
#include "S7ZScript/Monsters/ScorpsEnforcer/ScorpsEnforcer.ZS"
#include "S7ZScript/Monsters/ScorpsHunter/ScorpsHunter.ZS"
#include "S7ZScript/Monsters/DemonDog/DemonDog.ZS"
#include "S7ZScript/Monsters/Mechdemon/Mechdemon.ZS"
#include "S7ZScript/Monsters/Shadow/Shadow.ZS"
#include "S7ZScript/Monsters/InfernalGuardian/InfernalGuardian.ZS"
#include "S7ZScript/Monsters/Infernal/Infernal.ZS"
#include "S7ZScript/Monsters/FleshSpawn/FleshSpawn.ZS"
#include "S7ZScript/Monsters/FleshSpawn/Gibs.ZS"

// Inventory
#include "S7ZScript/Inventory/Armor.ZS"
#include "S7ZScript/Inventory/Health.ZS"
#include "S7ZScript/Inventory/Keys.ZS"
#include "S7ZScript/Inventory/Berserk.ZS"
#include "S7ZScript/Inventory/Loot.ZS"
#include "S7ZScript/Inventory/Flashlight.ZS"
#include "S7ZScript/Inventory/Invulnerability.ZS"
#include "S7ZScript/Inventory/Powerups.ZS"
#include "S7ZScript/Inventory/WeaponMods.ZS"
#include "S7ZScript/Inventory/Armor/SecurityVest.ZS"
#include "S7ZScript/Inventory/Armor/CombatArmor.ZS"
#include "S7ZScript/Inventory/Spawners/Weapon.ZS"
#include "S7ZScript/Inventory/Spawners/Ammo.ZS"
#include "S7ZScript/Inventory/Spawners/Powerups.ZS"
#include "S7ZScript/Inventory/Spawners/Items.ZS"
#include "S7ZScript/Inventory/Turret/Turret.ZS"

// Player stuff
#include "S7ZScript/Player/Player.ZS"
#include "S7ZScript/Player/PlayerE_Movement.ZS"
#include "S7ZScript/Player/PlayerE_Weapon.ZS"
#include "S7ZScript/Player/PlayerE_Cheats.ZS"
#include "S7ZScript/Player/PlayerE_Misc.ZS"
#include "S7ZScript/Player/PlayerE_Stealth.ZS"
#include "S7ZScript/Player/PlayerXPSystem.ZS"
#include "S7ZScript/Player/WeapBindsSystem.ZS"
#include "S7ZScript/Player/HealingSystem.ZS"
#include "S7ZScript/Player/Armor.ZS"

// Player classes
#include "S7ZScript/Player/Classes/Scout.ZS"
#include "S7ZScript/Player/Classes/Infiltrator.ZS"
#include "S7ZScript/Player/Classes/Medic.ZS"
#include "S7ZScript/Player/Classes/Infantry.ZS"

// Draco
#include "S7ZScript/Player/Draco/DracoPlayer.ZS"
#include "S7ZScript/Player/Draco/DefenseMatrix.ZS"

// GUI
#include "S7ZScript/GUI/HUDMessage.ZS"
#include "S7ZScript/GUI/BaseStatusbar.ZS"
#include "S7ZScript/GUI/Statusbar.ZS"
#include "S7ZScript/GUI/StatusbarMisc.ZS"
#include "S7ZScript/GUI/NewMenuItems/SpecialSlider.ZS"
#include "S7ZScript/GUI/NewMenuItems/CustomNumberField.ZS"

// Ammo
#include "S7ZScript/Inventory/Ammo.ZS"

// Misc
#include "S7ZScript/Misc/Props.ZS"
#include "S7ZScript/Misc/NamesList.ZS"
#include "S7ZScript/Misc/ACSBridge.ZS"
#include "S7ZScript/Misc/CheatThingy.ZS"

// Weapons
#include "S7ZScript/Weapons/Unarmed.ZS"
// Primary
#include "S7ZScript/Weapons/Primary/Shotgun/Shotgun.ZS"
#include "S7ZScript/Weapons/Primary/AMG/AMG.ZS"
#include "S7ZScript/Weapons/Primary/ManxCarbine/ManxCarbine.ZS"
#include "S7ZScript/Weapons/Primary/PrettyShootyIonCannonGun/PrettyShootyIonCannonGun.ZS"
#include "S7ZScript/Weapons/Primary/PlasmaGun/ChargeProj.ZS"
#include "S7ZScript/Weapons/Primary/PlasmaGun/PlasmaGun.ZS"
#include "S7ZScript/Weapons/Primary/Thumper/Casings.ZS"
#include "S7ZScript/Weapons/Primary/Thumper/Grenades.ZS"
#include "S7ZScript/Weapons/Primary/Thumper/Thumper.ZS"
#include "S7ZScript/Weapons/Primary/Hitter/Hitter.ZS"
#include "S7ZScript/Weapons/Primary/Fauchard/Fauchard.ZS"
#include "S7ZScript/Weapons/Primary/SSG/SSG.ZS"
#include "S7ZScript/Weapons/Primary/LaserPewPew/LaserPewPew.ZS"
#include "S7ZScript/Weapons/Primary/ConquerorRifle/ConquerorRifle.ZS"
#include "S7ZScript/Weapons/Primary/AK47/AK47.ZS"
#include "S7ZScript/Weapons/Primary/CaesarChaingun/CaesarChaingun.ZS"
// Secondary
#include "S7ZScript/Weapons/Secondary/Raptor/Raptor.ZS"
#include "S7ZScript/Weapons/Secondary/TEC-9/TEC-9.ZS"
#include "S7ZScript/Weapons/Secondary/Revolver/Revolver.ZS"
// Special
#include "S7ZScript/Weapons/Special/HellBlade/Common.ZS"
// Throwables
#include "S7ZScript/Weapons/Throwables/Grenade/Grenade.ZS"

// Parsers
#include "S7ZScript/Parsers/S7DATA/S7DATAParser.ZS"
#include "S7ZScript/Parsers/S7DATA/MapData.ZS"
#include "S7ZScript/Parsers/S7DATA/ShopData.ZS"
#include "S7ZScript/Parsers/S7DATA/ShopData/Pages.ZS"
#include "S7ZScript/Parsers/S7DATA/ShopData/Items.ZS"
#include "S7ZScript/Parsers/S7DATA/ShopData/PostProcessing.ZS"