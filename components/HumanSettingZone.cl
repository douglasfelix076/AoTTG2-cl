component HumanSettingZone
{
    DisableHooks = false;
    DisableAttacks = false;
    DisableSpecial = false;
    DisableGasJump = false;
    DisableDodge = false;
    Invincibility = false;

    #@type Human
    human = null;
    function OnCollisionEnter(obj)
    {
        if (Network.MyPlayer.CharacterType == "Human" && Network.MyPlayer.Character != null && Network.MyPlayer.Character == obj)
        {
            self.human = Network.MyPlayer.Character;
            if (self.DisableHooks)
            {
                self.human.RightHookEnabled = false;
                self.human.LeftHookEnabled = false;
                self.human.ClearHooks();
            }
            if (self.DisableAttacks)
            {
                Input.SetKeyDefaultEnabled("Human/AttackDefault", false);
                Input.SetKeyDefaultEnabled("Human/Reload", false);
            }
            if (self.DisableSpecial)
            {
                Input.SetKeyDefaultEnabled("Human/AttackSpecial", false);
            }
            if (self.DisableGasJump)
            {
                Input.SetKeyDefaultEnabled("Human/Jump", false);
            }
            if (self.DisableDodge)
            {
                Input.SetKeyDefaultEnabled("Human/Dodge", false);
            }
            if (self.Invincibility)
            {
                self.human.IsInvincible = true;
            }
        }
    }

    function OnCollisionExit(obj)
    {
        if (obj == self.human)
        {
            if (self.DisableHooks)
            {
                self.human.RightHookEnabled = true;
                self.human.LeftHookEnabled = true;
            }
            if (self.DisableAttacks)
            {
                Input.SetKeyDefaultEnabled("Human/AttackDefault", true);
                Input.SetKeyDefaultEnabled("Human/Reload", true);
            }
            if (self.DisableSpecial)
            {
                Input.SetKeyDefaultEnabled("Human/AttackSpecial", true);
            }
            if (self.DisableGasJump)
            {
                Input.SetKeyDefaultEnabled("Human/Jump", true);
            }
            if (self.DisableDodge)
            {
                Input.SetKeyDefaultEnabled("Human/Dodge", true);
            }
            if (self.Invincibility && self.human.InvincibleTimeLeft <= 0.0)
            {
                self.human.IsInvincible = false;
            }
        }
    }
}