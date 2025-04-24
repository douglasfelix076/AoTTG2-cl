extension QuaternionX
{
    # @return Quaternion
    function LookRotationY(forward, up)
    {
        ztoup = Quaternion.LookRotation(up, forward * 0-1);
        ytoz = Quaternion.FromEuler(Vector3(90, 0, 0));
        return ztoup * ytoz;
    }

    # @return Quaternion
    function FromToRotation(start, end)
    {
        # works the same as Quaternion.FromToRotation() but takes quaternions instead of Vector3
        return end * Quaternion.Inverse(start);
    }

    function AngleAxis(angleDegrees, axis)
    {
        angleRadians = angleDegrees * (Math.PI / 180.0);
        halfAngle = angleRadians / 2.0;
        sinHalf = Math.Sin(halfAngle) * Math.Rad2DegConstant;
        cosHalf = Math.Cos(halfAngle) * Math.Rad2DegConstant;

        axis = axis.Normalized;

        return Quaternion(axis.x * sinHalf, axis.y * sinHalf, axis.z * sinHalf, cosHalf);
    }

}