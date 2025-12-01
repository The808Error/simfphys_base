local function IsServerOK()

	if GetConVar( "gmod_physiterations" ):GetInt() < 4 then
		RunConsoleCommand("gmod_physiterations", "4")

		return false
	end

	return true
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetNotSolid( true )
	self:SetUseType( SIMPLE_USE )
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
	self:AddFlags( FL_OBJECT ) -- this allows npcs to see this entity

	if not IsServerOK() then

		self:Remove()

		print("[SIMFPHYS] ERROR COULDN'T INITIALIZE VEHICLE!")
	end

	local PObj = self:GetPhysicsObject()

	if not IsValid( PObj ) then print("[SIMFPHYS] ERROR COULDN'T INITIALIZE VEHICLE! '"..self:GetModel().."' has no physics model!") self:Remove() return end

	PObj:EnableMotion( false )

	self:SetValues()

	timer.Simple( 0.1, function()
		if not IsValid( self ) then return end
		self:InitializeVehicle()
	end)
end

function ENT:PostEntityPaste( ply, ent, createdEntities )
	self:SetValues()

	self:SetActive( false )
	self:SetDriver( NULL )
	self:SetLightsEnabled( false )
	self:SetLampsEnabled( false )
	self:SetFogLightsEnabled( false )

	self:SetDriverSeat( NULL )
	self:SetFlyWheelRPM( 0 )
	self:SetThrottle( 0 )
end

function ENT:UpdateTransmitState()
	return TRANSMIT_PVS -- TODO: originally this was TRANSMIT_ALWAYS which would network players all over the map for no reason, it was changed to PVS only, *might* cause issues.
end

function ENT:SetupView()
	local AttachmentID = self:LookupAttachment( "vehicle_driver_eyes" )
	local AttachmentID2 = self:LookupAttachment( "vehicle_passenger0_eyes" )

	local a_data1 = self:GetAttachment( AttachmentID )
	local a_data2 = self:GetAttachment( AttachmentID2 )

	local ID
	local ViewPos

	if a_data1 then
		ID = AttachmentID
		ViewPos = a_data1

	elseif a_data2 then
		ID = AttachmentID2
		ViewPos = a_data2

	else
		ID = false
		ViewPos = {
			Ang = self:LocalToWorldAngles( Angle( 0, 90,0 ) ),
			Pos = self:GetPos()
		}
	end

	local ViewAng = ViewPos.Ang - Angle( 0, 0, self.SeatPitch )
	ViewAng:RotateAroundAxis( self:GetUp(), -90 - ( self.SeatYaw or 0 ) )

	local data = {
		ID = ID,
		ViewPos = ViewPos.Pos,
		ViewAng = ViewAng,
	}

	return data
end

function ENT:SetupEnteringAnims()
	local attachments = self:GetAttachments()

	self.Exitpoints = {}
	self.Enterpoints = {}

	for _,i in pairs( attachments ) do
		local curstring = string.lower( i.name )

		if string.match( curstring, "exit", 1 ) then
			table.insert(self.Exitpoints, curstring)
		end

		if string.match( curstring, "enter", 1 ) then
			table.insert(self.Enterpoints, curstring)
		end
	end

	if table.Count( self.Enterpoints ) < 1 then
		self.Enterpoints = nil
	end

	if table.Count( self.Exitpoints ) < 1 then
		self.Exitpoints = nil
	end
end

