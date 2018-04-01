version "3.3"

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
** Credits for the sprites is in the CREDITS.txt files contained in the
** same folder as the ZScript code for the actor. Sprites used in multi-
** ple actors should be in Credits/Sprites.TXT.
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
#include "S7ZScript/Common/ErrorHandling.ZS"
#include "S7ZScript/Common/Extensions.ZS"
#include "S7ZScript/Common/MathExtensions.ZS"
#include "S7ZScript/Common/ActorExtensions.ZS"
#include "S7ZScript/Common/Utils.ZS"
#include "S7ZScript/Common/ServerData.ZS"
#include "S7ZScript/Common/CommonTokens.ZS"
#include "S7ZScript/EventHandlers.ZS"
#include "S7ZScript/Weapons/WeapData.ZS"
#include "S7ZScript/MD5.ZS"

// Bases
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
#include "S7ZScript/Effects/MapEvents.ZS"
#include "S7ZScript/Effects/Gore.ZS"
#include "S7ZScript/Effects/Fire.ZS"

// RPG Systems
#include "S7ZScript/RPG Systems/Shop System.ZS"
#include "S7ZScript/RPG Systems/ShopData.ZS"
#include "S7ZScript/RPG Systems/ShopData/Lucius.ZS"
#include "S7ZScript/RPG Systems/XP System.ZS"
#include "S7ZScript/RPG Systems/Upgrades.ZS"

// Menus
#include "S7ZScript/GUI/Menus/XPSystemMenu.ZS"
#include "S7ZScript/GUI/Menus/WeapAssignmentMenu/WeapSelList.ZS"
#include "S7ZScript/GUI/Menus/WeapAssignmentMenu/Main.ZS"
#include "S7ZScript/GUI/Menus/ShopMenu/List.ZS"
#include "S7ZScript/GUI/Menus/ShopMenu/BuySellPopup.ZS"
#include "S7ZScript/GUI/Menus/ShopMenu/Main.ZS"
#include "S7ZScript/GUI/Menus/PlayerMenu.ZS"

// Monsters
#include "S7ZScript/Monsters/Base Monsters.ZS"
#include "S7ZScript/Monsters/Spawners.ZS"
#include "S7ZScript/Monsters/ScorpsTrooper/ScorpsTrooper.ZS"
#include "S7ZScript/Monsters/Hellion/Hellion.ZS"
#include "S7ZScript/Monsters/Succubus/Succubus.ZS"
#include "S7ZScript/Monsters/BlackPanther/BlackPanther.ZS"
#include "S7ZScript/Monsters/Empress/Empress.ZS"
#include "S7ZScript/Monsters/Empress/Effects.ZS"
#include "S7ZScript/Monsters/Empress/Spawner.ZS"
#include "S7ZScript/Monsters/Empress/Invuln.ZS"
#include "S7ZScript/Monsters/FatFuck/FatFuck.ZS"
#include "S7ZScript/Monsters/Terminator/Terminator.ZS"
#include "S7ZScript/Monsters/ScorpsEnforcer/ScorpsEnforcer.ZS"
#include "S7ZScript/Monsters/ScorpsHunter/ScorpsHunter.ZS"

// Inventory
#include "S7ZScript/Inventory/Armor.ZS"
#include "S7ZScript/Inventory/Health.ZS"
#include "S7ZScript/Inventory/Keys.ZS"
#include "S7ZScript/Inventory/Berserk.ZS"
#include "S7ZScript/Inventory/Loot.ZS"

// Player stuff
#include "S7ZScript/Player/Player.ZS"
#include "S7ZScript/Player/PlayerE_Movement.ZS"
#include "S7ZScript/Player/PlayerE_Weapon.ZS"
#include "S7ZScript/Player/PlayerE_Cheats.ZS"
#include "S7ZScript/Player/PlayerE_Misc.ZS"
#include "S7ZScript/Player/PlayerXPSystem.ZS"
#include "S7ZScript/Player/WeapBindsSystem.ZS"
#include "S7ZScript/Player/HealingSystem.ZS"
#include "S7ZScript/Player/Armor.ZS"
#include "S7ZScript/Player/Scout.ZS"
#include "S7ZScript/Player/Draco/DracoPlayer.ZS"
#include "S7ZScript/Player/Draco/DefenseMatrix.ZS"

// GUI
#include "S7ZScript/GUI/HUDMessage.ZS"
#include "S7ZScript/GUI/BaseStatusbar.ZS"
#include "S7ZScript/GUI/Statusbar.ZS"
#include "S7ZScript/GUI/StatusbarMisc.ZS"
#include "S7ZScript/GUI/NewMenuItems/SpecialSlider.ZS"

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
// Secondary
#include "S7ZScript/Weapons/Secondary/Raptor/Raptor.ZS"
#include "S7ZScript/Weapons/Secondary/TEC-9/TEC-9.ZS"
#include "S7ZScript/Weapons/Secondary/Revolver/Revolver.ZS"
// Special
#include "S7ZScript/Weapons/Special/HellBlade/Common.ZS"
// Throwables
#include "S7ZScript/Weapons/Throwables/Grenade/Grenade.ZS"