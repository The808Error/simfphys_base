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
			
			local driverSeat = vehicle:GetDriverSeat()
			if not IsValid( driverSeat ) then return end

			ply:ExitVehicle()
			ply:EnterVehicle( driverSeat )

			ply:SetEyeAngles( Angle( 0, vehicle:GetAngles().y - driverSeat:GetAngles().y, 0 ) )
		end
	else
		-- Switch to passenger seat
		for _, pod in ipairs( vehicle:GetPassengerSeats() ) do
			if not IsValid( pod ) then continue end
			if IsValid( pod:GetDriver() ) then continue end

			if pod:GetNWInt( "pPodIndex", 3 ) == simfphys.pSwitchKeys[button] then
				ply:ExitVehicle()
				ply:EnterVehicle( pod )
			end
		end
	end
end )
