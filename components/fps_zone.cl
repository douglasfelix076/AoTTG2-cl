component FPSZone
{
    function OnCollisionStay(obj)
    {
        if (Network.MyPlayer.Character != null && obj == Network.MyPlayer.Character)
        {
            Camera.SetCameraMode("FPS");
        }
    }

    function OnCollisionExit(obj)
    {
        if (Network.MyPlayer.Character != null && obj == Network.MyPlayer.Character)
        {
            Camera.ResetCameraMode();
        }
    }
}