function ENT:InitializeVehicle()
	if not IsValid( self ) then return end

	local physObj = self:GetPhysicsObject()

	if not IsValid( physObj ) then return end

	if self.LightsTable then
		local vehiclelist = list.Get( "simfphys_lights" )[self.LightsTable] or false
		if vehiclelist then
			if vehiclelist.PoseParameters then
				self.LightsPP = vehiclelist.PoseParameters
			end

			if vehiclelist.BodyGroups then
				self:SetBodygroup( vehiclelist.BodyGroups.Off[1], vehiclelist.BodyGroups.Off[2] )
			end
		end
	end

	physObj:SetDragCoefficient( self.AirFriction or -250 )
	physObj:SetMass( self.Mass * 0.75 )

	if self.Inertia then
		physObj:SetInertia( self.Inertia )
	end

	local tanksize = self.FuelTankSize and self.FuelTankSize or 65
	local fueltype = self.FuelType and self.FuelType or FUELTYPE_PETROL

	self:SetMaxFuel( tanksize )
	self:SetFuel( self:GetMaxFuel() )
	self:SetFuelType( fueltype )
	self:SetFuelPos( self.FuelFillPos and self.FuelFillPos or Vector() )

	local View = self:SetupView()

	local driverSeat = ents.Create( "prop_vehicle_prisoner_pod" )
	self.DriverSeat = driverSeat

	driverSeat:SetMoveType( MOVETYPE_NONE )

	driverSeat:SetModel( "models/nova/airboat_seat.mdl" )
	driverSeat:SetKeyValue( "vehiclescript","scripts/vehicles/prisoner_pod.txt" )
	driverSeat:SetKeyValue( "limitview", self.LimitView and 1 or 0 )
	driverSeat:SetPos( View.ViewPos )
	driverSeat:SetAngles( View.ViewAng )
	driverSeat:SetOwner( self )
	driverSeat:Spawn()
	driverSeat:Activate()
	driverSeat:SetPos( View.ViewPos + driverSeat:GetUp() * ( -34 + self.SeatOffset.z ) + self.DriverSeat:GetRight() * ( self.SeatOffset.y ) + self.DriverSeat:GetForward() * ( -6 + self.SeatOffset.x ) )
	driverSeat:SetNWInt( "pPodIndex", 1 )

	if View.ID then
		self:SetupEnteringAnims()
		driverSeat:SetParent( self, View.ID )
	else
		driverSeat:SetParent( self )
	end

	driverSeat:GetPhysicsObject():EnableDrag( false )
	driverSeat:GetPhysicsObject():EnableMotion( false )
	driverSeat:GetPhysicsObject():SetMass( 1 )
	driverSeat.fphysSeat = true
	driverSeat.base = self
	driverSeat.DoNotDuplicate = true

	self:DeleteOnRemove( driverSeat )
	self:SetDriverSeat( driverSeat )
	driverSeat:SetNotSolid( true )
	--self.DriverSeat:SetNoDraw( true )
	driverSeat:SetColor( Color( 255, 255, 255, 0 ) )
	driverSeat:SetRenderMode( RENDERMODE_TRANSALPHA )
	driverSeat:DrawShadow( false )
	simfphys.SetOwner( self.EntityOwner, driverSeat )

	if self.PassengerSeats then
		for i = 1, #self.PassengerSeats do
			local seat = ents.Create( "prop_vehicle_prisoner_pod" )
			self.pSeat[i] = seat

			seat:SetModel( "models/nova/airboat_seat.mdl" )
			seat:SetKeyValue( "vehiclescript","scripts/vehicles/prisoner_pod.txt" )
			seat:SetKeyValue( "limitview", 0 )
			seat:SetPos( self:LocalToWorld( self.PassengerSeats[i].pos ) )
			seat:SetAngles( self:LocalToWorldAngles( self.PassengerSeats[i].ang ) )
			seat:SetOwner( self )
			seat:Spawn()
			seat:Activate()
			seat:SetNotSolid( true )
			--self.pSeat[i]:SetNoDraw( true )
			seat:SetColor( Color( 255, 255, 255, 0 ) )
			seat:SetRenderMode( RENDERMODE_TRANSALPHA )

			seat.fphysSeat = true
			seat.base = self
			seat.DoNotDuplicate = true
			simfphys.SetOwner( self.EntityOwner, self.pSeat[i] )

			seat:DrawShadow( false )
			seat:GetPhysicsObject():EnableMotion( false )
			seat:GetPhysicsObject():EnableDrag(false)
			seat:GetPhysicsObject():SetMass(1)

			self:DeleteOnRemove( seat )

			self.pSeat[i]:SetParent( self )

			self.pPodKeyIndex = self.pPodKeyIndex and self.pPodKeyIndex + 1 or 2

			self.pSeat[i]:SetNWInt( "pPodIndex", self.pPodKeyIndex )
		end
	end

	if WireLib then
		local passengersSeats = istable( self.pSeat ) and self.pSeat or {}

		WireLib.TriggerOutput( self, "PassengerSeats", passengersSeats )
		WireLib.TriggerOutput( self, "DriverSeat", self.DriverSeat )
	end

	if self.Attachments then
		for i = 1, #self.Attachments do
			local prop = ents.Create( ( self.Attachments[i].IsGlass and "gmod_sent_vehicle_fphysics_attachment_translucent" or "gmod_sent_vehicle_fphysics_attachment") )
			prop:SetModel( self.Attachments[i].model )
			prop:SetMaterial( self.Attachments[i].material )
			prop:SetRenderMode( RENDERMODE_TRANSALPHA )
			prop:SetPos( self:LocalToWorld( self.Attachments[i].pos ) )
			prop:SetAngles( self:LocalToWorldAngles( self.Attachments[i].ang ) )
			prop:SetOwner( self )
			prop:Spawn()
			prop:Activate()
			prop:DrawShadow( true )
			prop:SetNotSolid( true )
			prop:SetParent( self )
			prop.DoNotDuplicate = true
			simfphys.SetOwner( self.EntityOwner, prop )

			if self.Attachments[i].skin then
				prop:SetSkin( self.Attachments[i].skin )
			end

			if self.Attachments[i].bodygroups then
				for b = 1, #self.Attachments[i].bodygroups do
					prop:SetBodygroup(b, self.Attachments[i].bodygroups[b] )
				end
			end

			if self.Attachments[i].useVehicleColor == true then
				self.ColorableProps[i] = prop
				prop:SetColor( self:GetColor() )
			else
				prop:SetColor( self.Attachments[i].color or Color( 255, 255, 255, 255 ) )
			end

			self:DeleteOnRemove( prop )
		end
	end

	self:GetVehicleData()
