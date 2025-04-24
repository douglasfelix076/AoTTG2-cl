extension CineMessage
{
    # @param label string
    # @param text string
    # @param delay float
    # @param stayTime float
    coroutine TypeWrite(label, text, delay, stayTime)
    {
        for (i in Range(0, String.Length(text), 1))
        {
            UI.SetLabel(label, String.SubstringWithLength(text, 0, i+1));
            wait delay;
        }

        wait stayTime;

        for (i in Range(String.Length(text), 0, -1))
        {
            UI.SetLabel(label, String.SubstringWithLength(text, 0, i));
            wait delay;
        }

        UI.SetLabel(label, "");
    }

    # @param label string
    # @param text string
    # @param color string
    # @param delay float
    # @param stayTime float
    coroutine TypeWriteWithColor(label, text, color, delay, stayTime)
    {
        for (i in Range(0, String.Length(text), 1))
        {
            UI.SetLabel(label, UI.WrapStyleTag(String.SubstringWithLength(text, 0, i+1), "color", color));
            wait delay;
        }

        wait stayTime;

        for (i in Range(String.Length(text), 0, -1))
        {
            UI.SetLabel(label, UI.WrapStyleTag(String.SubstringWithLength(text, 0, i), "color", color));
            wait delay;
        }

        UI.SetLabel(label, "");
    }
}