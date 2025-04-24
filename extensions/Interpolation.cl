extension Interpolation
{
    function Evaluate(x, ease)
    {
        x = Math.Clamp(x, 0.0, 1.0);

        if (ease == "linear")
        {
            return x;
        }
        elif (ease == "in")
        {
            return x * x * x;
        }
        elif (ease == "out") # cubic easing
        {
            return 1.0 - Math.Pow(1.0 - x, 3.0);
        }
        elif (ease == "inout") # cubic easing
        {
            if (x < 0.5)
            {
                return 4.0 * x * x * x;
            }
            else
            {
                return 1.0 - (Math.Pow(0-2.0 * x + 2.0, 3.0) / 2.0);
            }
        }
        elif (ease == "inouts") # cubic easing
        {
            return 0-(Math.Cos(Math.Rad2Deg(Math.PI * x)) - 1) / 2;
        }

        return x;
    }
}