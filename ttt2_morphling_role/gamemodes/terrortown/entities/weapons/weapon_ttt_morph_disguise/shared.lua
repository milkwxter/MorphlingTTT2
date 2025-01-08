if SERVER then
	AddCSLuaFile()	
   util.AddNetworkString("ttt2_morphling_morph_net")
   resource.AddWorkshop("3263839562") -- Auto download the mod for clients
   resource.AddWorkshop("2144375749") -- Auto download the required mod for clients
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

local MorphlingMenuOpen = false

--Removes the Disguise tool on death or drop
function SWEP:OnDrop()
	self:Remove()
end

-- Primary attack opens a Disguise menu
if CLIENT then
   function SWEP:PrimaryAttack()
      if MorphlingMenuOpen == true then return end
	  -- Store reference to local player
	  local ply = LocalPlayer()
	  
      -- Create a GUI and sound
	  morphFrame = vgui.Create("DFrame")
      MorphlingMenuOpen = true
      morphFrame:SetPos(10, ScrH() - 800)
      morphFrame:SetSize(200, 300)
      morphFrame:SetTitle("Gather DNA: (Hold " .. Key("+showscores", "tab"):lower() .. ")")
      morphFrame:SetDraggable(true)
      morphFrame:ShowCloseButton(false)
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
         if ply:Alive() and not ply:IsSpec() then
            -- Close the menu
            morphFrame:Close()
            -- Play a sound for the client
            surface.PlaySound("npc/antlion/distract1.wav")
            -- Start a message to the server, send the local player and whoever they selected
            net.Start("ttt2_morphling_morph_net")
            net.WriteEntity(ply)
			net.WriteEntity(pnl:GetValue(1))
			net.SendToServer()
            -- tell the weapon the menu is closed
            MorphlingMenuOpen = false
         else
            ply:PrintMessage(HUD_PRINTTALK, "Error. You must be alive to morph.")
         end
      end
   end
end

net.Receive("ttt2_morphling_morph_net", function()
	-- collect information from net message
    local morphlingPlayer = net.ReadEntity()
    local morphTarget = net.ReadEntity()
	
	-- no clients allowed
    if CLIENT then return end
	
	if morphlingPlayer:GetRoleString() != "morphling" then
		morphlingPlayer:PrintMessage(HUD_PRINTTALK, "Error. You are no longer a Morphling. You can safely ignore this message.")
		return 
	end

	-- check if morphing player decides to remove disguise
    if morphTarget == morphlingPlayer then
	   morphlingPlayer:PrintMessage(HUD_PRINTTALK, "You removed your disguise!")
       morphlingPlayer:DeactivateDisguiserTarget()
	   morphlingPlayer:UpdateStoredDisguiserTarget(nil)
      return
    end

	-- otherwise, update his disguise
	morphlingPlayer:PrintMessage(HUD_PRINTTALK, "You morphed into: " .. morphTarget:Nick())
    morphlingPlayer:UpdateStoredDisguiserTarget(morphTarget, morphTarget:GetModel(), morphTarget:GetSkin())
	morphlingPlayer:DeactivateDisguiserTarget()
    morphlingPlayer:ToggleDisguiserTarget()

   -- alien effects
   local edata = EffectData()
   edata:SetEntity(morphlingPlayer)
   edata:SetOrigin(morphlingPlayer:GetNetworkOrigin())
   util.PaintDown(morphlingPlayer:LocalToWorld(morphlingPlayer:OBBCenter()), "Antlion.Splat", morphlingPlayer)
   util.Effect("AntlionGib", edata)
end)