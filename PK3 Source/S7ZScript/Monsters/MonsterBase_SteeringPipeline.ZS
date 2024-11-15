/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 1993-1996 id Software
 *  Copyright (C) 1994-1996 Raven Software
 *  Copyright (C) 1998-1998 Chi Hoang, Lee Killough, Jim Flynn, Rand Phares, Ty Halderman
 *  Copyright (C) 1999-2016 Randy Heit
 *  Copyright (C) 2002-2016 Christoph Oelckers
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

class S7_MonsterSteering_Behaviour play abstract {
    virtual bool IsActive (S7_MonsterBase monster) { return true; }
    abstract Vector3, double Steer (S7_MonsterBase monster);
    abstract double GetWeight (S7_MonsterBase monster);
}

class S7_MonsterSteering_SeekBehaviour : S7_MonsterSteering_Behaviour {
    private double lookaheadFactor;

    static S7_MonsterSteering_SeekBehaviour Create () { return new ('S7_MonsterSteering_SeekBehaviour'); }

    S7_MonsterSteering_SeekBehaviour WithLookahead (double newLookahead) {
        lookaheadFactor = newLookahead;
        return self;
    }

    override double GetWeight (S7_MonsterBase monster) { return 1; }

    override Vector3, double Steer (S7_MonsterBase monster) {
        if (monster.MoveStandStillCount > 0)
            return StandStill (monster), 0;

        monster.targetSystem.NextNode.Invalidate ();
        S7_MonsterTargetInfo targetInfo;
        monster.targetSystem.GetMovementGoal (targetInfo);

        switch (monster.AIState) {
            case S7_MonsterBase.AIS_Wander:
                /*if (!targetInfo.IsValid)
                    return HandleWander (monster), 0;*/
            case S7_MonsterBase.AIS_Chase:
                return HandleChase (monster, targetInfo), 0;

            case S7_MonsterBase.AIS_MissileAttack:
                return StandStill (monster), 0;
        }

        return (0, 0, 0), 0;
    }

    Vector3 StandStill (S7_MonsterBase monster) {
        if (monster.S7_CanFly ()) {
            let velLenSqr = monster.Vel dot monster.Vel;
            if (velLenSqr >= double.Equal_Epsilon)
                return monster.Vel / velLenSqr * monster.MaxAccel / Thinker.TicRate;
        } else if (monster.Pos.Z ~== monster.FloorZ || monster.Pos.Z < monster.FloorZ) {
            let velLenSqr = monster.Vel.XY dot monster.Vel.XY;
            if (velLenSqr >= double.Equal_Epsilon)
                return (monster.Vel.XY / velLenSqr * monster.MaxAccel / Thinker.TicRate, 0);
        }

        return (0, 0, 0);
    }

    Vector3 HandleChase (S7_MonsterBase monster, S7_MonsterTargetInfo targetInfo) {
        if ((!targetInfo.IsValid && monster.AIState != S7_MonsterBase.AIS_Wander) || monster.MoveStandStillCount > 0)
            return StandStill (monster);

        if (monster.bInChase && monster.MoveCount < 0)
            monster.S7_SetMoveCount ();

        if (!targetInfo.IsValid)
            return (0, 0, 0);

        let level = monster.Level;
        let canFly = monster.S7_CanFly ();
        let maxSpeed = monster.Speed / Thinker.TicRate;
        let maxAccel = monster.MaxAccel / Thinker.TicRate;
        targetInfo.Velocity = (0, 0, 0);

        Vector3 goalDir;
        double goalDist;
        if (canFly) {
            let goalPos = level.Vec3Offset (targetInfo.Position, targetInfo.Velocity * lookaheadFactor);
            let goalDiff = level.Vec3Diff (monster.Pos, goalPos);

            goalDist = goalDiff.Length ();
            goalDir = goalDiff / goalDist;
        } else {
            let goalPos = level.Vec2Offset (targetInfo.Position.XY, targetInfo.Velocity.XY * lookaheadFactor);
            let goalDiff = level.Vec2Diff (monster.Pos.XY, goalPos);

            goalDist = goalDiff.Length ();
            goalDir = (goalDiff / goalDist, 0);
        }

        if (goalDist < double.Equal_Epsilon)
            goalDir = (0, 0, 0);

        let targetRadius = max (targetInfo.Radius * 2 + monster.Radius, 1);
        let slowRadius = targetRadius * 2 - targetRadius;
        if (goalDist <= targetRadius)
            return (0, 0, 0);

        let targetSpeed = (goalDist > slowRadius) ? maxSpeed : (maxSpeed * (goalDist - targetRadius) / slowRadius);
        let targetVel = goalDir * targetSpeed;

        if (canFly)
            return S7_Math.ClampVec3Length (targetVel - monster.Vel, maxAccel);

        return (S7_Math.ClampVec2Length (targetVel.XY - monster.Vel.XY, maxAccel), 0);
    }
}

