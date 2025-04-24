class NetworkRPC
{
    Call       = "";
    Message    = "";
    Args       = List();
    JoinedArgs = "";

    # @param message string
    function Init(message)
    {
        split = String.Split(message, "|");
        if (split.Count == 0)
        {
            return;
        }
        call = split.Get(0);
        args = List();
        if (split.Count > 1)
        {
            args = String.Split(split.Get(1), ";");
        }

        self.Call = call;
        self.Args = args;

        split.RemoveAt(0);

        self.JoinedArgs = String.Join(split, "|");
    }

    function Print()
    {
        Game.Print("<color=white>RPC:</color> <color=green>" + self.Message + "</color>");
    }

    # @param id int
    # @return string
    function GetString(id)
    {
        return self.Args.Get(id);
    }

    # @param id int
    # @return float
    function GetFloat(id)
    {
        return Convert.ToFloat(self.Args.Get(id));
    }

    # @param id int
    # @return int
    function GetInt(id)
    {
        return Convert.ToInt(self.Args.Get(id));
    }

    # @param id int
    # @return bool
    function GetBool(id)
    {
        return Convert.ToBool(self.Args.Get(id));
    }

    # @param id int
    # @return Vector3
    function GetVector3(id)
    {
        vectorString = self.Args.Get(id);
        values = String.Split(String.SubstringWithLength(vectorString, 1, String.Length(vectorString) - 2), ",");
        return Vector3(Convert.ToFloat(values.Get(0)),Convert.ToFloat(values.Get(1)),Convert.ToFloat(values.Get(2)));
    }

    # @param id int
    # @return Quaternion
    function GetQuaternion(id)
    {
        quatString = self.Args.Get(id);
        values = String.Split(String.SubstringWithLength(quatString, 1, String.Length(quatString) - 2), ",");
        return Vector3(Convert.ToFloat(values.Get(0)),Convert.ToFloat(values.Get(1)),Convert.ToFloat(values.Get(2),Convert.ToFloat(values.Get(3))));
    }
}