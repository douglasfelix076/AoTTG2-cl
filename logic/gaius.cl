# @import gaiusenums charactercontainer parent quaternionx key effects PushRegion DestroySelf KillHuman TransformIK Utility MusicPlayer Command NetworkRPC ObjectPooling
# commence epic spaghetti code

component Gaius
{
    _animationLength = 1.0;
    _animationStart = 0.0;
    _currentAnimation = "";
    _addonAnimation = "";
    _rootAnimations = List();
    _state = GaiusState.NONE;
    _normalizedTime = 0.0;
    _targetUpdateHeadRotation = Quaternion();
    _armorObjects = List();
    _waitTime = 0.0;
    _turnSpeed = 0.35;
    _life = 100.0;
    _stateStage = 0;
    _hasArmor = true;
    _StateTime = 0.0;
    _RootPreviousPosition = Vector3();
    _RootPreviousRotation = Quaternion();
    _needResetRoot = false;
    _StepUpdate = false;
    _RaiseUpdateL = false;
    _RaiseUpdateR = false;
    /* @type Transform */ _transform  = null;
    /* @type Transform */ _root       = null;
    /* @type Transform */ _rootAdd    = null;
    /* @type Transform */ _waist      = null;
    /* @type Transform */ _direction  = null;
    /* @type Transform */ _footR      = null;
    /* @type Transform */ _footL      = null;
    /* @type Transform */ _head       = null;
    /* @type Transform */ _neck       = null;
    /* @type Transform */ _armR       = null;
    /* @type Transform */ _swordPoint = null;
    /* @type Transform */ _swordJudge = null;
    /* @type Character */ _target     = null;

    /* @type GaiusIKManager */ IKManager = null;

    function Init()
    {
        self.SetupTransforms();
        self.SetupArmor();
        self.SetupRootAnimations();
        self.IKManager = GaiusIKManager(self.MapObject);

        o = Utility.CreateControllerObject();
        o.Parent = self.MapObject;
        o.LocalPosition = Vector3();
    }

    function OnGameStart()
    {
        if (self.NetworkView.Owner == Network.MyPlayer)
        {
            self.Idle();
        }

        MusicPlayer.Play(Music.IN_AWE_OF_POWER);
    }

    function OnTick()
    {
        if (self.NetworkView.Owner == Network.MyPlayer)
        {
            if (self._state == GaiusState.WALK)
            {
                # distance = self.GetTargetHorizontalDistance();
                angle = self.GetAngleFromTarget();
                 self._transform.RotateAround(self._root.Position, Vector3.Up, angle * Time.TickTime * self._turnSpeed);

            }
        }
        self.DoLegStepEffects();
    }

    function OnFrame()
    {
        self.UpdateAnimationNormalizedTime();

        if (self.AnimationEnded(self._currentAnimation) && self._rootAnimations.Contains(self._currentAnimation))
        {
            self.ResetRoot();
        }

        if (self.NetworkView.Owner == Network.MyPlayer)
        {
            if (self._state == GaiusState.IDLE)
            {
                self.UpdateIdle();
            }
            elif (self._state == GaiusState.WALK)
            {
                self.UpdateWalk();
            }
            elif (self._state == GaiusState.ATTACK)
            {
                self.UpdateAttack();
            }
            elif (self._state == GaiusState.FAIL)
            {
                self.UpdateFail();
            }
        }
        if (self._StateTime > 0.0)
        {
            return;
        }
    }

    function OnLateFrame()
    {
        if (self._needResetRoot)
        {
            #Game.Print("old....: "  + self._RootPreviousPosition);
            #Game.Print("current: "  + self._root.Position);
            #self._transform.QuaternionRotation = self._root.QuaternionRotation * self._RootPreviousRotation;
            self._transform.Position = self._RootPreviousPosition + (self._transform.Position - self._root.Position);
            self._needResetRoot = false;
        }
        if (self.NetworkView.Owner == Network.MyPlayer)
        {
            castResult = self.GetGroundCast(self.MapObject.Position);
            self._transform.Position           = Vector3(self._transform.Position.X, Math.Lerp(self._transform.Position.Y, castResult.Point.Y, Time.FrameTime), self._transform.Position.Z);
            self._transform.QuaternionRotation = QuaternionX.LookRotationY(self._transform.Forward, Vector3.Up);
        }
        self.UpdateHeadRotation();
        self.UpdateLegIK();

    }

    function UpdateIdle()
    {

    }

    function UpdateWalk()
    {
        if (self.AnimationEnded(GaiusAnimations.WALK))
        {
            self.PlayAnimation(GaiusAnimations.STANDBY, 0.0);
            self.PlayAnimation(GaiusAnimations.WALK, 0.0);
        }

        distance = self.GetTargetHorizontalDistance();

        if (distance < 20)
        {
            #self.StateAnimate(GaiusState.IDLE, GaiusAnimations.WALK_END, 1.0);
        }
    }

    function UpdateAttack()
    {
        if (self.AnimationEnded(GaiusAnimations.ATTACK_SLAM_START))
        {
            castResult = self.GetGroundCastWithTag(self._swordJudge.Position, "Solid");
                Game.Print(castResult.ToString());
            if (castResult.Hit)
            {
                self.RemoveArmor();
                self.CreateAttackBoom(castResult.Point, castResult.Normal, Effects.Boom2, 3.5);
                self.StateAnimate(GaiusState.FAIL, GaiusAnimations.ATTACK_SLAM_FAIL2, 0.4);
            }
            else
            {
                self.CreateAttackBoom(castResult.Point, castResult.Normal, Effects.Boom6, 3.5);
                self.PlayAnimation(GaiusAnimations.ATTACK_SLAM_2, 0.4);
            }

        }
        elif (self.AnimationEnded(GaiusAnimations.ATTACK_SLAM_2))
        {
            self.PlayAnimation(GaiusAnimations.ATTACK_SLAM_3, 0.4);

            hand = self._transform.GetTransform(GaiusBodyPart.HAND_R);
            self.Fix(GaiusBodyPart.HAND_R, hand.Position, hand.Rotation, 0.0);
        }
        elif (self.AnimationEnded(GaiusAnimations.ATTACK_SLAM_3))
        {
            self.PlayAnimation(GaiusAnimations.ATTACK_SLAM_END, 0.4);
            self.Unfix(GaiusBodyPart.HAND_R, 1.0);
        }
        elif (self.AnimationEnded(GaiusAnimations.ATTACK_STAB_START))
        {
            self.PlayAnimation(GaiusAnimations.ATTACK_STAB_LOOP, 0.1);
        }
        elif (self._currentAnimation == GaiusAnimations.ATTACK_STAB_LOOP)
        {
            hand = self._transform.GetTransform(GaiusBodyPart.HAND_R);
            if (self._stateStage == 0  && self._normalizedTime >= 0.03)
            {
                castResult = self.GetGroundCast(self._swordPoint.Position);
                Game.Print(castResult.ToString());
                self.CreateAttackBoom(castResult.Point, castResult.Normal, Effects.Boom6, 2.3);
                self._stateStage = 1;
            }
            elif (self._stateStage == 1  && self._normalizedTime >= 0.1)
            {
                self.Fix(GaiusBodyPart.HAND_R, hand.Position, hand.Rotation, 0.2);
                self._stateStage = 2;
            }
            elif (self._stateStage == 2  && self._normalizedTime >= 0.85)
            {
                self.Unfix(GaiusBodyPart.HAND_R, 1.0);
                self._stateStage = 3;
            }
            elif (self._stateStage == 3  && self._normalizedTime >= 1.0)
            {
                castResult = self.GetGroundCast(self._swordPoint.Position);
                Game.SpawnEffect(Effects.GroundShatter, castResult.Point - castResult.Normal * 0.01, Vector3(0,0,0), 2.5);
                self.PlayAnimation(GaiusAnimations.ATTACK_STAB_END, 0.1);
                self._stateStage = 4;
            }
        }
        elif (self._currentAnimation == GaiusAnimations.ATTACK_SLAM_END || self._currentAnimation == GaiusAnimations.ATTACK_STAB_END)
        {
            if (self._normalizedTime >= 1.0)
            {
                self.Idle();
            }
        }
        elif (self._currentAnimation == GaiusAnimations.ATTACK_STOMP_L_START || self._currentAnimation == GaiusAnimations.ATTACK_STOMP_R_START)
        {
            if (self._normalizedTime >= 1.0)
            {
                castResult = self.GetGroundCast(self._transform.GetTransform(GaiusBodyPart.ATTACK_POINT).Position);
                if (castResult.Tag == "Solid")
                {
                    animation = GaiusAnimations.ATTACK_STOMP_R_FAIL;
                    if (self._currentAnimation == GaiusAnimations.ATTACK_STOMP_L_START)
                    {
                        animation = GaiusAnimations.ATTACK_STOMP_L_FAIL;
                    }
                    self.StateAnimate(GaiusState.FAIL, animation, 0.4);
                }
                else
                {
                    animation = GaiusAnimations.ATTACK_STOMP_R;
                    if (self._currentAnimation == GaiusAnimations.ATTACK_STOMP_L_START)
                    {
                        animation = GaiusAnimations.ATTACK_STOMP_L;
                    }
                    self.PlayAnimation(animation, 0.4);
                }
            }
        }
        elif (self._currentAnimation == GaiusAnimations.ATTACK_STOMP_L || self._currentAnimation == GaiusAnimations.ATTACK_STOMP_R)
        {
            if (self._stateStage == 0 && self._normalizedTime >= 0.11)
            {
                castResult = self.GetGroundCast(self._transform.GetTransform(GaiusBodyPart.ATTACK_POINT).Position);
                self.CreateAttackBoom(castResult.Point, castResult.Normal, Effects.Boom2, 2.0);
                self._stateStage = 1;
            }
            elif (self._stateStage == 1 && self._normalizedTime >= 1.0)
            {
                self.Idle();
            }
        }
    }

    function UpdateFail()
    {
        if (self._currentAnimation == GaiusAnimations.ATTACK_STOMP_L_FAIL || self._currentAnimation == GaiusAnimations.ATTACK_STOMP_R_FAIL)
        {
            if (self._stateStage == 0 && self._normalizedTime >= 0.06)
            {
                castResult = self.GetGroundCast(self._transform.GetTransform(GaiusBodyPart.ATTACK_POINT).Position);
                self.CreateAttackBoom(castResult.Point, castResult.Normal, Effects.Boom1, 1.5);
                self._stateStage = 1;
            }
            elif (self._stateStage == 1 && self._normalizedTime >= 1.0)
            {
                self.Idle();
            }
        }
        if (self._normalizedTime >= 1.0)
        {
            self.Idle();
        }
    }

    function FindTarget()
    {
        for (human in Game.Humans)
        {
            self.SetTarget(human);
        }
    }

    # @param character Character
    function SetTarget(character)
    {
        self._target = character;
        self.NetworkView.SendMessageOthers("SetTarget|" + character.ViewID);
    }

    function AnimationEnded(anim)
    {
        return self._currentAnimation == anim && self._normalizedTime >= 1.0;
    }

    # @return float
    function GetAngleFromTarget()
    {
        if (self._target != null)
        {
            FromToPos = self._target.Position - self._transform.Position;
            FromToPos.Y = 0;

            return Vector3.SignedAngle(self._transform.Forward, FromToPos, Vector3.Up);
        }

        return 0.0;
    }

    # @return float
    function GetTargetHorizontalDistance()
    {
        FromToPos = self._root.Position - self._target.Position;
        FromToPos.Y = 0;
        return FromToPos.Magnitude;
    }

    function Fix(name, point, rotation, fade)
    {
        self.IKManager.Fix(name, point, rotation, fade);
        self.NetworkView.SendMessageOthers("IK_Fix|" + name + ";" + point + ";" + rotation + ";" + fade);
    }

    function Unfix(name, fade)
    {
        self.IKManager.Unfix(name, fade);
        self.NetworkView.SendMessageOthers("IK_Unfix|" + name + ";" + fade);
    }

    function UpdateLegIK()
    {
        self.SetLegHeight(self.IKManager._IK_LegR);
        self.SetLegHeight(self.IKManager._IK_LegL);
    }

    # @param ikSolver TransformIK
    function SetLegHeight(ikSolver)
    {
        foot = ikSolver._TransformC.Position;
        resultCast = self.GetGroundCast(foot);

        posY = self.MapObject.Position.Y;
        centerY = posY + ikSolver._LengthAB + ikSolver._LengthBC;
        castY = resultCast.Point.Y;
        final = Math.Lerp(castY, centerY, (foot.Y-posY)/(centerY-posY));
        ikSolver._Target.Position = Vector3(resultCast.Point.X, Math.Lerp(ikSolver._Target.Position.Y, final - 0.1, Time.FrameTime * 6  ), resultCast.Point.Z);
    }

    function DoLegStepEffects()
    {
        stepTime1 = 0.5;
        stepTime2 = 0.0;
        raiseTime1 = 0.1;
        raiseTime2 = 0.6;
        animation = List();

        animation.Add(GaiusAnimations.WALK         );
        animation.Add(GaiusAnimations.WALK_END     );
        animation.Add(GaiusAnimations.WALK_START   );
        animation.Add(GaiusAnimations.ATTACK_STAB_START);
        animation.Add(GaiusAnimations.ATTACK_SLAM_2);
        animation.Add(GaiusAnimations.ATTACK_STOMP_L_FAIL);
        animation.Add(GaiusAnimations.ATTACK_STOMP_R_FAIL);

        if (self._currentAnimation == GaiusAnimations.WALK)
        {
            stepTime1 = 0.4;
            stepTime2 = 0.9;
            raiseTime1 = 0.5;
            raiseTime2 = 0.9;
        }

        if (!animation.Contains(self._currentAnimation))
        {
            return;
        }

        # normalizedTime = self._normalizedTime;
        # if (normalizedTime > 1.0)
        # {
        #     normalizedTime -= 1.0;
        # }

        # point = Vector3();
        # ik = null;


        # /*
        # if (self._StepUpdate)
        # {
        #     if ((normalizedTime > stepTime2))
        #     {
        #         self._StepUpdate = false;
        #         point = self._footR.Position;
        #         ik = self.IKManager._IK_LegR._Target;
        #     }
        # }
        # else
        # {
        #     if ((normalizedTime > stepTime1) && (normalizedTime < stepTime2))
        #     {
        #         self._StepUpdate = true;
        #         point = self._footL.Position;
        #         ik = self.IKManager._IK_LegR._Target;
        #     }
        # }

        # if (normalizedTime > raiseTime1 && self._RaiseUpdate)
        # {
        #     self._RaiseUpdate = false;
        #     self.Fix(GaiusBodyPart.FOOT_R, point, rotation, fade)
        # }

        # if (point != Vector3())
        # {
        #     cast = self.GetGroundCast(point);
        #     #Game.SpawnEffect(Effects.Boom6, cast.Point, Vector3(270,0,0), 1);
        #     mud = Map.CreateMapObjectRaw("Scene,Custom/sotc/mud,35,0,1,0,1,0,mud,0.0,0.0,0.0,0,0,0,0.6,0.6,0.6,Physical,Entities,Default,DefaultNoTint|255/255/255/255,");
        #     mud.Position = cast.Point;
        #     mud.Up = cast.Normal;
        #     mud.Transform.RotateAround(mud.Position, mud.Up, Random.RandomFloat(0.0, 36.0));

        # }
    }


    function UpdateHeadRotation()
    {
        if (self._target != null)
        {
            if (Network.IsMasterClient)
            {
                fromTo = self._target.Position - (self._head.Position + self._head.Up);

                rotation = self._head.QuaternionRotation;
                if (Vector3.Angle(self._head.Forward, fromTo) <= 80)
                {
                    rotation = Quaternion.LookRotation(fromTo, self._head.Up);
                }
                self._targetUpdateHeadRotation = Quaternion.Slerp(self._targetUpdateHeadRotation, rotation, Time.FrameTime * 2);

            }
        }
        self._head.QuaternionRotation = self._targetUpdateHeadRotation;
    }

    function SendNetworkStream()
    {
        self.NetworkView.SendStream(self._targetUpdateHeadRotation.Euler);
        self.IKManager.SendStream(self.NetworkView);
    }

    function OnNetworkStream()
    {
        self._targetUpdateHeadRotation = Quaternion.FromEuler(self.NetworkView.ReceiveStream());
        self.IKManager.ReceiveStream(self.NetworkView);
    }

    function OnNetworkMessage(sender, message)
    {
        rpc = NetworkRPC(message);

        if (rpc.Call == "PlayAnimation")
        {
            aniName = rpc.GetString(0);
            time    = rpc.GetFloat(1);
            addon   = rpc.GetBool(2);

            if (addon)
            {
                self.JustPlayAddonAnimation(aniName, time);
            }
            else
            {
                self.PlayAnimation_Func(aniName, time);
            }
        }
        elif (rpc.Call == "Instantiate")
        {
            Map.CreateMapObjectRaw(rpc.JoinedArgs);
        }
        elif (rpc.Call == "Kill")
        {
            human = Network.MyPlayer.Character;
            if (human != null && human.Type == "Human" && !human.IsInvincible)
            {
                Network.MyPlayer.Character.GetKilled(self._name);
            }
        }
        elif (rpc.Call == "SetTarget")
        {
            viewID = rpc.GetInt(0);
            self._target = Game.FindCharacterByViewID(viewID);
        }
        elif (rpc.Call == "IK_Fix")
        {
            name     = rpc.GetString(0);
            point    = rpc.GetVector3(1);
            rotation = rpc.GetVector3(2);
            fade     = rpc.GetFloat(3);

            self.IKManager.Fix(name, point, rotation, fade);
        }
        elif (rpc.Call == "IK_Unfix")
        {
            name = rpc.GetString(0);
            fade = rpc.GetFloat(1);

            self.IKManager.Unfix(name, fade);
        }
        elif (rpc.Call == "RemoverArmor")
        {
            self.RemoveArmor_Func();
        }
    }

    function StateAnimate(state, animation, crossfade)
    {
        self.PlayAnimation(animation, crossfade);
        self._StateTime = self._animationLength;
        self._state = state;
        self._stateStage = 0;

        self.Unfix(GaiusBodyPart.HAND_L, 0.1);
        self.Unfix(GaiusBodyPart.HAND_R, 0.1);
    }

    coroutine Disable()
    {
        self._state = GaiusState.DOWN;
        self._transform.Position = Vector3.Zero;
        wait 0.0;
        self.PlayAnimation(GaiusAnimations.BOOT, 0.0);
        wait 0.0;
        self.PlayAnimation(GaiusAnimations.BOOT_CANCEL, 0.0);
    }

    coroutine Boot()
    {
        self.StateAnimate(GaiusState.BOOT, GaiusAnimations.BOOT, 0.0);
    }

    function Idle()
    {
        self.ResetAttack();
        self.StateAnimate(GaiusState.IDLE, GaiusAnimations.STAND, 0.6);
    }

    function Walk()
    {
        self.StateAnimate(GaiusState.WALK, GaiusAnimations.WALK, 1.0);
    }

    function DoAttack()
    {
        if (self._target != null)
        {
            self.ResetAttack();
            animation = "";

            distance = self.GetTargetHorizontalDistance();

            if (distance < 40)
            {
                angle = self.GetAngleFromTarget();
                if (angle < 0)
                {
                    animation = GaiusAnimations.ATTACK_STOMP_L_START;
                }
                else
                {
                    animation = GaiusAnimations.ATTACK_STOMP_R_START;
                }
            }
            elif (distance < 80)
            {
                animation = GaiusAnimations.ATTACK_STAB_START;
            }
            else
            {
                animation = GaiusAnimations.ATTACK_SLAM_START;
            }

            self.StateAnimate(GaiusState.ATTACK, animation, 0.0);
        }
        else
        {
            self.StateAnimate(GaiusState.ATTACK, GaiusAnimations.ATTACK_SLAM_START, 0.0);
        }
    }

    function AttackSlam()
    {
        self.StateAnimate(GaiusState.ATTACK, GaiusAnimations.ATTACK_SLAM_START, 0.0);
    }

    function SetupTransforms()
    {
        self._transform  = self.MapObject.Transform;
        self._root       = self._transform.GetTransform(GaiusBodyPart.ROOT);
        self._rootAdd    = self._transform.GetTransform(GaiusBodyPart.ROOTADD);
        self._waist      = self._transform.GetTransform(GaiusBodyPart.WAIST);
        self._direction  = self._transform.GetTransform(GaiusBodyPart.DIRECTION);
        self._footR      = self._transform.GetTransform(GaiusBodyPart.FOOT_R);
        self._footL      = self._transform.GetTransform(GaiusBodyPart.FOOT_L);
        self._head       = self._transform.GetTransform(GaiusBodyPart.HEAD);
        self._swordPoint = self._transform.GetTransform(GaiusBodyPart.SWORD_POINT);
        self._swordJudge = self._transform.GetTransform(GaiusBodyPart.SWORD_JUDGE);
        self._armR       = self._transform.GetTransform(GaiusBodyPart.ARM_R);
        self._neck       = self._transform.GetTransform(GaiusBodyPart.NECK);
    }

    function SetupArmor()
    {
        self._armorObjects.Add(Utility.CreateChild("DA_1", self._neck, Vector3(-0.570687771,2.29757905,-1.96679378 ), Vector3(359.429321,2.29757905  ,358.033203), Vector3.One));
        self._armorObjects.Add(Utility.CreateChild("DA_2", self._neck, Vector3( 0.679365456,2.31751657,-1.92129743 ), Vector3(347.948364,0.0629453361,359.986847), Vector3.One));
        self._armorObjects.Add(Utility.CreateChild("DB_1", self._armR, Vector3( 0.046075806,2.95184112,-1.03128505 ), Vector3.Zero, Vector3.One));
        self._armorObjects.Add(Utility.CreateChild("DB_2", self._armR, Vector3(-1.42681706 ,2.50064278, 0.962808609), Vector3.Zero, Vector3.One));
        self._armorObjects.Add(Utility.CreateChild("DB_3", self._armR, Vector3( 1.88184988 ,2.60794973,-1.40873075 ), Vector3.Zero, Vector3.One));
        self._armorObjects.Add(Utility.CreateChild("DB_4", self._armR, Vector3( 0.80769515 ,2.21394658,-1.07759917 ), Vector3.Zero, Vector3.One));
        self._armorObjects.Add(Utility.CreateChild("DB_5", self._armR, Vector3(-1.12138474 ,2.26630116,-0.690158665), Vector3.Zero, Vector3.One));
        self._armorObjects.Add(Utility.CreateChild("DB_6", self._armR, Vector3( 2.78087163 ,2.43877983,-0.652130723), Vector3.Zero, Vector3.One));
    }

    function SetupRootAnimations()
    {
        self._rootAnimations.Add(GaiusAnimations.WALK);
        self._rootAnimations.Add(GaiusAnimations.WALK_END);
        self._rootAnimations.Add(GaiusAnimations.WALK_START);
        self._rootAnimations.Add(GaiusAnimations.ATTACK_STOMP_L_FAIL);
        self._rootAnimations.Add(GaiusAnimations.BOOT);
    }

    function ResetRoot()
    {
        self._RootPreviousPosition = self._root.Position;
        self._RootPreviousRotation = self._root.QuaternionRotation;
        self._needResetRoot = true;
    }

    function RemoveArmor()
    {
        self.RemoveArmor_Func();
        MusicPlayer.Play(Music.THE_OPENED_WAY);
        self.NetworkView.SendMessageOthers("RemoverArmor");
    }

    function RemoveArmor_Func()
    {
        if (self._hasArmor)
        {
            self._hasArmor = false;

            nForce = 10.0;
            for (object in self._armorObjects)
            {
                object.Parent = null;
                object.AddBuiltinComponent("Rigidbody", 4.0, Vector3.Down * 25.0, false, false);
                random1 = Random.RandomVector3(Vector3.One * (0-nForce), Vector3.One * nForce);
                random2 = Random.RandomVector3(Vector3.One * (0-nForce), Vector3.One * nForce);
                object.UpdateBuiltinComponent("Rigidbody", "AddForce", random1, "Impulse");
                object.UpdateBuiltinComponent("Rigidbody", "SetToque", random2, "Impulse");
            }

            self._armorObjects.Clear();
        }

    }

    function TurnToTarget()
    {
        if (self._target != null)
        {
            angle = self.GetAngleFromTarget();

            if (Math.Abs(angle) >= 135)
            {
                self.TurnBack();
            }
            else
            {
                self.TurnHalf(angle < 0);
            }
        }
    }

    function TurnBack()
    {
        self._state = GaiusState.TURN;
        self.StateAnimate(GaiusState.TURN, GaiusAnimations.TURN_BACK, 0.4);
    }

    function TurnHalf(left)
    {
        self._state = GaiusState.TURN;
        if (left)
        {
            self.StateAnimate(GaiusState.TURN, GaiusAnimations.TURN_L, 0.4);
        }
        else
        {
            self.StateAnimate(GaiusState.TURN, GaiusAnimations.TURN_R, 0.4);
        }
    }

    function ResetAttack()
    {
        self.ResetRoot();
        self._stateStage = 0;
    }

    # @return float
    function UpdateAnimationNormalizedTime()
    {
        prev = self._normalizedTime;
        self._normalizedTime = (Time.GameTime - self._animationStart) / self._animationLength;
    }

    # @param aniName string
    # @param time float
    function PlayAnimation(aniName, time)
    {
        self.PlayAnimation_Func(aniName, time);

        self.NetworkView.SendMessageOthers("PlayAnimation|" + aniName + ";" + time + ";" + false);
    }

    # @param aniName string
    # @param time float
    function PlayAddonAnimation(aniName, time)
    {
        self.JustPlayAddonAnimation(aniName, time);

        self.NetworkView.SendMessageOthers("PlayAnimation|" + aniName + ";" + time + ";" + true);
    }

    # @param aniName string
    # @param time float
    function PlayAnimation_Func(aniName, fade)
    {
        #self._transform.PlayAnimation(GaiusAnimations.STANDBY, 0.0);
        self._transform.PlayAnimation(aniName, Convert.ToFloat(fade));
        self._normalizedTime = 0.0;
        self._currentAnimation = aniName;
        self._animationStart = Time.GameTime;
        self._animationLength = self._transform.GetAnimationLength(aniName);
    }

    # @param aniName string
    # @param time float
    function JustPlayAddonAnimation(aniName, fade)
    {
        #self._transform.PlayAnimation(GaiusAnimations.STANDBY, fade);
        self._transform.PlayAnimation(aniName, Convert.ToFloat(fade));
        self._addonAnimation = aniName;
    }

    # @param rawdata string
    function Instantiate(rawdata)
    {
        return Map.CreateMapObjectRaw(rawdata);
        self.NetworkView.SendMessageOthers("Instantiate|" + rawdata);
    }

    # @param point Vector3
    # @return CastResult
    function GetGroundCast(point)
    {
        return self.GetGroundCastX(point, "", self.MapObject);
    }

    # @param point Vector3 @param tag string
    # @return CastResult
    function GetGroundCastWithTag(point, tag)
    {
        return self.GetGroundCastX(point, tag, self.MapObject);
    }

    # @param point Vector3 @param tag string @param ignore MapObject
    # @return CastResult
    function GetGroundCastX(point, tag, ignore)
    {
        startPoint = point + Vector3.Up * 20;
        endPoint   = point + Vector3.Down * 30;
        normal     = Vector3.Up;
        cast       = Utility.GroundCast(startPoint, endPoint, "MapObjects", tag, self.MapObject);

        if (cast != null)
        {
            normal = cast.Normal;
            point  = cast.Point;
        }

        return CastResult(cast,point,normal);
    }

    function CreateAttackBoom(position, upDir, effect, size)
    {
                Game.Print(upDir);
        dir = Quaternion.FromEuler(Vector3(270,0,0)) * Quaternion.FromToRotation(Vector3.Up, upDir).Euler;
        Game.Print(dir);
        Game.SpawnEffect(effect, position + upDir * 0.01, dir, size);
        self.CreateExplosionAt(position, "Flattened", size * 6, size * 10 );
    }

    # @param position Vector3 @param name string @param killRadius float @param pushRadius float
    function CreateExplosionAt(position, name, killRadius, pushRadius)
    {
        rad1 = killRadius * 2.0;
        rad2 = pushRadius * 2.0;
        pos = position.X + "," + position.Y + "," + position.Z;
        radius1 = rad1 + "," + rad1 + "," + rad1;
        radius2 = rad2 + "," + rad2 + "," + rad2;
        self.Instantiate("Scene,Geometry/Sphere1,686,0,1,0,0,0,Push," + pos + ",0,0,0," + radius2 + ",Region,Characters,Default,DefaultNoTint|255/255/255/255,DestroySelf|Time:1.0|DestroyChildren:true,PushRegion|Up:2.5|MinForce:7.0");
        self.Instantiate("Scene,Geometry/Sphere1,645,0,1,0,0,0,KillCollider," + pos + ",0,0,0," + radius1 + ",Region,Characters,Default,DefaultNoTint|255/255/255/255,DestroySelf|Time:0.1|DestroyChildren:true,KillHuman|Name:" + name);
    }
}

