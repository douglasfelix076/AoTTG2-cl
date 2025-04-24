class Command
{
    IsCommand   = false;
    CommandName = "";
    Args        = List();
    ArgCount    = 0;

    # @param message string
    function Init(message)
    {
        if (String.StartsWith(message, "/") && String.Length(message) > 1)
        {
            self.Args        = String.Split(String.Substring(message, 1), " ", true);
            self.CommandName = self.Args.Get(0);
            self.IsCommand   = true;

            self.Args.RemoveAt(0);
            self.ArgCount = self.Args.Count;
        }
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