end

function ENT:GetVehicleData()
	self:SetPoseParameter( "vehicle_steer", 1 )
	self:SetPoseParameter( "vehicle_wheel_fl_height", 1 )
	self:SetPoseParameter( "vehicle_wheel_fr_height", 1 )
	self:SetPoseParameter( "vehicle_wheel_rl_height", 1 )
	self:SetPoseParameter( "vehicle_wheel_rr_height", 1 )

	timer.Simple( 0.15, function()
		if not IsValid( self ) then return end
		self.posepositions["Pose0_Steerangle"] = self.CustomWheels and Angle() or self:GetAttachment( self:LookupAttachment( "wheel_fl" ) ).Ang
		self.posepositions["Pose0_Pos_FL"] = self.CustomWheels and self:LocalToWorld( self.CustomWheelPosFL ) or self:GetAttachment( self:LookupAttachment( "wheel_fl" ) ).Pos
		self.posepositions["Pose0_Pos_FR"] = self.CustomWheels and self:LocalToWorld( self.CustomWheelPosFR ) or self:GetAttachment( self:LookupAttachment( "wheel_fr" ) ).Pos
		self.posepositions["Pose0_Pos_RL"] = self.CustomWheels and self:LocalToWorld( self.CustomWheelPosRL ) or self:GetAttachment( self:LookupAttachment( "wheel_rl" ) ).Pos
		self.posepositions["Pose0_Pos_RR"] = self.CustomWheels and self:LocalToWorld( self.CustomWheelPosRR ) or self:GetAttachment( self:LookupAttachment( "wheel_rr" ) ).Pos

		self:WriteVehicleDataTable()
	end )
end

function ENT:ResetJoystick()
	self.PressedKeys["joystick_steer_left"] = 0
	self.PressedKeys["joystick_steer_right"] = 0
	self.PressedKeys["joystick_brake"] = 0
	self.PressedKeys["joystick_throttle"] = 0
	self.PressedKeys["joystick_gearup"] = 0
	self.PressedKeys["joystick_geardown"] = 0
	self.PressedKeys["joystick_handbrake"] = 0
	self.PressedKeys["joystick_clutch"] = 0
	self.PressedKeys["joystick_air_w"] = 0
	self.PressedKeys["joystick_air_a"] = 0
	self.PressedKeys["joystick_air_s"] = 0
	self.PressedKeys["joystick_air_d"] = 0
end

function ENT:SetValues()
	if istable( WireLib ) then
		self:createWireIO()
	end

	self:SetGear( 2 )

	self.EnableSuspension = 0
	self.WheelOnGroundDelay = 0
	self.SmoothAng = 0
	self.Steer = 0
	self.EngineIsOn = 0
	self.EngineTorque = 0

	self.pSeat = {}
	self.exfx = {}
	self.Wheels = {}
	self.Elastics = {}
	self.GhostWheels = {}
	self.PressedKeys = {}
	self:ResetJoystick()

	self.ColorableProps = {}
	self.posepositions = {}

	self.HandBrakePower = 0
	self.DriveWheelsOnGround = 0
	self.WheelRPM = 0
	self.EngineRPM = 0
	self.RpmDiff = 0
	self.Torque = 0
	self.CurrentGear = 2
	self.GearUpPressed = 0
	self.GearDownPressed = 0
	self.RPM_DIFFERENCE = 0
	self.exprpmdiff = 0
	self.OldLockBrakes = 0
	self.ThrottleDelay = 0
	self.Brake = 0
	self.HandBrake = 0
	self.AutoClutch = 0
	self.NextShift = 0
	self.ForwardSpeed = 0
	self.EngineWasOn = 0
	self.SmoothTurbo = 0
	self.SmoothBlower = 0
	self.cc_speed = 0
	self.LightsActivated = false

	self.VehicleData = {}
	for i = 1, 6 do
		self.VehicleData[ "spin_"..i ] = 0
		self.VehicleData[ "SurfaceMul_"..i ] = 1
		self.VehicleData[ "onGround_"..i ] = 0
	end

	self.VehicleData[ "Steer" ] = 0
end

