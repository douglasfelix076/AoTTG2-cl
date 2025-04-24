class ObjectPooling
{
    _originalData = null;
    _pool = List();
    _activate = true;

    function Init(objectData, activateOnGet)
    {
        self._originalData = objectData;
        self._activate = activateOnGet;
    }

    function Get()
    {
        for(obj in self._pool)
        {
            if (!obj.Active)
            {
                if (self._activate)
                {
                    obj.Active = true;
                }
                return obj;
            }
        }
        new = Map.CopyMapObject(self._originalData, false);
        self._pool.Add(new);
        if (self._activate)
        {
            new.Active = true;
        }
        return new;
    }

    function Destroy(obj)
    {
        obj.Active = false;
    }
}