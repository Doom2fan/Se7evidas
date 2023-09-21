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

struct S7_MonsterTargetInfo {
    bool IsValid;
    Actor TargetActor;

    Vector3 Position;
    Vector3 Velocity;

    double Radius;
    double Height;

    double Angle;
    double Pitch;

    void Invalidate () {
        IsValid = false;
        TargetActor = null;

        Position = Velocity = (double.NaN, double.NaN, double.NaN);

        Radius = Height = double.NaN;

        Angle = Pitch = double.NaN;
    }

    void Copy (out S7_MonsterTargetInfo other) {
        IsValid = other.IsValid;
        TargetActor = other.TargetActor;

        Position = other.Position;
        Velocity = other.Velocity;

        Radius = other.Radius;
        Height = other.Height;

        Angle = other.Angle;
        Pitch = other.Pitch;
    }

    void FromActor (Actor targetAct) {
        if (!targetAct) {
            Invalidate ();
            return;
        }

        IsValid = true;
        TargetActor = targetAct;

        Position = targetAct.Pos;
        Velocity = targetAct.Vel;

        Radius = targetAct.Radius;
        Height = targetAct.Height;

        Angle = targetAct.Angle;
        Pitch = targetAct.Pitch;
    }

    void FromPosVel (Vector3 pos, Vector3 vel, double newRadius = 0, double newHeight = 0, double newAngle = 0, double newPitch = 0) {
        IsValid = true;
        TargetActor = null;

        Position = pos;
        Velocity = vel;

        Radius = newRadius;
        Height = newHeight;

        Angle = newAngle;
        Pitch = newPitch;
    }
}

class S7_MonsterBase_TargettingSystem play {
    S7_MonsterBase Monster;
    Actor TargetMarker;

    void Initialize () {
        Countdown = -1;
    }

    //-------------------------------------------------------------------------------------------
    //
    // Movement target retrieval
    //
    //-------------------------------------------------------------------------------------------
    void GetMovementGoal (out S7_MonsterTargetInfo targetInfo) {
        if (Monster.Goal)
            targetInfo.FromActor (Monster.goal);
        else if (NextNode.IsValid)
            targetInfo.Copy (NextNode);
        else if (Monster.Target)
            targetInfo.FromActor (Monster.Target);
    }

    void Tick () {
        SearchBehavior ();

        if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching && NextNode.IsValid) {
            if (!TargetMarker)
                TargetMarker = Actor.Spawn ("S7_LastKnownPositionMarker", NextNode.Position);
            else
                TargetMarker.SetOrigin (NextNode.Position, false);

        } else if (TargetMarker)
            TargetMarker.Destroy ();
    }
}