class S7_MonsterSteering_Pipeline play {
    const ConstraintSteps = 5;

    private S7_MonsterBase monster;

    private int lastSteerTic;
    private int updateTime;

    private Array<S7_MonsterSteering_Behaviour> behaviours;

    static S7_MonsterSteering_Pipeline Create (S7_MonsterBase monster) {
        let ret = new ('S7_MonsterSteering_Pipeline');
        ret.monster = monster;
        return ret;
    }

    S7_MonsterSteering_Pipeline AddBehaviour (S7_MonsterSteering_Behaviour behaviour) {
        behaviours.Push (behaviour);
        return self;
    }

    Vector3, double GetSteering () {
        let level = monster.Level;
        if (lastSteerTic >= level.TotalTime)
            return (0, 0, 0), 0;

        lastSteerTic = level.TotalTime;

        let maxSpeed = monster.Speed / Thinker.TicRate;
        let maxAccel = monster.MaxAccel / Thinker.TicRate;
        let maxTurnSpeed = monster.MaxTurnSpeed / Thinker.TicRate;
        let maxTurnAccel = monster.MaxTurnAccel / Thinker.TicRate;

        let accumLinear = (0, 0, 0);
        let accumAngular = 0;
        let calcLinear = true;
        let calcAngular = true;
        for (let i = 0; i < behaviours.Size (); i++) {
            let behaviour = behaviours [i];
            if (!behaviour.IsActive (monster))
                continue;

            let [linearForce, angularForce] = behaviour.Steer (monster);
            let weight = behaviour.GetWeight (monster);
            linearForce *= weight;
            angularForce *= weight;

            if (calcLinear) {
                let len = accumLinear.Length ();
                let remainingLen = max (maxAccel - len, 0);

                if (remainingLen > double.Equal_Epsilon)
                    accumLinear += S7_Math.ClampVec3Length (linearForce, remainingLen);

                if (remainingLen <= double.Equal_Epsilon)
                    calcLinear = false;
            }

            if (calcAngular) {
                let len = abs (accumAngular);
                let remainingLen = max (maxTurnAccel - len, 0);

                if (remainingLen > double.Equal_Epsilon)
                    accumAngular += clamp (angularForce, -remainingLen, remainingLen);

                if (remainingLen <= double.Equal_Epsilon)
                    calcAngular = false;
            }

            if (!calcLinear && !calcAngular)
                break;
        }

        return accumLinear, accumAngular;

        /*targetVel = S7_Math.ClampVec3Length (targetVel, maxSpeed);
        if (!canFly)
            linearAccel = (S7_Math.ClampVec2Length (targetVel.XY - monster.Vel.XY, maxAccel), 0);
        else
            linearAccel = S7_Math.ClampVec3Length (targetVel - monster.Vel, maxAccel);
        angularAccel = clamp (angularVel - monster.AngularVelocity, -maxTurnAccel, maxTurnAccel);*/
    }
}