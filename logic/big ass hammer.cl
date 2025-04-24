class Main
{
    TitanSpeed = 1.0;
    TitanSpawnSpeed = 1.0;
    MaxTitans = 70;
    TitanBlowawayForce = 200.0;
    _spawnTimer = 0.0;
    _hammerL = null;
    _hammerR = null;
    
    function Init()
    {
        self._hammerL = Map.FindMapObjectByName("HammerOriginL");
        self._hammerR = Map.FindMapObjectByName("HammerOriginR");
        Camera.FollowDistance = 6;
        self.Wait();
    }

    function OnCharacterSpawn(character)
    {
        if (character.Type == "Human")
        {
            character.Speed = 4;
            character.MaxGas = 99999;
            character.CurrentGas = 99999;
            character.MaxBladeDurability = 99999;
            character.CurrentBladeDurability = 99999;
        }
    }
    
    function OnNetworkMessage(sender, message)
    {
        viewID = Convert.ToInt(message);
        titan = Game.FindCharacterByViewID(viewID);
        if (titan != null)
        {
            self.CreateRagdoll(sender.Character.Position, titan, Network.MyPlayer.Name);
        }
    }

    coroutine Wait()
    {
        wait 1.0 / self.TitanSpawnSpeed;

        if (Game.Titans.Count < self.MaxTitans)
        {
            pos = Random.RandomDirection();
            pos.Y = 0;
            pos = pos.Normalized * Random.RandomFloat(100, 200);
            titan = Game.SpawnTitanAt("Default", pos);
            titan.FocusRange = 1000;
            titan.DetectRange = 1000;
            titan.RunSpeedBase = titan.RunSpeedBase * self.TitanSpeed; 
        }

        self.Wait();
    }
    
    function OnTick()
    {
        self._spawnTimer -= Time.TickTime;

    }

    function OnCharacterSpawn(character)
    {
        if (character.Type == "Human")
        {
            hammerL = Map.CopyMapObject(self._hammerL, true);
            hammerR = Map.CopyMapObject(self._hammerR, true);
            hammerL.Active = true;
            hammerR.Active = true;
            hammerL.GetComponent("Hammer").Setup(character);
            hammerR.GetComponent("Hammer").Setup(character);
        }
    }

    function CreateRagdoll(hammer, titan, name)
    {
        pos = titan.Position.X + ", " + (titan.Position.Y + titan.Size * 10) + ", " + titan.Position.Z;
        rot = titan.Rotation.X + ", " + titan.Rotation.Y + ", " + titan.Rotation.Z;
        
        r = Map.CreateMapObjectRaw("Scene,Geometry/Capsule,15,0,1,1,0,0,Capsule,"+pos+","+rot+",0.9,0.9,0.9,Physical,MapObjects,Default,Default|255/0/255/255,RagdollTitan|,Rigidbody|Mass:2|Gravity:0/-20/0|FreezeRotation:false|Interpolate:false");
        r.GetComponent("RagdollTitan").Setup(titan);
        
        rb = r.GetComponent("Rigidbody");
        force = ((r.Position - hammer).Normalized) * self.TitanBlowawayForce;
        torque = Random.RandomVector3(Vector3(0.1,0.1,0.1) * (0-self.TitanBlowawayForce), Vector3(0.1,0.1,0.1) * self.TitanBlowawayForce);
        rb.AddForceWithMode(force, "VelocityChange");
        rb.AddTorque(torque, "VelocityChange");
        
        titan.GetKilled(name);
        titan.PlayAnimation("Idle");
    }
}

component RagdollTitan
{
    titan = null;
    
    function Setup(titan)
    {
        self.titan = titan;
    }

    function OnFrame()
    {
        if (self.titan != null)
        {
            self.titan.Position = self.MapObject.Position - self.MapObject.Up * self.titan.Size * 10;
            self.titan.QuaternionRotation = self.MapObject.QuaternionRotation;
        }
        else
        {
            Map.DestroyMapObject(self.MapObject, true);
        }
    }

}

component Hammer
{
    LeftHanded = false;

    _human = null;
    _collider = null;

    function HandleCollision(other)
    {
        if (self._human.IsMine && ((self._human.State == "Attack" && !Input.GetKeyHold("Human/AttackDefault")) || (self._human.State == "SpecialAttack" && !Input.GetKeyHold("Human/AttackSpecial"))))
        {
            Game.SpawnEffect("Boom1", self._collider.MapObject.Position, Vector3.Zero, 2);
            if (Network.IsMasterClient)
            {
                Main.CreateRagdoll(self.MapObject.Position, other, Network.MyPlayer.Name);
            }
            else
            {
                Network.SendMessage(Network.MasterClient, Convert.ToString(other.ViewID));
            }
        }
    }

    function Setup(human)
    {
        # waits a frame since components are loaded a frame after the object is copied
        wait 0.0;

        self._collider = self.MapObject.GetChild("collider").GetComponent("HammerCollision");
        self._collider.SetHandler(self);

        transform = null;

        if (self.LeftHanded)
        {
            transform = human.Transform.GetTransform("Armature/Core/Controller_Body/hip/spine/chest/shoulder_L/upper_arm_L/forearm_L/hand_L");
            self.MapObject.Parent = transform;
            self.MapObject.LocalRotation = Vector3(0,0,90);
        }
        else
        {
            transform = human.Transform.GetTransform("Armature/Core/Controller_Body/hip/spine/chest/shoulder_R/upper_arm_R/forearm_R/hand_R");
            self.MapObject.Parent = transform;
            self.MapObject.LocalRotation = Vector3(0,0,-90);
        }

        self.MapObject.LocalPosition = Vector3.Zero;
        self._human = human;
    }
}

component HammerCollision
{
    _handler = null;

    function SetHandler(handler)
    {
        self._handler = handler;
    }
    
    function OnCollisionEnter(other)
    {
        if (self._handler != null && other.Type == "Titan" && other.Health > 0)
        {
            self._handler.HandleCollision(other);
        }
    }
}
