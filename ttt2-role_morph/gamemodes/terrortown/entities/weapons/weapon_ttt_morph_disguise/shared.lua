if SERVER then
	AddCSLuaFile()	

   util.AddNetworkString("TTT2UpdateDisguiserTarget")
	util.AddNetworkString("TTT2ToggleDisguiserTarget")
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
		self:AddHUDHelpLine("Show mouse to select Morph target.", Key("+showscores", "tab"))
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


function disguiseMorphling(argument, plyToDisguiseInto)
   -- if argument is not anything leave the function early
   if argument == nil then return end
   if CLIENT then
      argument:PrintMessage(HUD_PRINTTALK, "You are a CLIENT morphling.")
      argument:PrintMessage(HUD_PRINTTALK, argument)
      argument:PrintMessage(HUD_PRINTTALK, plyToDisguiseInto)
      argument:PrintMessage(HUD_PRINTTALK, plyToDisguiseInto:GetModel())
   end
   if SERVER then
      EPOP:AddMessage({text =  "I am the SERVER. Enjoy this EPOP message.", color = MORPHLING.color}, {text = "Hello from the SERVER."}, 5, nil, true)
      argument:UpdateStoredDisguiserTarget(plyToDisguiseInto, plyToDisguiseInto:GetModel(), plyToDisguiseInto:GetSkin())
      argument:DeactivateDisguiserTarget()
      argument:ToggleDisguiserTarget()
   end
end

-- Primary attack opens a Disguise menu
function SWEP:PrimaryAttack()
   if CLIENT then
      -- create friendly variable for the weapons owner
      local owner = self:GetOwner()
      -- Simply open the morphling menu
      openMorphlingMenu(owner)
   end
end

function openMorphlingMenu(owner)
-- Create a GUI and sound
   morphFrame = vgui.Create("DFrame")
   morphFrame:SetPos(10, ScrH() - 800)
   morphFrame:SetSize(200, 300)
   morphFrame:SetTitle("Disguise into: (Hold " .. Key("+showscores", "tab"):lower() .. ")")
   morphFrame:SetDraggable(true)
   morphFrame:ShowCloseButton(true)
   morphFrame:SetVisible(true)
   morphFrame:SetDeleteOnClose(true)
   surface.PlaySound("npc/antlion/attack_single1.wav")
   
   -- Create list of Players avaliable to disguise into
   local morphList = vgui.Create("DListView", morphFrame)
   morphList:Dock(FILL)
   morphList:SetMultiSelect(false)
   morphList:AddColumn("Players")
   
   -- Populate the list
   for _, v in ipairs(player.GetAll()) do
      if (v:Alive() and not v:IsSpec()) or not v:Alive() then
         morphList:AddLine(v)
      end
   end

   -- When player selects one of the options, do X
   morphList.OnRowSelected = function(lst, index, pnl)
      if owner:Alive() and not owner:IsSpec() then
         -- Remind player who they disguised into
         ent = pnl:GetValue(1)
         owner:PrintMessage(HUD_PRINTTALK, "You morphed into " .. ent:Nick())
         -- Add special alien effects
         morphlingSpecialEffects(owner, ent)
         -- Close the menu
         morphFrame:Close()
         -- Run my custom Hook
         hook.Call("EVENT_MORPHLING_DISGUISE", nil, owner, pnl:GetValue(1)) -- HOOK DOESNT RUN
      else
         owner:PrintMessage(HUD_PRINTTALK, "ERROR! You must be alive to morph.")
      end
   end
end

-- This is the function that handles the Alien effects (DONT TOUCH)
function morphlingSpecialEffects(plyToDisguiseInto)
   -- Gather data about the morphlings position
   local hitEnt = LocalPlayer()
   local edata = EffectData()
   edata:SetEntity(hitEnt)
   edata:SetOrigin(hitEnt:GetNetworkOrigin())
   -- play a sound for the client
   if CLIENT then
      surface.PlaySound("npc/antlion/distract1.wav")
   end
   -- paint some icky stuff and particles
   util.PaintDown(hitEnt:LocalToWorld(hitEnt:OBBCenter()), "Antlion.Splat", hitEnt)
   util.Effect("AntlionGib", edata)
end