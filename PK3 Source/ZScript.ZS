version "2.5"

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
class S7_IsLoaded : actor {
    default {
        +noClip +noBlockmap +thruActors +noInteraction
    }

    states {
    Spawn:
        TNT1 A 2;
        stop;
    }
}

#INCLUDE "S7ZScript/zgui/zgui.ZS"
#INCLUDE "S7ZScript/Constants.ZS"
#INCLUDE "S7ZScript/Defaults.ZS"
#INCLUDE "S7ZScript/Extensions.ZS"
#INCLUDE "S7ZScript/MathExtensions.ZS"

// ZGui stuff
#include "S7ZScript/GUI/BaseMenu.ZS"
#include "S7ZScript/GUI/ZGuiControls/BaseControl.ZS"
#include "S7ZScript/GUI/ZGuiControls/Button.ZS"
#include "S7ZScript/GUI/ZGuiControls/Label.ZS"
#include "S7ZScript/GUI/ZGuiControls/Image.ZS"

// Effects
#INCLUDE "S7ZScript/Effects/Smoke.ZS"
#INCLUDE "S7ZScript/Effects/Casings.ZS"
#INCLUDE "S7ZScript/Effects/Shrapnel.ZS"
#INCLUDE "S7ZScript/Effects/Blood.ZS"
#INCLUDE "S7ZScript/Effects/Teleport.ZS"
#INCLUDE "S7ZScript/Effects/Parkour.ZS"
#INCLUDE "S7ZScript/Effects/MapEvents.ZS"
#INCLUDE "S7ZScript/Effects/Gore.ZS"
#INCLUDE "S7ZScript/Effects/Fire.ZS"

// Common stuff
#INCLUDE "S7ZScript/CommonTokens.ZS"
#INCLUDE "S7ZScript/Base Actors.ZS"
#INCLUDE "S7ZScript/Base Weapon.ZS"
#INCLUDE "S7ZScript/Bullets.ZS"

// RPG Systems
#INCLUDE "S7ZScript/RPG Systems/Shop System.ZS"
#INCLUDE "S7ZScript/RPG Systems/XP System.ZS"
#INCLUDE "S7ZScript/RPG Systems/Upgrades.ZS"

// Menus
#INCLUDE "S7ZScript/GUI/Menus/XPSystemMenu.ZS"
#INCLUDE "S7ZScript/GUI/Menus/WeapAssignmentMenu.ZS"

// Monsters
#INCLUDE "S7ZScript/Monsters/Spawners.ZS"
#INCLUDE "S7ZScript/Monsters/ScorpsTrooper/ScorpsTrooper.ZS"
#INCLUDE "S7ZScript/Monsters/Hellion/Hellion.ZS"
#INCLUDE "S7ZScript/Monsters/Succubus/Succubus.ZS"
#INCLUDE "S7ZScript/Monsters/BlackPanther/BlackPanther.ZS"
#INCLUDE "S7ZScript/Monsters/Empress/Empress.ZS"
#INCLUDE "S7ZScript/Monsters/Empress/Effects.ZS"
#INCLUDE "S7ZScript/Monsters/Empress/Spawner.ZS"
#INCLUDE "S7ZScript/Monsters/Empress/Invuln.ZS"
#INCLUDE "S7ZScript/Monsters/FatFuck/FatFuck.ZS"
#INCLUDE "S7ZScript/Monsters/Terminator/Terminator.ZS"
#INCLUDE "S7ZScript/Monsters/ScorpsEnforcer/ScorpsEnforcer.ZS"

// Inventory
#INCLUDE "S7ZScript/Inventory/Health.ZS"
#INCLUDE "S7ZScript/Inventory/Keys.ZS"
#INCLUDE "S7ZScript/Inventory/Berserk.ZS"
#INCLUDE "S7ZScript/Inventory/Loot.ZS"

// Player stuff
#INCLUDE "S7ZScript/CheatThingy.ZS"
#INCLUDE "S7ZScript/Player.ZS"
#INCLUDE "S7ZScript/WeapBindsSystem.ZS"
#INCLUDE "S7ZScript/Scout.ZS"

// GUI
#INCLUDE "S7ZScript/GUI/Statusbar.ZS"
#INCLUDE "S7ZScript/GUI/StatusbarMisc.ZS"

// Ammo
#INCLUDE "S7ZScript/Inventory/Ammo.ZS"

// Misc
#INCLUDE "S7ZScript/Props.ZS"

// Weapons
#INCLUDE "S7ZScript/Weapons/Unarmed.ZS"
// Primary
#INCLUDE "S7ZScript/Weapons/Primary/Shotgun/Shotgun.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/AMG/AMG.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/ManxCarbine/ManxCarbine.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/PrettyShootyIonCannonGun/PrettyShootyIonCannonGun.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/PlasmaGun/ChargeProj.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/PlasmaGun/PlasmaGun.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/Thumper/Casings.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/Thumper/Grenades.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/Thumper/Thumper.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/Hitter/Hitter.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/Fauchard/Fauchard.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/SSG/SSG.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/LaserPewPew/LaserPewPew.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/ConquerorRifle/ConquerorRifle.ZS"
#INCLUDE "S7ZScript/Weapons/Primary/AK47/AK47.ZS"
// Secondary
#INCLUDE "S7ZScript/Weapons/Secondary/Raptor/Raptor.ZS"
#INCLUDE "S7ZScript/Weapons/Secondary/TEC-9/TEC-9.ZS"
#INCLUDE "S7ZScript/Weapons/Secondary/Revolver/Revolver.ZS"
// Throwables
#INCLUDE "S7ZScript/Weapons/Throwables/Grenade/Grenade.ZS"