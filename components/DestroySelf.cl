component DestroySelf
{
    Time = 10.0;
    DestroyChildren = true;
    ActiveOnAwake = true;
    _active = false;

    function Init()
    {
        if (self.ActiveOnAwake)
        {
            self._active = true;
        }
    }

    function OnTick()
    {
        if (self._active)
        {
            self.Time -= Time.TickTime;
            if (self.Time <= 0)
            {
                Map.DestroyMapObject(self.MapObject, self.DestroyChildren);
            }
        }
    }
}