
extension MusicPlayer
{
    IsPlaying    = false;
    Enabled     = false;
    CurrentMusic = "";
    FileName     = "MusicPlayer";

    /* @type MapObject */
    _player     = null;

    #singletons when thyme
    function Init()
    {
        self.Load();

        asset = Main.MusicAsset;
        if (asset != "")
        {
            self._player = Map.CreateMapObjectRaw("Scene," + asset + ",32,0,1,1,1,0,music_boss,0,100,50,0,0,0,1,1,1,None,Entities,Default,DefaultNoTint|255/255/255/255,");
        }
    }

    # @param name string
    function Play(name)
    {
        if (self._player == null) { return; }

        self.Stop();

        if (name == "") { return; }

        self.IsPlaying = true;
        self.CurrentMusic = name;

        if (self.Enabled)
        {
            self._player.Transform.GetTransform(name).PlaySound();
        }

        if (Network.IsMasterClient)
        {
            Network.SendMessageOthers("PlayMusic|" + name);
        }
    }

    function Stop()
    {
        if (self._player == null) { return; }

        for (child in self._player.Transform.GetTransforms())
        {
            child.StopSound();
        }
        self.IsPlaying = false;
    }

    function Toggle()
    {
        self.Enabled = !self.Enabled;

        if (self.Enabled)
        {
            self.Play(self.CurrentMusic);
        }
        else
        {
            self.Stop();
        }

        PersistentData.SetProperty("Enabled", self.Enabled);
        PersistentData.SaveToFile(self.FileName, false);
    }

    function Load()
    {
        if (!PersistentData.FileExists(self.FileName))
        {
            PersistentData.SaveToFile(self.FileName, false);
        }

        PersistentData.LoadFromFile(self.FileName, false);
        self.Enabled = PersistentData.GetProperty("Enabled", true);

    }
}