class GaiusIKManager
{
    dict = Dict();

    /* @type MapObject   */ MapObject = null;

    /* @type TransformIK */ _IK_LegL  = null;
    /* @type TransformIK */ _IK_LegR  = null;
    /* @type TransformIK */ _IK_ArmL  = null;
    /* @type TransformIK */ _IK_ArmR  = null;

    function Init(obj)
    {
        self.MapObject = obj;

        self._IK_LegL = self.MapObject.AddComponent("TransformIK").Setup(obj, GaiusBodyPart.FOOT_L, "OnLateFrame", true);
        self._IK_LegR = self.MapObject.AddComponent("TransformIK").Setup(obj, GaiusBodyPart.FOOT_R, "OnLateFrame", true);
        self._IK_ArmL = self.MapObject.AddComponent("TransformIK").Setup(obj, GaiusBodyPart.HAND_L, "OnLateFrame", true);
        self._IK_ArmR = self.MapObject.AddComponent("TransformIK").Setup(obj, GaiusBodyPart.HAND_R, "OnLateFrame", true);

        self.dict.Set(GaiusBodyPart.FOOT_L, self._IK_LegL);
        self.dict.Set(GaiusBodyPart.FOOT_R, self._IK_LegR);
        self.dict.Set(GaiusBodyPart.HAND_L, self._IK_ArmL);
        self.dict.Set(GaiusBodyPart.HAND_R, self._IK_ArmR);

    }

