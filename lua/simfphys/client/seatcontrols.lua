hook.Add( "InitPostEntity", "simfphys_MouseCheckerInit", function()
	local previousState = false

	timer.Create( "simfphys_mouseStateCheck", 0.25, 0, function()
		if not LocalPlayer():InVehicle() then return end

		local current = vgui.CursorVisible()
		if current == previousState then return end

		previousState = current
		
		net.Start( "simfphys_blockcontrols" )
		net.WriteBool( current )
		net.SendToServer()
	end )
end )