function ENT:WriteVehicleDataTable()
	self:SetPoseParameter( "vehicle_steer", 0 )
	self:SetPoseParameter( "vehicle_wheel_fl_height", 0 )
	self:SetPoseParameter( "vehicle_wheel_fr_height", 0 )
	self:SetPoseParameter( "vehicle_wheel_rl_height", 0 )
	self:SetPoseParameter( "vehicle_wheel_rr_height", 0 )

	timer.Simple( 0.1, function()
		if not IsValid( self ) then return end

		self.posepositions["Pose1_Steerangle"] = self.CustomWheels and Angle() or self:GetAttachment( self:LookupAttachment( "wheel_fl" ) ).Ang
		self.posepositions["Pose1_Pos_FL"] = self.CustomWheels and self:LocalToWorld( self.CustomWheelPosFL ) or self:GetAttachment( self:LookupAttachment( "wheel_fl" ) ).Pos
		self.posepositions["Pose1_Pos_FR"] = self.CustomWheels and self:LocalToWorld( self.CustomWheelPosFR ) or self:GetAttachment( self:LookupAttachment( "wheel_fr" ) ).Pos
		self.posepositions["Pose1_Pos_RL"] = self.CustomWheels and self:LocalToWorld( self.CustomWheelPosRL ) or self:GetAttachment( self:LookupAttachment( "wheel_rl" ) ).Pos
		self.posepositions["Pose1_Pos_RR"] = self.CustomWheels and self:LocalToWorld( self.CustomWheelPosRR ) or self:GetAttachment( self:LookupAttachment( "wheel_rr" ) ).Pos
		self.posepositions["PoseL_Pos_FL"] = self:WorldToLocal( self.posepositions.Pose1_Pos_FL )
		self.posepositions["PoseL_Pos_FR"] = self:WorldToLocal( self.posepositions.Pose1_Pos_FR )
		self.posepositions["PoseL_Pos_RL"] = self:WorldToLocal( self.posepositions.Pose1_Pos_RL )
		self.posepositions["PoseL_Pos_RR"] = self:WorldToLocal( self.posepositions.Pose1_Pos_RR )

		self.VehicleData["suspensiontravel_fl"] = self.CustomWheels and self.FrontHeight or math.Round( ( self.posepositions.Pose0_Pos_FL - self.posepositions.Pose1_Pos_FL):Length() , 2)
		self.VehicleData["suspensiontravel_fr"] = self.CustomWheels and self.FrontHeight or math.Round( ( self.posepositions.Pose0_Pos_FR - self.posepositions.Pose1_Pos_FR):Length() , 2)
		self.VehicleData["suspensiontravel_rl"] = self.CustomWheels and self.RearHeight or math.Round( ( self.posepositions.Pose0_Pos_RL - self.posepositions.Pose1_Pos_RL):Length() , 2)
		self.VehicleData["suspensiontravel_rr"] = self.CustomWheels and self.RearHeight or math.Round( ( self.posepositions.Pose0_Pos_RR - self.posepositions.Pose1_Pos_RR):Length() , 2)

		local Figure1 = math.Round( math.acos( math.Clamp( self.posepositions.Pose0_Steerangle:Up():Dot( self.posepositions.Pose1_Steerangle:Up()),-1,1) ) * (180 / math.pi) , 2)
		local Figure2 = math.Round( math.acos( math.Clamp( self.posepositions.Pose0_Steerangle:Forward():Dot( self.posepositions.Pose1_Steerangle:Forward()),-1,1) ) * (180 / math.pi) , 2)
		local Figure3 = math.Round( math.acos( math.Clamp( self.posepositions.Pose0_Steerangle:Right():Dot( self.posepositions.Pose1_Steerangle:Right()),-1,1) ) * (180 / math.pi) , 2)
		self.VehicleData["steerangle"] = self.CustomWheels and self.CustomSteerAngle or math.max( Figure1, Figure2, Figure3 )

		local pFL = self.posepositions.Pose0_Pos_FL
		local pFR = self.posepositions.Pose0_Pos_FR
		local pRL = self.posepositions.Pose0_Pos_RL
		local pRR = self.posepositions.Pose0_Pos_RR
		local pAngL = self:WorldToLocalAngles( ( ( pFL + pFR ) / 2 - ( pRL + pRR ) / 2):Angle() )
		pAngL.r = 0
		pAngL.p = 0

		self.VehicleData["LocalAngForward"] = pAngL

		local yAngL = self.VehicleData.LocalAngForward - Angle( 0, 90, 0 )
		yAngL:Normalize()

		self.VehicleData["LocalAngRight"] = yAngL
		self.VehicleData["pp_spin_1"] = "vehicle_wheel_fl_spin"
		self.VehicleData["pp_spin_2"] = "vehicle_wheel_fr_spin"
		self.VehicleData["pp_spin_3"] = "vehicle_wheel_rl_spin"
		self.VehicleData["pp_spin_4"] = "vehicle_wheel_rr_spin"

		self.Turbo = CreateSound( self, "" )
		self.Blower = CreateSound( self, "" )
		self.BlowerWhine = CreateSound( self, "" )
		self.BlowOff = CreateSound( self, "" )

		local Health = math.floor( self.MaxHealth and self.MaxHealth or ( 1000 + self:GetPhysicsObject():GetMass() / 3 ) )
		self:SetMaxHealth( Health )
		self:SetCurHealth( Health )

		self:SetFastSteerAngle(self.FastSteeringAngle / self.VehicleData["steerangle"])
		self:SetNotSolid( false )
		self:SetupVehicle()
	end )
