AddCSLuaFile()

SWEP.Category			= "simfphys"
SWEP.Spawnable		= true
SWEP.AdminSpawnable	= false
SWEP.ViewModel		= "models/weapons/c_pistol.mdl"
SWEP.WorldModel		= "models/weapons/w_pistol.mdl"
SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 53
SWEP.Weight 			= 42
SWEP.AutoSwitchTo 		= true
SWEP.AutoSwitchFrom 	= true
SWEP.HoldType			= "pistol"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

function SWEP:SetupDataTables()
	self:NetworkVar( "Entity", 0, "Car" )
	self:NetworkVar( "Bool", 0, "Active" )
end

if CLIENT then
	SWEP.PrintName		= "Remote Controller"
	SWEP.Purpose			= "remote controls simfphys vehicles"
	SWEP.Instructions		= "Left-Click on a simfphys car to link. Press the Use-Key to start remote controlling."
	SWEP.Author			= "Blu"
	SWEP.Slot				= 1
	SWEP.SlotPos			= 10

	function SWEP:PrimaryAttack()
		if self:GetActive() then return false end

		local trace = self:GetOwner():GetEyeTrace()
		local ent = trace.Entity

		if not simfphys.IsCar( ent ) then return false end

		self:EmitSound( "Weapon_Pistol.Empty" )

		return true
	end

	function SWEP:SecondaryAttack()
		if self:GetActive() then return false end

		self:EmitSound( "Weapon_Pistol.Empty" )

		return true
	end

	function SWEP:Think()
		if self.HasHaloHook then return end
		self.HasHaloHook = true

		hook.Add( "PreDrawHalos", "simfphys_remote_halos", function()
			local ply = LocalPlayer()
			local weapon = ply:GetActiveWeapon()
			if not weapon:IsValid() or weapon:GetClass() ~= "weapon_simremote" then
				hook.Remove( "PreDrawHalos", "simfphys_remote_halos" )
				self.HasHaloHook = nil
				return
			end

			if IsValid( weapon ) then
				if ply:InVehicle() then return end

				if not weapon:GetActive() then
					local car = weapon:GetCar()

					if IsValid( car ) then
						halo.Add( { car }, Color( 0, 127, 255 ) )
					end
				end
			end
		end )
	end

	return
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:OwnerChanged()
end

function SWEP:Think()
	if not self:GetOwner():KeyPressed( IN_USE ) then return end
	
	if self:GetActive() or not IsValid( self:GetCar() ) then
		self:Disable()
	else
		self:Enable()
	end
end

local function canControl( ply, car )
	if CPPI and not car:CPPICanTool( ply, "weapon_simremote" ) then return false end

	return true
end

function SWEP:PrimaryAttack()
	if self:GetActive() then return false end

	local ply = self:GetOwner()
	local trace = ply:GetEyeTrace()
	local ent = trace.Entity

	if not simfphys.IsCar( ent ) then return false end
	if not canControl( ply, ent ) then return false end

	self:SetCar( ent )

	ply:ChatPrint( "Remote Controller linked." )

	return true
end

function SWEP:SecondaryAttack()
	if self:GetActive() then return false end

	if IsValid( self:GetCar() ) then
		self:SetCar( NULL )
		self:GetOwner():ChatPrint( "Remote Controller unlinked." )

		return true
	end

	return false
end

function SWEP:Enable()
	local car = self:GetCar()

	if not IsValid( car ) then return end

	local ply = self:GetOwner()
	
	if IsValid( car:GetDriver() ) then
		ply:ChatPrint( "Vehicle is already in use." )
	else
		if car:GetIsVehicleLocked() then
			ply:ChatPrint( "Vehicle is locked." )
		else
			self.UsingPlayer = ply
			self:SetActive( true )

			ply:SetMoveType( MOVETYPE_NONE )
			ply:DrawViewModel( false )

			car.RemoteDriver = ply
		end
	end
end

function SWEP:Disable()
	local ply = self.UsingPlayer
	local car = self:GetCar()

	if self:GetActive() and IsValid( ply ) then
		ply:SetMoveType( MOVETYPE_WALK )
		ply:DrawViewModel( true )
	end

	self:SetActive( false )
	self.OldMoveType = nil

	if IsValid( car ) then
		car.RemoteDriver = nil
	end
end

hook.Add( "simfphysOnDelete", "simfphysOnDelete_remote", function( ent )
	local driver = ent.RemoteDriver
	if not driver then return end

	local ply = ent.RemoteDriver
	local weapon = ply:GetActiveWeapon()

	if IsValid( weapon ) and weapon:GetClass() == "weapon_simremote" then
		weapon:Disable()
	end
end )

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_VM_DRAW )
	return true
end

function SWEP:Holster()
	if IsValid( self:GetCar() ) then
		self:Disable()
	end
	return true
end

function SWEP:OnDrop()
	if IsValid( self:GetCar() ) then
		self:Disable()
		self.TheCar = nil
	end
end
