component PushRegion
{
    _count = 0;
    _active_me = true;
    Up = 1.0;
    MinForce = 5.0;

    function OnTick()
    {
        if (self._count > 1)
        {
            self._active_me = false;
        }
        else
        {
            self._count += 1;
        }
    }

    function OnCollisionStay(other)
    {
        if (self._active_me)
        {
            if (other.Type == "Human")
            {
                vector = other.Position - self.MapObject.Position;
                num2 = self.MapObject.Scale.X / 2.0;
                num3 = Math.Max(5.0, num2 - vector.Magnitude);
                other.AddForce(vector.Normalized * num3 + Vector3.Up * self.Up, "Impulse");
            }
        }
    }
}