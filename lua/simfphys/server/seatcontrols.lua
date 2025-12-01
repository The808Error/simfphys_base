util.AddNetworkString( "simfphys_mousesteer" )
util.AddNetworkString( "simfphys_blockcontrols" )

local IsValid = IsValid

net.Receive( "simfphys_mousesteer", function( _, ply )
	if not ply:IsDrivingSimfphys() then return end

	local vehicle = net.ReadEntity()
	local Steer = net.ReadInt( 9 )

	Steer = Steer / 255

	if not IsValid( vehicle ) or ply:GetSimfphys() ~= vehicle:GetParent() then return end

	vehicle.ms_Steer = Steer
end )

net.Receive( "simfphys_blockcontrols", function( _, ply )
	if not IsValid( ply ) then return end

	ply.blockcontrols = net.ReadBool()
end )

hook.Add( "PlayerButtonDown", "!!!simfphysButtonDown", function( ply, button )
	local vehicle = ply:GetSimfphys()

	if not IsValid( vehicle ) then return end
	local driver = vehicle:GetDriver()

	if button == KEY_1 then
		-- Locking/Unlocking the vehicle
		if ply == driver then
			if vehicle:GetIsVehicleLocked() then
				vehicle:UnLock()
			else
				vehicle:Lock()
			end
		elseif not IsValid( driver ) then
			-- Switching to the driver seat
			ply:ExitVehicle()

			local driverSeat = vehicle:GetDriverSeat()
			if not IsValid( driverSeat ) then return end

			timer.Simple( FrameTime(), function()
				if not IsValid( vehicle ) or not IsValid( ply ) then return end
				if IsValid( vehicle:GetDriver() ) or not IsValid( driverSeat ) then return end

				ply:EnterVehicle( driverSeat )

				timer.Simple( FrameTime() * 2, function()
					if not IsValid( ply ) or not IsValid( vehicle ) then return end
					ply:SetEyeAngles( Angle( 0, vehicle:GetAngles().y, 0 ) )
				end )
			end )
		end
	else
		for _, pod in ipairs( vehicle:GetPassengerSeats() ) do
			if not IsValid( pod ) then continue end
			if pod:GetNWInt( "pPodIndex", 3 ) == simfphys.pSwitchKeys[button] and not IsValid( pod:GetDriver() ) then
				ply:ExitVehicle()

				timer.Simple( FrameTime(), function()
					if not IsValid( pod ) or not IsValid( ply ) then return end
					if IsValid( pod:GetDriver() ) then return end

					ply:EnterVehicle( pod )
				end )
			end
		end
	end
end )
