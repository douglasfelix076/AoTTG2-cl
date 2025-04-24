# @import Command

class Main
{
    /* PlayerSettings */ Settings = null;

    function OnGameStart()
    {
        self.SetupSettings();
    }

    function SetupSettings()
    {
        self.Settings = PlayerSettings("HexSettings");

        self.Settings.AddSetting("Icon"      , "Levi1"         );
        self.Settings.AddSetting("TeamColor" , "FF0000"        );
        self.Settings.AddSetting("Language"  , UI.GetLanguage());
        self.Settings.AddSetting("Volume"    , 10              );
        self.Settings.AddSetting("Music"     , 7               );
        PersistentData.LoadFromFile("MusicPlayer", false);
    }

    function OnChatInput(message)
    {
        command = Command(message);

        if (command.IsCommand)
        {
            if (command.CommandName == "get")
            {
                key = command.GetString(0);

                value = self.Settings.Load(key);

                Game.Print("config: " + key + " valor: " + value );
            }
            return false;
        }
    }
}

class PlayerSettings
{
    FileName = "";
    Settings = Dict();

    # @param id string
    function Init(fileName)
    {
        if (!PersistentData.IsValidFileName(fileName))
        {
            Game.Print("Invalid setting filename! (" + fileName + ")");
            return;
        }

        self.FileName = fileName;

        PersistentData.Clear();
        if (!self.FileExists())
        {
            self.SaveFile();
        }

        PersistentData.LoadFromFile(self.FileName, false);
    }

    function AddSetting(name, defaultValue)
    {
        value = PersistentData.GetProperty(name, defaultValue);
        PersistentData.SetProperty(name, value);
        self.Settings.Set(name, value);
        self.SaveFile();
    }

    # @param name string
    function Load(name)
    {
        if (self.Settings.Contains(name))
        {
            return self.Settings.Get(name);
        }
        else
        {
            Game.Print("Error: Settings '" + name + "' does not exist!");
        }

        return null;
    }

    # @param name string
    function Save(name, value)
    {
        if (self.FileExists())
        {
            self.Settings.Set(name,defaultValue);
            PersistentData.SetProperty(name, value);
            self.SaveFile();
        }
    }

    function SaveFile()
    {
        if (self.FileNameIsSet())
        {
            PersistentData.SaveToFile(self.FileName, false);
        }
    }

    function FileExists()
    {
        if (self.FileNameIsSet())
        {
            return PersistentData.FileExists(self.FileName);
        }
        return false;
    }

    function FileNameIsSet()
    {
        return self.FileName != "";
    }
}