    function Exists(name)
    {
        if (self.dict.Contains(name))
        {
            return true;
        }

        Game.Print("<color=red>error: unknown ik solver (" + name + ")</color>");
        return false;
    }

    coroutine Fix(name, point, rotation, fade)
    {
        if (!self.Exists(name)) { return; }

        ik = self.dict.Get(name);
        target = ik._Target;

        ik.UpdateMode = "OnLateFrame";
        target.Position = point;
        target.Rotation = rotation;

        startTime = Time.GameTime;
        while (Time.GameTime < startTime + fade)
        {
            ik.Weight = (Time.GameTime - startTime) / fade;
        }
        ik.Weight = 1.0;
    }

    coroutine Unfix(name, fade)
    {
        if (!self.Exists(name)) { return; }

        ik = self.dict.Get(name);

        startTime = Time.GameTime;
        while (Time.GameTime < startTime + fade)
        {
            ik.Weight = 1.0 - (Time.GameTime - startTime) / fade;
        }
        ik.UpdateMode = "None";
        ik.Weight = 0.0;
    }

    function Release(fade)
    {
        for (ikBone in self.dict.Keys)
        {
            self.Unfix(ikBone, fade);
        }
    }

    # @param nview NetworkView
    function SendStream(nview)
    {
        nview.SendStream(self._IK_LegL._Target.Position);
        nview.SendStream(self._IK_LegR._Target.Position);
        nview.SendStream(self._IK_ArmL._Target.Position);
        nview.SendStream(self._IK_ArmR._Target.Position);
        nview.SendStream(self._IK_LegL._Target.Rotation);
        nview.SendStream(self._IK_LegR._Target.Rotation);
        nview.SendStream(self._IK_ArmL._Target.Rotation);
        nview.SendStream(self._IK_ArmR._Target.Rotation);
    }

