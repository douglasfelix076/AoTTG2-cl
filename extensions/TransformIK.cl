# @import Utility
component TransformIK
{
    TransformPath = "";
    RollOffset = 0.0;
    UpdateMode = "OnTick";

    # Used with animations
    Weight = 1.0;
    UseAnimationPole = false;

    Description = "2 bone Inverse kinematics for custom assets.";
    TransformPathTooltip = "The path to the object's end bone.";
    UpdateModeDropbox = "OnTick,OnFrame,OnLateFrame,Disabled";
    WeightTooltip = "(0.0 - 1.0) Interpolates between the original animation and the target rotation.";
    UseAnimationPoleTooltip = "Will use the original object's position as a pole instead of a custom one.";

    /* @type MapObject    */ transform  = null;
    /* @type MapObject    */ _Target     = null;
    /* @type MapObject    */ _Pole       = null;
    /* @type Transform    */ _TransformA = null; # root
    /* @type Transform    */ _TransformB = null; # knee
    /* @type Transform    */ _TransformC = null; # end bone
    /* @type LineRenderer */ _lr         = null;

    _LocalForwardRotationA = Vector3();
    _LocalForwardRotationB = Vector3();

    _LengthAB = 0.0;
    _LengthBC = 0.0;

    function Init()
    {
        self._Target = Utility.CreateControllerObject();
        self._Pole   = Utility.CreateControllerObject();
    }

    function Setup(obj,path,updateMode,animationPole)
    {
        if (path == "")
        {
            Game.Print("<color=red>error: TransformPath is empty!</color>");
            self.UpdateMode = "None";
            return;
        }
        if (updateMode != "")
        {
            self.UpdateMode = updateMode;
        }

        self.UseAnimationPole = animationPole;

        self.transform = obj.Transform;
        self.TransformPath = path;

        parentPath1 = self.GetParentPath(self.TransformPath);
        parentPath2 = self.GetParentPath(parentPath1);
        self._TransformA = self.transform.GetTransform(parentPath2);
        self._TransformB = self.transform.GetTransform(parentPath1);
        self._TransformC = self.transform.GetTransform(self.TransformPath);
        self._LocalForwardRotationA = Quaternion.Inverse(self._TransformA.QuaternionRotation) * (self._TransformB.Position - self._TransformA.Position).Normalized;
        self._LocalForwardRotationB = Quaternion.Inverse(self._TransformB.QuaternionRotation) * (self._TransformC.Position - self._TransformB.Position).Normalized;

        self.UpdateLengths();

        self._lr = LineRenderer.CreateLineRenderer();
        self._lr.PositionCount = 3;
        self._lr.Enabled = true;
        self._lr.LineColor = Color(0,255,255);

        return self;
    }

    function OnTick()
    {
        if (self.UpdateMode == "OnTick")
        {
            self.Solver();
        }
    }

    function OnFrame()
    {
        if (self.UpdateMode == "OnFrame")
        {
            self.Solver();
        }
    }

    function OnLateFrame()
    {
        if (self.UpdateMode == "OnLateFrame")
        {
            self.Solver();
        }


        # uncomment for bone visualization

        d = 0.5;
        self._lr.SetPosition(0, self._TransformA.Position + (Camera.Position - self._TransformA.Position) * d);
        self._lr.SetPosition(1, self._TransformB.Position + (Camera.Position - self._TransformB.Position) * d);
        self._lr.SetPosition(2, self._TransformC.Position + (Camera.Position - self._TransformC.Position) * d);

        dist1 = Camera.Position - self._TransformA.Position;
        dist2 = Camera.Position - self._TransformC.Position;
        self._lr.StartWidth = dist1.Magnitude / 200;
        self._lr.EndWidth   = dist2.Magnitude / 200;
    }

    function Solver()
    {
        PosA = self._TransformA.Position;
        PosB = self._TransformB.Position;
        PosC = self._TransformC.Position;
        PosP = self._Pole.Position;
        PosT = self._Target.Position;

        if (self.UseAnimationPole)
        {
            PosP = PosB;
        }

        PoleDir = (PosP - PosA).Normalized;

        _LengthAC = (PosA - PosT).Magnitude;
        targetDirection = (PosT - PosA).Normalized;

        finalA = self._TransformA.QuaternionRotation;
        finalB = self._TransformB.QuaternionRotation;
        finalC = self._TransformC.QuaternionRotation;

        if (PosA == PosT)
        {
            # *explodes*
        }
        elif (_LengthAC >= self._LengthAB + self._LengthBC)
        {
            finalA = self.GetRotatedDirection(Quaternion.LookRotation(targetDirection, PoleDir), self._LocalForwardRotationA, self._TransformA.QuaternionRotation);
            finalB = self.GetRotatedDirection(Quaternion.LookRotation(targetDirection, PoleDir), self._LocalForwardRotationB, self._TransformB.QuaternionRotation);
        }
        else
        {
            cosAngleUpper = ((self._LengthBC * self._LengthBC) + (_LengthAC * _LengthAC) - (self._LengthAB * self._LengthAB)) / (2.0 * self._LengthBC * _LengthAC);
            cosAngleLower = ((self._LengthBC * self._LengthBC) - (_LengthAC * _LengthAC) + (self._LengthAB * self._LengthAB)) / (2.0 * self._LengthBC * self._LengthAB);

            cosAngleUpper = Math.Clamp(cosAngleUpper, 0.0 - 1.0, 1.0);
            cosAngleLower = Math.Clamp(cosAngleLower, 0.0 - 1.0, 1.0);

            upperRotation = Quaternion.LookRotation(targetDirection, PoleDir) *
                            Quaternion.Inverse(Quaternion.FromEuler(Vector3(Math.Acos(cosAngleUpper), 0.0, 0.0)));

            lowerRotation = upperRotation *
                            Quaternion.Inverse(Quaternion.FromEuler(Vector3(Math.Acos(cosAngleLower)+180, 0.0, 0.0)));

            finalA = self.GetRotatedDirection(upperRotation, self._LocalForwardRotationA, self._TransformA.QuaternionRotation);
            finalB = self.GetRotatedDirection(lowerRotation, self._LocalForwardRotationB, self._TransformB.QuaternionRotation);
            finalC = self._Target.QuaternionRotation;
        }

        self.Weight = Math.Clamp(self.Weight, 0.0, 1.0);

        self._TransformA.QuaternionRotation = Quaternion.Slerp(self._TransformA.QuaternionRotation, finalA, self.Weight);
        self._TransformB.QuaternionRotation = Quaternion.Slerp(self._TransformB.QuaternionRotation, finalB, self.Weight);
        self._TransformC.QuaternionRotation = Quaternion.Slerp(self._TransformC.QuaternionRotation, finalC, self.Weight);
    }

    # @param targetRotation Quaternion
    # @param currentForward Vector3
    # @param currentRotation Quaternion
    # @return Quaternion
    function GetRotatedDirection(targetRotation, currentForward, currentRotation)
    {
        fromTo = Quaternion.FromToRotation(currentRotation * currentForward, targetRotation * Vector3.Forward);
        newRotation = fromTo * currentRotation;
        return newRotation;
    }

    function UpdateLengths()
    {
        self._LengthAB = (self._TransformC.Position - self._TransformB.Position).Magnitude;
        self._LengthBC = (self._TransformB.Position - self._TransformA.Position).Magnitude;
    }

    # @param str string
    # @return string
    function GetParentPath(str)
    {
        strs = String.Split(str, "/");
        strs.RemoveAt(strs.Count - 1);
        return String.Join(strs, "/");
    }

    # @param axis Vector3
    # @param angle float
    # @return Quaternion
    function AngleAxis(axis, angle)
    {
        axis = axis.Normalized;
        halfAngleRad = 0.5 * angle * Math.Deg2RadConstant;

        sina = Math.Sin(halfAngleRad);
        cosa = Math.Cos(halfAngleRad);
        axis *= sina;
        return Quaternion(axis.X, axis.Y, axis.Z, cosa);
    }
}