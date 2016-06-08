/*
**  Se7evidas - A GZDoom mod
**  Copyright (C) 2015  Chronos Ouroboros
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
#include "misc/names.h"
#include "systems/monster_stuff.h"

MonsterInfo_t *monsterList;

void ClearMonsterList () {
    MonsterInfo_t *cur = monsterList;
    MonsterInfo_t *next;
    while (TRUE) {
        if (!monsterList)
            break;

        next = cur->next;
        cur->next = NULL;
        free (cur);
        cur = next;
    }
}

bool AddMonsterToList (MonsterInfo_t *monster) {
    if (monster->next != NULL)
        return FALSE;

    monster->next = monsterList;
    monsterList = monster;

    return TRUE;
}

void UpdateMonsterInfo (MonsterInfo_t *self) {
    if (StrICmp (GetActorClass (0), s"None") == 0 || StrICmp (GetActorClass (0), s"") == 0) {
        self->removed = TRUE;
        return;
    } else if (self->removed)
        self->removed = FALSE;

    self->x = GetActorX (0); self->y = GetActorY (0); self->z = GetActorZ (0);
    self->velX = GetActorVelX (0); self->velY = GetActorVelY (0); self->velZ = GetActorVelZ (0);
    self->angle = GetActorAngle (0); self->pitch = GetActorPitch (0);
    self->floorZ = GetActorFloorZ (0); self->ceilZ = GetActorCeilingZ (0);

    self->health = GetActorProperty (0, APROP_Health); self->maxHealth = GetActorProperty (0, APROP_SpawnHealth);
    if (self->health > self->maxHealth)
        self->maxHealth = self->health;
    self->tid = ActivatorTID ();
}

Script_C void S7_GenericMonsterScript () {
    MonsterInfo_t *self = allocAndClear (sizeof (MonsterInfo_t));
    AddMonsterToList (self);

    while (TRUE) {
        UpdateMonsterInfo (self);

        Delay (1);
    }
}

Script_C void S7_SuccubusScript () {
    MonsterInfo_t *self = allocAndClear (sizeof (MonsterInfo_t));
    vec3_k targetPos;
    bool flying = FALSE;
    AddMonsterToList (self);

    while (TRUE) {
        UpdateMonsterInfo (self);
        targetPos = GetActivatorPointerPos (AAPTR_TARGET);

        if (self->z - targetPos.z > 96.0k)
            flying = TRUE;
        else if ((self->z - self->floorZ) <= 0)
            flying = FALSE;
        else
            flying = TRUE;

        if (GetUserVariable (0, s"user_Flying") != flying)
            SetUserVariable (0, s"user_Flying", flying);

        Delay (1);
    }
}

Script_C void S7_ZombieScript () {
    string name = s"Reading name";
    int readDelay = Random (3, 6);
    MonsterInfo_t *self = allocAndClear (sizeof (MonsterInfo_t));
    AddMonsterToList (self);

    while (TRUE) {
        UpdateMonsterInfo (self);

        if (readDelay != 0xBAADBEEF && readDelay <= 0) {
            name = NL_GenMaleNameEng ();
            readDelay = 0xBAADBEEF;
        }

        if (StrCmp (GetActorPropertyString (0, APROP_NameTag), name) != 0)
            SetActorPropertyString (0, APROP_NameTag, name);

        /*if (GetActorProperty (0, APROP_Health) > 0)
            Log ("pitch: %k", GetActorPitch (0));*/

        Delay (1);

        if (readDelay != 0xBAADBEEF && readDelay > 0)
            readDelay--;
    }
}