    # @param nview NetworkView
    function ReceiveStream(nview)
    {
        self._IK_LegL._Target.Position = nview.ReceiveStream();
        self._IK_LegR._Target.Position = nview.ReceiveStream();
        self._IK_ArmL._Target.Position = nview.ReceiveStream();
        self._IK_ArmR._Target.Position = nview.ReceiveStream();
        self._IK_LegL._Target.QuaternionRotation = Quaternion.Lerp(Quaternion.FromEuler(self._IK_LegL._Target.Rotation), Quaternion.FromEuler(nview.ReceiveStream()), 0.4);
        self._IK_LegR._Target.QuaternionRotation = Quaternion.Lerp(Quaternion.FromEuler(self._IK_LegR._Target.Rotation), Quaternion.FromEuler(nview.ReceiveStream()), 0.4);
        self._IK_ArmL._Target.QuaternionRotation = Quaternion.Lerp(Quaternion.FromEuler(self._IK_ArmL._Target.Rotation), Quaternion.FromEuler(nview.ReceiveStream()), 0.4);
        self._IK_ArmR._Target.QuaternionRotation = Quaternion.Lerp(Quaternion.FromEuler(self._IK_ArmR._Target.Rotation), Quaternion.FromEuler(nview.ReceiveStream()), 0.4);
    }
}

