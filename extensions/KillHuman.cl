component KillHuman
{
    _count = 0;
    _active_me = true;
    Name = "Server";

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
            if (other.Type == "Human" && other.IsMine && !other.IsInvincible)
            {
                other.GetKilled(self.Name);
            }
        }
    }
}