Script_C void S7_EmpressScript () {
    if (!CheckInventory (EMPIDENT))
        return;

    int invulnDelay,
        ballsCount,
        newHealth, health;
    MonsterInfo_t *self = allocAndClear (sizeof (MonsterInfo_t));
    AddMonsterToList (self);

    newHealth = GetActorProperty (0, APROP_Health);
    health = EMPMHEALTH;
    while (TRUE) {
        UpdateMonsterInfo (self);

        ballsCount = CheckInventory (s"S7_EmpressBalls");
        health += -(0x7FFFFFFF - newHealth);

        if (health > EMPINVLIMIT || ballsCount > 0) {
            SetInventory (EMPINVTOKEN, FALSE);
            if (ballsCount > 0)
                invulnDelay = EMPINVDELAY;
        } else if (invulnDelay) {
            SetInventory (EMPINVTOKEN, FALSE);
            invulnDelay--;
        } else if (health <= EMPINVLIMIT && ballsCount < 1 && invulnDelay < 1)
            SetInventory (EMPINVTOKEN, TRUE);

        SetUserVariable (0, EMPHPVAR, health);

        Delay (1);

        if (!CheckInventory (ISDEADTOKEN)) {
            newHealth = GetActorProperty (0, APROP_Health);
            SetActorProperty (0, APROP_Health, 0x7FFFFFFF);
        } else {
            newHealth = 0x7FFFFFFF;

            if (GetActorProperty (0, APROP_Health) > 0) {
                SetActorProperty (0, APROP_Health, 0x7FFFFFFF);
            }
        }
    }
}

/*Script_C void S7_SLanceBeamGrab () {
    accum x1 = GetActorX (0), y1 = GetActorY (0), z1 = GetActorZ (0);
    accum x2, y2, z2, xDiff, yDiff, zDiff;
    long accum angel, bitch;
    int flickerDelay = Random (8, 35 * 2);
    bool justFlickered = FALSE;

    SetActivatorToTarget (0);

    while (TRUE) {
        if (!CheckInventory (s"S7_SoulLance_BeamGrabbed"))
            break;

        if (flickerDelay < 1) {
            GiveInventory (DISABLEHUDTOKEN, 1);
            flickerDelay = Random (8, 35 * 2);
            justFlickered = TRUE;
        } else {
            flickerDelay--;
        }

        x2 = GetActorX (0); y2 = GetActorY (0); z2 = GetActorZ (0);
        xDiff = x1 - x2; yDiff = y1 - y2; zDiff = z1 - z2;
        angel = FixedSqrt ((long accum) xDiff * xDiff + yDiff * yDiff);
        bitch = FixedSqrt ((long accum) xDiff * xDiff + yDiff * yDiff + zDiff * zDiff);
        //bitch = ScaleValueAccum (bitch, -1.0k, 1.0k, -0.25k, 0.25k);

        SetActorAngle (0, ScaleValueAccum (angel, 0.0k, 360.0k, 0.0k, 1.0k));
        //SetActorPitch (0, (accum) -(ScaleValueAccum (bitch, -1.0k, 1.0k, -0.25k, 0.25k)));
        PrintBold ("%k", (accum) angel);

        Delay (1);

        if (justFlickered) {
            TakeInventory (DISABLEHUDTOKEN, 0x7FFFFFFF);
            justFlickered = FALSE;
        }
    }
}*/

typedef struct SLanceBGI {
    vec3_k holderPos;
    int holderTID; int flags;
} SLanceBGI;
enum {
    BGIF_STOP1 = 1, BGIF_STOP2 = 1 << 1,
    BGIF_CANRESETTID = 1 << 2,
    BGIF_P1GONE = 1 << 3, BGIF_P2GONE = 1 << 4,
};

Script_C void S7_SLanceBeamGrabP2 (SLanceBGI *info);