end

function ENT:SetupVehicle()
	local BaseMass = self:GetPhysicsObject():GetMass()
	local MassCenterOffset = self.CustomMassCenter or Vector()
	local BaseMassCenter = self:LocalToWorld( self:GetPhysicsObject():GetMassCenter() - MassCenterOffset )

	local OffsetMass = BaseMass * 0.25
	local CenterWheels = (self.posepositions["Pose1_Pos_FL"] + self.posepositions["Pose1_Pos_FR"] + self.posepositions["Pose1_Pos_RL"] + self.posepositions["Pose1_Pos_RR"]) / 4

	local Sub = CenterWheels - BaseMassCenter
	local Dir = Sub:GetNormalized()
	local Dist = Sub:Length()
	local DistAdd = BaseMass * Dist / OffsetMass

	local OffsetMassCenter = BaseMassCenter + Dir * ( Dist + DistAdd )

	local massOffset = ents.Create( "prop_physics" )
	self.MassOffset = massOffset

	massOffset:SetModel( "models/hunter/plates/plate.mdl" )
	massOffset:SetPos( OffsetMassCenter )
	massOffset:SetAngles( Angle() )
	massOffset:Spawn()
	massOffset:Activate()
	massOffset:GetPhysicsObject():EnableMotion(false)
	massOffset:GetPhysicsObject():SetMass( OffsetMass )
	massOffset:GetPhysicsObject():EnableDrag( false )
	massOffset:SetOwner( self )
	massOffset:DrawShadow( false )
	massOffset:SetNotSolid( true )
	massOffset:SetNoDraw( true )
	massOffset.DoNotDuplicate = true

	simfphys.SetOwner( self.EntityOwner, massOffset )

	local weld = constraint.Weld( massOffset, self, 0, 0, 0, true, true )
	weld.DoNotDuplicate = true

	local ballsack = constraint.AdvBallsocket(
		self.MassOffset,
		self,
		0,
		0,
		Vector(),
		Vector(),
		0,
		0,
		-0.01,
		-0.01,
		-0.01,
		0.01,
		0.01,
		0.01,
		0,
		0,
		0,
		0,
		1
	)
	ballsack.DoNotDuplicate = true

	if self.CustomWheels then
		if self.CustomWheelModel then
			if not file.Exists( self.CustomWheelModel, "GAME" ) then
				if IsValid( self.EntityOwner ) then
					self.EntityOwner:PrintMessage( HUD_PRINTTALK, "ERROR: \"" .. self.CustomWheelModel .. "\" does not exist! Removing vehicle. (Class: "..self:GetSpawn_List()..")")
				end

				self:Remove()
				return
			end

			if self.SteerFront ~= false then
				local steerMaster = ents.Create( "prop_physics" )
				self.SteerMaster = steerMaster

				steerMaster:SetModel( self.CustomWheelModel )
				steerMaster:SetPos( self:GetPos() )
				steerMaster:SetAngles( self:GetAngles() )
				steerMaster:Spawn()
				steerMaster:Activate()

				local pobj = steerMaster:GetPhysicsObject()

				if IsValid( pobj ) then
					pobj:EnableMotion( false )
				else
					if IsValid( self.EntityOwner ) then
						self.EntityOwner:PrintMessage( HUD_PRINTTALK, "ERROR: \"" .. self.CustomWheelModel .. "\" doesn't have an collision model! Removing vehicle. (Class: "..self:GetSpawn_List()..")")
					end

					steerMaster:Remove()
					self:Remove()

					return
				end

				steerMaster:SetOwner( self )
				steerMaster:DrawShadow( false )
				steerMaster:SetNotSolid( true )
				steerMaster:SetNoDraw( true )
				steerMaster.DoNotDuplicate = true
				self:DeleteOnRemove( steerMaster )
				simfphys.SetOwner( self.EntityOwner, steerMaster )
			end

			if self.SteerRear then
				local steerMaster2 = ents.Create( "prop_physics" )
				self.SteerMaster2 = steerMaster2

				steerMaster2:SetModel( self.CustomWheelModel )
				steerMaster2:SetPos( self:GetPos() )
				steerMaster2:SetAngles( self:GetAngles() )
				steerMaster2:Spawn()
				steerMaster2:Activate()

				local pobj = steerMaster2:GetPhysicsObject()
				if IsValid( pobj ) then
					pobj:EnableMotion( false )
				else
					if IsValid( self.EntityOwner ) then
						self.EntityOwner:PrintMessage( HUD_PRINTTALK, "ERROR: \"" .. self.CustomWheelModel .. "\" doesn't have an collision model! Removing vehicle. (Class: "..self:GetSpawn_List()..")")
					end

					steerMaster2:Remove()
					self:Remove()
					return
				end

				steerMaster2:SetOwner( self )
				steerMaster2:DrawShadow( false )
				steerMaster2:SetNotSolid( true )
				steerMaster2:SetNoDraw( true )
				steerMaster2.DoNotDuplicate = true
				self:DeleteOnRemove( steerMaster2 )
				simfphys.SetOwner( self.EntityOwner, steerMaster2 )
			end

			local steerMaster, steerMaster2 = self.SteerMaster, self.SteerMaster2

			local radius = IsValid( steerMaster ) and ( steerMaster:OBBMaxs() - steerMaster:OBBMins()) or ( steerMaster2:OBBMaxs() - steerMaster2:OBBMins() )
			self.FrontWheelRadius = self.FrontWheelRadius or math.max( radius.x, radius.y, radius.z ) * 0.5
			self.RearWheelRadius = self.RearWheelRadius or self.FrontWheelRadius

			self:CreateWheel( 1, WheelFL, self:LocalToWorld( self.CustomWheelPosFL ), self.FrontHeight, self.FrontWheelRadius, false , self:LocalToWorld( self.CustomWheelPosFL + Vector(0,0,self.CustomSuspensionTravel * 0.5) ),self.CustomSuspensionTravel, self.FrontConstant, self.FrontDamping, self.FrontRelativeDamping)
			self:CreateWheel( 2, WheelFR, self:LocalToWorld( self.CustomWheelPosFR ), self.FrontHeight, self.FrontWheelRadius, true , self:LocalToWorld( self.CustomWheelPosFR + Vector(0,0,self.CustomSuspensionTravel * 0.5) ),self.CustomSuspensionTravel, self.FrontConstant, self.FrontDamping, self.FrontRelativeDamping)
			self:CreateWheel( 3, WheelRL, self:LocalToWorld( self.CustomWheelPosRL ), self.RearHeight, self.RearWheelRadius, false , self:LocalToWorld( self.CustomWheelPosRL + Vector(0,0,self.CustomSuspensionTravel * 0.5) ),self.CustomSuspensionTravel, self.RearConstant, self.RearDamping, self.RearRelativeDamping)
			self:CreateWheel( 4, WheelRR, self:LocalToWorld( self.CustomWheelPosRR ), self.RearHeight, self.RearWheelRadius, true , self:LocalToWorld( self.CustomWheelPosRR + Vector(0,0,self.CustomSuspensionTravel * 0.5) ), self.CustomSuspensionTravel, self.RearConstant, self.RearDamping, self.RearRelativeDamping)

			if self.CustomWheelPosML then
				self:CreateWheel( 5, WheelML, self:LocalToWorld( self.CustomWheelPosML ), self.RearHeight, self.RearWheelRadius, false , self:LocalToWorld( self.CustomWheelPosML + Vector(0,0,self.CustomSuspensionTravel * 0.5) ),self.CustomSuspensionTravel, self.RearConstant, self.RearDamping, self.RearRelativeDamping)
			end

			if self.CustomWheelPosMR then
				self:CreateWheel( 6, WheelMR, self:LocalToWorld( self.CustomWheelPosMR ), self.RearHeight, self.RearWheelRadius, true , self:LocalToWorld( self.CustomWheelPosMR + Vector(0,0,self.CustomSuspensionTravel * 0.5) ), self.CustomSuspensionTravel, self.RearConstant, self.RearDamping, self.RearRelativeDamping)
			end
		else
			if IsValid( self.EntityOwner ) then
				self.EntityOwner:PrintMessage( HUD_PRINTTALK, "ERROR: no wheel model defined. Removing vehicle. (Class: "..self:GetSpawn_List()..")")
			end
			self:Remove()
		end
	else
		self:CreateWheel( 1, WheelFL, self:GetAttachment( self:LookupAttachment( "wheel_fl" ) ).Pos, self.FrontHeight, self.FrontWheelRadius, false , self.posepositions.Pose1_Pos_FL, self.VehicleData.suspensiontravel_fl, self.FrontConstant, self.FrontDamping, self.FrontRelativeDamping)
		self:CreateWheel( 2, WheelFR, self:GetAttachment( self:LookupAttachment( "wheel_fr" ) ).Pos, self.FrontHeight, self.FrontWheelRadius, true , self.posepositions.Pose1_Pos_FR, self.VehicleData.suspensiontravel_fr, self.FrontConstant, self.FrontDamping, self.FrontRelativeDamping)
		self:CreateWheel( 3, WheelRL, self:GetAttachment( self:LookupAttachment( "wheel_rl" ) ).Pos, self.RearHeight, self.RearWheelRadius, false , self.posepositions.Pose1_Pos_RL, self.VehicleData.suspensiontravel_rl, self.RearConstant, self.RearDamping, self.RearRelativeDamping)
		self:CreateWheel( 4, WheelRR, self:GetAttachment( self:LookupAttachment( "wheel_rr" ) ).Pos, self.RearHeight, self.RearWheelRadius, true , self.posepositions.Pose1_Pos_RR, self.VehicleData.suspensiontravel_rr, self.RearConstant, self.RearDamping, self.RearRelativeDamping)
	end

	timer.Simple( 0.01, function()
		if not istable( self.Wheels ) then return end

		for i = 1, #self.Wheels do
			local Ent = self.Wheels[ i ]
			
			if IsValid( Ent ) then
				local PhysObj = Ent:GetPhysicsObject()

				if IsValid( PhysObj ) then
					PhysObj:EnableMotion( true )
				end
			end
		end

		timer.Simple( 0.05, function()
			if not IsValid( self ) then return end

			self:GetPhysicsObject():EnableMotion( true )

			local PhysObj = self.MassOffset:GetPhysicsObject()
			if IsValid( PhysObj ) then
				PhysObj:EnableMotion(true)
			end
		end )
	end )

	self.VehicleData.filter = table.Copy( self.Wheels )
	table.insert( self.VehicleData.filter, self )

	self.EnableSuspension = 1
	self:OnSpawn()
	hook.Run( "simfphysOnSpawn", self )