class Main
{
    /* @type Gaius */ _gaius = null;
    MusicAsset = "Custom/sotc/music";

    function OnGameStart()
    {
        self._gaius = Map.FindMapObjectByID(2).GetComponent("Gaius");
        self.UpdateSettings();
        UI.SetLabel("BottomRight", "Settings: " + UI.WrapStyleTag(Input.GetKeyName(Keybind.INTERACTION_FUNCTION_4), "color", "#" + UI.GetThemeColor("ChatPanel", "TextColor", "ID").ToHexString()));
    }

    function UpdateSettings()
    {
        self.CreatePopup("Settings", "Settings", 350, 450);

        musicOn = " On";
        if (!MusicPlayer.Enabled) { musicOn = " Off"; }

        UI.AddPopupButton("Settings", "Settings_ToggleMusic", "Music: " + musicOn);
    }

    function CreatePopup(name, title, width, height)
    {
        if (UI.GetPopups().Contains("Settings"))
        {
            UI.ClearPopup(name);
        }
        else
        {
            UI.CreatePopup(name, title, width, height);
        }
    }

    function OnButtonClick(buttonName)
    {
        if (buttonName == "Settings_ToggleMusic")
        {
            MusicPlayer.Toggle();
            self.UpdateSettings();
        }
    }