Script_C void S7_SLanceBeamGrab () {
    SLanceBGI *info = allocAndClear (sizeof (SLanceBGI));
    int oldTID = ActivatorTID ();

    info->holderTID = UniqueTID (-10000, -5000);
    info->holderPos.x = GetActorX (0);
    info->holderPos.y = GetActorY (0);
    info->holderPos.z = GetActorZ (0);

    PrintBold ("%d", info->holderTID);

    S7_SLanceBeamGrabP2 (info);

    while (TRUE) {
        if (!CheckInventory (s"S7_SoulLance_BeamGrabbed") ||
             GetActorProperty (0, APROP_Health) <= 0 ||
             CheckInventory (ISDEADTOKEN) ||
            (CheckInventory (EMPINVTOKEN) && GetUserVariable (0, EMPHPVAR) <= 0) ||
            info->flags & BGIF_STOP1) {
            TakeInventory (s"S7_SoulLance_BeamGrabbed", 0x7FFFFFFF);
            info->flags |= BGIF_STOP2;
            break;
        }

        info->holderPos.x = GetActorX (0);
        info->holderPos.y = GetActorY (0);
        info->holderPos.z = GetActorZ (0);

        Delay (1);
    }

    info->flags |= BGIF_P1GONE;
    if (info->flags & BGIF_P1GONE && info->flags & BGIF_P2GONE)
        free (info);
    info = NULL;
}

Script_C void S7_SLanceBeamGrabP2 (SLanceBGI *info) {
    SetActivatorToTarget (0);

    int actorInfo = ClassifyActor (0);

    if (!PlayerInGame (PLN) ||
        !(actorInfo & ACTOR_PLAYER ||
            actorInfo & ACTOR_BOT) ||
        actorInfo & ACTOR_VOODOODOLL) {
        TakeInventory (s"S7_SoulLance_BeamGrabbed", 0x7FFFFFFF);
        info->flags |= BGIF_STOP1;
        return;
    }


    vec3_k playerPos, rotAngles;
    bool   justFlickered = FALSE;
    int    thingyTID     = UniqueTID (-10000, -5000);
    int    flickerDelay  = Random (8, 35 * 2);

    SpawnProjectile (0, s"S7_SoulLance_Beam_GrabbedSpawner", 0, 0, 0, 0, thingyTID);


    while (TRUE) {
        if (!CheckInventory (s"S7_SoulLance_BeamGrabbed") ||
            !PlayerInGame (PLN) ||
            GetActorProperty (0, APROP_Health) <= 0 ||
            info->flags & BGIF_STOP2) {
            TakeInventory (s"S7_SoulLance_BeamGrabbed", 0x7FFFFFFF);
            Thing_Remove (thingyTID);
            info->flags |= BGIF_STOP1;
            break;
        }

        if (flickerDelay < 1) {
            GiveInventory (DISABLEHUDTOKEN, 1);
            flickerDelay = Random (8, 35 * 2);
            justFlickered = TRUE;
        } else {
            flickerDelay--;
        }

        playerPos.x = GetActorX (0);
        playerPos.y = GetActorY (0);
        playerPos.z = GetActorZ (0);

        rotAngles = GetEulerAngles (info->holderPos, playerPos);

        ChangeActorAngle (0,          rotAngles.z, TRUE);
        ChangeActorPitch (0,         -rotAngles.y, TRUE);
        ChangeActorAngle (thingyTID,  rotAngles.z, TRUE);
        ChangeActorPitch (thingyTID, -rotAngles.y, TRUE);

        SetUserArray (thingyTID, s"user_off", 0,
            11.0k * ScaleValueAccum (AbsA (GetActorPitch (0)), 0.0k, 0.25k, 1.0k, 0.0k));
        SetUserArray (thingyTID, s"user_off", 1,
            0.0k);
        SetUserArray (thingyTID, s"user_off", 2,
            44.0k * (GetActorPropertyFixed (0, APROP_Height) / 56.0k));

        Delay (1);

        if (justFlickered) {
            TakeInventory (DISABLEHUDTOKEN, 0x7FFFFFFF);
            justFlickered = FALSE;
        }
    }

    info->flags |= BGIF_P2GONE;
    if (info->flags & BGIF_P1GONE && info->flags & BGIF_P2GONE)
        free (info);
    info = NULL;
}

Script_C void FloatTest () {
    while (TRUE) {
        PrintBold ("%k", GetActorPropertyFixed (0, APROP_Height));
        Delay (1);
    }
    long accum lk = 262144.0lk;

    PrintBold ("%k %k", (accum) lk, (accum) LongFixedSqrt (lk));
}