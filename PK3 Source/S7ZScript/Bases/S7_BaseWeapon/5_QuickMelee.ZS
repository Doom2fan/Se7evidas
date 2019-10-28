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
// Melee type tokens
//
//-------------------------------------------------------------------------------------------
/* Credits:
** Sprites: Apocalyptic Studio, Captain J, Chronos "phantombeta" Ouroboros
** Animation: Chronos "phantombeta" Ouroboros
** Sounds: Credits in the SNDINFO file
*/
class S7_DaggerMelee : S7_Boolean { }

/* Credits:
** Sprites: Captain J, Chronos "phantombeta" Ouroboros
** Animation: Chronos "phantombeta" Ouroboros
** Sounds: Credits in the SNDINFO file
*/
class S7_MacheteMelee : S7_Boolean { }

/* Credits:
** Sprites: ???, Chronos "phantombeta" Ouroboros
** Animation: Chronos "phantombeta" Ouroboros
** Sounds: Credits in the SNDINFO file
*/
//class S7_KickMelee : S7_Boolean { }

extend class S7_BaseWeapon {
    bool meleeAttackSoundPlayed;
    action void S7_QuickMeleeCustomPunch (int damage, Class<Actor> puffType) {
        let puff = S7_CustomPunch (damage, 0, puffType, damageType: 'QuickMelee');

        if (!puff)
            return;

        if (invoker.meleeAttackSoundPlayed) {
            for (int i = CHAN_Auto; i < CHAN_7; i++)
                puff.A_StopSound (i);
        }

        let crashState = puff.FindState ("Crash"),
            xdeathState = puff.FindState ("XDeath");
        if (puff.InStateSequence (puff.CurState, crashState) ||
            puff.InStateSequence (puff.CurState, xdeathState))
            invoker.meleeAttackSoundPlayed = true;
    }

    states {
    QuickMelee:
        TNT1 A 0 {
            TakeInventory ('S7_DoMelee', 0x7FFFFFFF);
            if (CheckInventory ('S7_DaggerMelee', 1))
                return ResolveState ("DaggerMelee");
            if (CheckInventory ('S7_MacheteMelee', 1))
                return ResolveState ("MacheteMelee");

            return ResolveState ("KickMelee");
        }

    DaggerMelee:
        TNT1 A 0 A_Jump (256, "DaggerMelee1", "DaggerMelee2");
        wait;
    DaggerMelee1:
        DAG1 ABCD 1;
        DAG1 E    1 {
            A_PlaySound ("Weapons/Tridagger/Swing", CHAN_Weapon);
            S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (9. + fRandom [weaponDamage] (-0.5, 1.0)), 'S7_DaggerPuff');
        }
        DAG1 F    1 S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (9. + fRandom [weaponDamage] (-0.5, 1.0)), 'S7_DaggerPuff');
        DAG1 G    1 S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (9. + fRandom [weaponDamage] (-0.5, 1.0)), 'S7_DaggerPuff');
        DAG1 H    1 { invoker.meleeAttackSoundPlayed = false; }
        TNT1 A    5;
        TNT1 A    0 A_Jump (256, "MeleeDone");
        wait;
    DaggerMelee2:
        DAG2 AB 1;
        DAG2 C  1 {
            A_PlaySound ("Weapons/Tridagger/Swing", CHAN_Weapon);
            S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (9. + fRandom [weaponDamage] (-0.5, 1.0)), 'S7_DaggerPuff');
        }
        DAG2 D  1 S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (9. + fRandom [weaponDamage] (-0.5, 1.0)), 'S7_DaggerPuff');
        DAG2 E  1 S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (9. + fRandom [weaponDamage] (-0.5, 1.0)), 'S7_DaggerPuff');
        DAG2 F  1 { invoker.meleeAttackSoundPlayed = false; }
        DAG2 GH 1;
        TNT1 A  5;
        TNT1 A  0 A_Jump (256, "MeleeDone");
        wait;

    MacheteMelee:
        TNT1 A  4;
        KNF1 AB 1;
        KNF1 C  1 {
            A_PlaySound ("Weapons/Machete/Swing", CHAN_Weapon);
            S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (15.35 + fRandom [weaponDamage] (-2, 5)), 'S7_MachetePuff');
        }
        KNF1 D  1 S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (15.35 + fRandom [weaponDamage] (-2, 5)), 'S7_MachetePuff');
        KNF1 E  1 S7_QuickMeleeCustomPunch (S7_GetMeleeDamage (15.35 + fRandom [weaponDamage] (-2, 5)), 'S7_MachetePuff');
        KNF1 F  1 { invoker.meleeAttackSoundPlayed = false; }
        TNT1 A 12;
        TNT1 A 0 A_Jump (256, "MeleeDone");
        wait;

    KickMelee:
        KICK BCD   1;
        KICK H     1 S7_CustomPunch (S7_GetMeleeDamage (30. + fRandom [weaponDamage] (-2.5, 5)), 0, 'S7_MeleePuff');
        KICK HHHIG 1;
        KICK FEDCB 1;
        KICK A     1;

        TNT1 A 0 A_Jump (256, "MeleeDone");
        wait;

    MeleeDone:
        TNT1 A 0 A_JumpIfInventory ('S7_DoMelee', 1, "QuickMelee");
        TNT1 A 0 A_Jump (256, "Ready");
        wait;
    }
}

//-------------------------------------------------------------------------------------------
//
// Melee puffs
//
//-------------------------------------------------------------------------------------------
class S7_MeleePuff : S7_EffectsBase {
    default {
        DamageType 'Kick';
        AttackSound "Weapons/Kick/HitWall";
        ActiveSound "Weapons/Kick/Swing";

        +NOBLOCKMAP +NOGRAVITY +PUFFONACTORS +NOEXTREMEDEATH
    }

    states {
    Spawn:
        TNT1 A 1;
        stop;
    Crash:
        TNT1 A 1;
        stop;
    XDeath:
        TNT1 A 1;
        stop;
    }
}

class S7_MeleePuffStrong : S7_MeleePuff {
    default {
        Decal 'FistScorch';
        AttackSound "Weapons/Kick/Strong";
        ActiveSound "Weapons/Kick/Swing";

        +EXTREMEDEATH
        -NOEXTREMEDEATH
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnItem ('S7_ShotSmoke');
        stop;
    }
}

class S7_DaggerPuff : S7_MeleePuff {
    default {
        DamageType 'Blade';
        ActiveSound "";
        AttackSound "Weapons/Tridagger/HitWall";
        SeeSound "Weapons/Tridagger/HitFlesh";
    }
}

class S7_MachetePuff : S7_MeleePuff {
    default {
        DamageType 'Blade';
        ActiveSound "";
        AttackSound "Weapons/Machete/HitWall";
        SeeSound "Weapons/Machete/HitFlesh";
    }
}