    function OnNetworkMessage(sender, message)
    {
        rpc = NetworkRPC(message);

        if (rpc.Call == "PlayMusic")
        {
            MusicPlayer.Play(rpc.GetString(0));
        }
    }

    function OnChatInput(message)
    {
        cmd = Command(message);
        if (cmd.IsCommand)
        {
            customCommand = true;
            val = String.Split(String.Substring(message, 1), " ", true);
            command = val.Get(0);
            if (cmd.CommandName == "t")
            {
                Time.TimeScale = cmd.GetFloat(0);
            }
            elif (cmd.CommandName == "c")
            {
                Camera.FollowDistance = cmd.GetFloat(0);
            }
            elif (cmd.CommandName == "boot")
            {
                self._gaius.Boot();
            }
            elif (cmd.CommandName == "arena")
            {
                Network.MyPlayer.Character.Position = Vector3(0.0,185,402);
            }
            elif (cmd.CommandName == "pull")
            {
                self._gaius._transform.Position = Network.MyPlayer.Character.Position;
            }
            elif (cmd.CommandName == "slam")
            {
                self._gaius.StateAnimate(GaiusState.ATTACK, GaiusAnimations.ATTACK_SLAM_START, 0.4);
            }
            elif (cmd.CommandName == "stab")
            {
                self._gaius.StateAnimate(GaiusState.ATTACK, GaiusAnimations.ATTACK_STAB_START, 0.4);
            }
            elif (cmd.CommandName == "stomp")
            {
                self._gaius.StateAnimate(GaiusState.ATTACK, GaiusAnimations.ATTACK_STOMP_L, 0.4);
            }
            elif (cmd.CommandName == "eff")
            {
                Game.SpawnEffect(cmd.GetString(0), Network.MyPlayer.Character.Position, Vector3(270,0,0), 3);
            }
            else
            {
                customCommand = false;
            }

            if (customCommand)
            {
                return false;
            }
        }
    }