end

function ENT:CreateWheel(index, name, attachmentpos, height, radius, swap_y , poseposition, suspensiontravel, constant, damping, rdamping)
	local fAng = self:LocalToWorldAngles( self.VehicleData.LocalAngForward )
	local rAng = self:LocalToWorldAngles( self.VehicleData.LocalAngRight )

	local Forward = fAng:Forward()
	local Right = swap_y and -rAng:Forward() or rAng:Forward()
	local Up = self:GetUp()

	local RopeLength = 150
	local LimiterLength = 60
	local LimiterRopeLength = math.sqrt( (suspensiontravel * 0.5) ^ 2 + LimiterLength ^ 2 )
	local WheelMass = self.Mass / 32

	if self.FrontWheelMass and (index == 1 or index == 2) then
		WheelMass = self.FrontWheelMass
	end
	if self.RearWheelMass and (index == 3 or index == 4 or index == 5 or index == 6) then
		WheelMass = self.RearWheelMass
	end

	self.name = ents.Create( "gmod_sent_vehicle_fphysics_wheel" )
	self.name:SetPos( attachmentpos - Up * height)
	self.name:SetAngles( fAng )
	self.name:Spawn()
	self.name:Activate()
	self.name:PhysicsInitSphere( radius, "jeeptire" )
	self.name:SetCollisionBounds( Vector(-radius,-radius,-radius), Vector(radius,radius,radius) )
	self.name:GetPhysicsObject():EnableMotion(false)
	self.name:GetPhysicsObject():SetMass( WheelMass )
	self.name:SetBaseEnt( self )
	simfphys.SetOwner( self.EntityOwner, self.name )
	self.name.EntityOwner = self.EntityOwner
	self.name.Index = index
	self.name.Radius = radius

	if self.CustomWheels then
		local Model = ( self.CustomWheelModel_R and (index == 3 or index == 4 or index == 5 or index == 6)) and self.CustomWheelModel_R or self.CustomWheelModel
		local ghostAng = Right:Angle()
		local mirAng = swap_y and 1 or -1
		ghostAng:RotateAroundAxis( Forward, self.CustomWheelAngleOffset.p * mirAng )
		ghostAng:RotateAroundAxis( Right, self.CustomWheelAngleOffset.r * mirAng )
		ghostAng:RotateAroundAxis( Up, -self.CustomWheelAngleOffset.y )

		local Camber = self.CustomWheelCamber or 0
		ghostAng:RotateAroundAxis( Forward, Camber * mirAng )

		self.GhostWheels[index] = ents.Create( "gmod_sent_vehicle_fphysics_attachment" )
		self.GhostWheels[index]:SetModel( Model )
		self.GhostWheels[index]:SetPos( self.name:GetPos() )
		self.GhostWheels[index]:SetAngles( ghostAng )
		self.GhostWheels[index]:SetOwner( self )
		self.GhostWheels[index]:Spawn()
		self.GhostWheels[index]:Activate()
		self.GhostWheels[index]:SetNotSolid( true )
		self.GhostWheels[index].DoNotDuplicate = true
		self.GhostWheels[index]:SetParent( self.name )
		self:DeleteOnRemove( self.GhostWheels[index] )
		simfphys.SetOwner( self.EntityOwner, self.GhostWheels[index] )

		self.GhostWheels[index]:SetRenderMode( RENDERMODE_TRANSALPHA )

		if self.ModelInfo then
			if self.ModelInfo.WheelColor then
				self.GhostWheels[index]:SetColor( self.ModelInfo.WheelColor )
			end
		end

		self.name.GhostEnt = self.GhostWheels[index]

		local nocollide = constraint.NoCollide(self,self.name,0,0)
		nocollide.DoNotDuplicate = true
	end

	local targetentity = self
	if self.CustomWheels then
		if index == 1 or index == 2 then
			targetentity = self.SteerMaster or self
		end
		if index == 3 or index == 4 then
			targetentity = self.SteerMaster2 or self
		end
	end


	-- Ballsocket
	constraint.AdvBallsocket(
		targetentity,
		self.name,
		0,
		0,
		Vector(),
		Vector(),
		0,
		0,
		-0.01,
		-0.01,
		-0.01,
		0.01,
		0.01,
		0.01,
		0,
		0,
		0,
		1,
		1
	).DoNotDuplicate = true
	
	-- Rope1
	constraint.Rope(
		self,
		self.name,
		0,
		0,
		self:WorldToLocal( self.name:GetPos() + Forward * RopeLength * 0.5 + Right * RopeLength ),
		Vector(),
		Vector( RopeLength * 0.5, RopeLength, 0 ):Length(),
		0,
		0,
		0,
		"cable/cable2",
		true
	).DoNotDuplicate = true
	
	-- Rope2
	constraint.Rope(
		self,
		self.name,
		0,
		0,
		self:WorldToLocal( self.name:GetPos() - Forward * RopeLength * 0.5 + Right * RopeLength ),
		Vector(),
		Vector( RopeLength * 0.5,RopeLength, 0 ):Length(),
		0,
		0,
		0,
		"cable/cable2",
		true
	).DoNotDuplicate = true


	if self.StrengthenSuspension then
		-- Rope3
		constraint.Rope(
			self,
			self.name,
			0,
			0,
			self:WorldToLocal( poseposition - Up * suspensiontravel * 0.5 + Right * LimiterLength ),
			Vector(),
			LimiterRopeLength * 0.99,
			0,
			0,
			0,
			"cable/cable2",
			false
		).DoNotDuplicate = true
		
		-- Rope4
		constraint.Rope(
			self,
			self.name,
			0,
			0,
			self:WorldToLocal( poseposition - Up * suspensiontravel * 0.5 - Right * LimiterLength ),
			Vector(),
			LimiterRopeLength,
			0,
			0,
			0,
			"cable/cable2",
			false
		).DoNotDuplicate = true


		local elastic1 = constraint.Elastic(
			self.name,
			self,
			0,
			0,
			Vector( 0, 0, height ),
			self:WorldToLocal( self.name:GetPos() ),
			constant * 0.5,
			damping * 0.5,
			rdamping * 0.5,
			"cable/cable2",
			0,
			false
		)

		local elastic2 = constraint.Elastic(
			self.name,
			self,
			0,
			0,
			Vector( 0, 0, height ),
			self:WorldToLocal( self.name:GetPos() ),
			constant * 0.5,
			damping * 0.5,
			rdamping * 0.5,
			"cable/cable2",
			0,
			false
		)


		elastic1.DoNotDuplicate = true
		elastic2.DoNotDuplicate = true

		self.Elastics[index] = elastic1
		self.Elastics[index * 10] = elastic2
	else
		-- Rope3
		constraint.Rope(
			self,
			self.name,
			0,
			0,
			self:WorldToLocal( poseposition - Up * suspensiontravel * 0.5 + Right * LimiterLength ),
			Vector(),
			LimiterRopeLength,
			0,
			0,
			0,
			"cable/cable2",
			false
		).DoNotDuplicate = true


		local elastic = constraint.Elastic(
			self.name,
			self,
			0,
			0,
			Vector( 0, 0, height ),
			self:WorldToLocal( self.name:GetPos() ),
			constant,
			damping,
			rdamping,
			"cable/cable2",
			0,
			false
		)

		elastic.DoNotDuplicate = true
		self.Elastics[index] = elastic
	end

	self.Wheels[index] = self.name

	if index == 2 then
		if IsValid( self.Wheels[1] ) and IsValid( self.Wheels[2] ) then
			local nocollide = constraint.NoCollide( self.Wheels[1], self.Wheels[2], 0, 0 )
			nocollide.DoNotDuplicate = true
		end

	elseif index == 4 then
		if IsValid( self.Wheels[3] ) and IsValid( self.Wheels[4] ) then
			local nocollide = constraint.NoCollide( self.Wheels[3], self.Wheels[4], 0, 0 )
			nocollide.DoNotDuplicate = true
		end

	elseif index == 6 then
		if IsValid( self.Wheels[5] ) and IsValid( self.Wheels[6] ) then
			local nocollide = constraint.NoCollide( self.Wheels[5], self.Wheels[6], 0, 0 )
			nocollide.DoNotDuplicate = true
		end
	end
end
