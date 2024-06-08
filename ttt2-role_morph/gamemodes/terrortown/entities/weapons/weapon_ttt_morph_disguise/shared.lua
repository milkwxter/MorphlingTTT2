if SERVER then
	AddCSLuaFile()	
   util.AddNetworkString("ttt2_morphling_morph_net")
end

SWEP.HoldType               = "knife"

if CLIENT then
   SWEP.PrintName           = "Morphling Disguiser"
   SWEP.Slot                = 8
   SWEP.ViewModelFlip       = false
   SWEP.ViewModelFOV        = 90
   SWEP.DrawCrosshair       = false
	
   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "Bring up a menu to disguise yourself as other players."
   };

   SWEP.Icon                = "vgui/ttt/icon_morph_disguise"
   SWEP.IconLetter          = "j"

   function SWEP:Initialize()
		self:AddTTT2HUDHelp("Open Morphling Menu.")
		self:AddHUDHelpLine("Show mouse to select morph target.", Key("+showscores", "tab"))
	end
end

SWEP.Base                   = "weapon_tttbase"

SWEP.UseHands               = true
SWEP.ViewModel              = "models/weapons/cstrike/c_knife_t.mdl"
SWEP.WorldModel             = "models/weapons/w_knife_t.mdl"

SWEP.Primary.Damage         = 0
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Delay          = 1
SWEP.Primary.Ammo           = "none"

SWEP.Kind                   = WEAPON_CLASS
SWEP.AllowDrop              = false -- Is the player able to drop the swep

SWEP.IsSilent               = true

-- Pull out faster than standard guns
SWEP.DeploySpeed            = 2

--Removes the Disguise tool on death or drop
function SWEP:OnDrop()
	self:Remove()
end

-- Primary attack opens a Disguise menu
if CLIENT then
   function SWEP:PrimaryAttack()
      -- Create a GUI and sound
      morphFrame = vgui.Create("DFrame")
      morphFrame:SetPos(10, ScrH() - 800)
      morphFrame:SetSize(200, 300)
      morphFrame:SetTitle("Gather DNA: (Hold " .. Key("+showscores", "tab"):lower() .. ")")
      morphFrame:SetDraggable(true)
      morphFrame:ShowCloseButton(true)
      morphFrame:SetVisible(true)
      morphFrame:SetDeleteOnClose(true)
      surface.PlaySound("npc/antlion/attack_single1.wav")

      -- Create list of Players avaliable to disguise into
      local list = vgui.Create("DListView", morphFrame)
      list:Dock(FILL)
      list:SetMultiSelect(false)
      list:AddColumn("Players")

      -- Populate the list
      for _, v in ipairs(player.GetAll()) do
         if (v:Alive() and not v:IsSpec()) or not v:Alive() then
            list:AddLine(v)
         end
      end

      -- When player selects one of the options, do X
      list.OnRowSelected = function(lst, index, pnl)
         local ply = LocalPlayer()
         if ply:Alive() and not ply:IsSpec() then
            -- Remind player who they disguised into
            LocalPlayer():PrintMessage(HUD_PRINTTALK, "You morphed into: " .. pnl:GetValue(1):Nick())
            -- Close the menu
            morphFrame:Close()
            -- Play a sound for the client
            surface.PlaySound("npc/antlion/distract1.wav")
            -- Start a message to the server, send the local player and whoever they selected
            net.Start("ttt2_morphling_morph_net")
            net.WriteEntity(LocalPlayer())
				net.WriteEntity(pnl:GetValue(1))
				net.SendToServer()
         else
            ply:PrintMessage(HUD_PRINTTALK, "Error. You must be alive to morph.")
         end
      end
   end
end

net.Receive("ttt2_morphling_morph_net", function()
   local morphlingPlayer = net.ReadEntity()
   local morphTarget = net.ReadEntity()

   if CLIENT then return end

   if morphTarget == morphlingPlayer then
      morphlingPlayer:DeactivateDisguiserTarget()
	   morphlingPlayer:UpdateStoredDisguiserTarget(nil)
      return
   end

   morphlingPlayer:UpdateStoredDisguiserTarget(morphTarget, morphTarget:GetModel(), morphTarget:GetSkin())
	morphlingPlayer:DeactivateDisguiserTarget()
   morphlingPlayer:ToggleDisguiserTarget()

   -- Alien effects (DONT TOUCH!!!)
   local edata = EffectData()
   edata:SetEntity(morphlingPlayer)
   edata:SetOrigin(morphlingPlayer:GetNetworkOrigin())
   util.PaintDown(morphlingPlayer:LocalToWorld(morphlingPlayer:OBBCenter()), "Antlion.Splat", morphlingPlayer)
   util.Effect("AntlionGib", edata)
end)