    function OnFrame()
    {
        if (!Network.IsMasterClient)
        {
            return;
        }

        if (Input.GetKeyDown(Keybind.INTERACTION_FUNCTION_1))
        {
            self._gaius.FindTarget();
            self._gaius.DoAttack();
        }
        if (Input.GetKeyDown(Keybind.INTERACTION_FUNCTION_2))
        {
            self._gaius.FindTarget();
            self._gaius.TurnToTarget();
        }
        if (Input.GetKeyDown(Keybind.INTERACTION_FUNCTION_3))
        {
            self._gaius.FindTarget();
            self._gaius.Walk();
        }
        if (Input.GetKeyDown(Keybind.INTERACTION_FUNCTION_4))
        {
            UI.ShowPopup("Settings");
        }
        if (Input.GetKeyDown(Keybind.INTERACTION_INTERACT_1))
        {
            self._gaius.PlayAddonAnimation(GaiusAnimations.ADD_ARM_R_UP_START, 0.0);
        }
        if (Input.GetKeyDown(Keybind.INTERACTION_INTERACT_2))
        {
            #self.NextFrame();
        }
        if (Input.GetKeyDown(Keybind.INTERACTION_INTERACT_3))
        {
            #Time.TimeScale = 1.0;
        }

        UI.SetLabel("BottomRight", "_normalizedTime: "    + self._gaius._normalizedTime
                + String.Newline + "_currentAnimation: "  + self._gaius._currentAnimation
                + String.Newline + "_animationStart: "    + self._gaius._animationStart
                + String.Newline + "_state: "             + self._gaius._state
                + String.Newline + "has target: "         + (self._gaius._target != null)
                + String.Newline + "Time: "               + Time.GameTime);

    }

    coroutine NextFrame()
    {
        Time.TimeScale = 1.0;
        wait 0.0;
        Time.TimeScale = 0.0;
    }
}

class CastResult
{
    Hit    = false;

    # @type LineCastHitResult
    Cast   = null;
    Point  = Vector3();
    Normal = Vector3();
    Object = null;
    Tag    = "";

    # @param cast LineCastHitResult
    function Init(cast,point,normal)
    {
        self.Hit    = cast != null;
        self.Cast   = cast;
        self.Point  = point;
        self.Normal = normal;

        if (self.Cast != null)
        {
            self.Object = cast.Collider;

            if (self.Object.Type == "MapObject" && self.Object.GetComponent("Tag") != null)
            {
                self.Tag = self.Object.GetComponent("Tag").Name;
            }
        }
    }

    function ToString()
    {
        if (self.Hit)
        {
            return "CastResult - Hit: " + self.Hit + ", Point: " + self.Point + ", Normal: " + self.Normal + ", Object: " + self.Object;
        }
        return "CastResult - Hit: " + self.Hit + ", Point: " + self.Point + ", Normal: " + self.Normal;
    }
}
