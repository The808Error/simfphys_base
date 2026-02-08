local HULL_SIZE = Vector( 18, 18, 0 )

local function exitUsingMyTraces( ent, ply, b_ent )
	local center = b_ent:LocalToWorld( b_ent:OBBcenter() )
	local vel = b_ent:GetVelocity()
	local radius = b_ent:BoundingRadius()
	local filter1 = { ent, ply }
	local filter2 = { ent, ply, b_ent }

	do
		local wheels = b_ent.Wheels
		
		for i = 1, #wheels do
			filter1[#filter1 + 1] = wheels[i]
			filter2[#filter2 + 1] = wheels[i]
		end
	end


	if vel:Length() > 250 then
		local pos = b_ent:GetPos()
		local dir = vel:GetNormalized()
		local targetpos = pos - dir * ( radius + 40 )

		local tr = util.TraceHull{
			start = center,
			endpos = targetpos - Vector(0,0,10),
			maxs = HULL_SIZE,
			mins = -HULL_SIZE,
			filter = filter2
		}

		local exitpoint = tr.HitPos + Vector(0,0,10)

		if util.IsInWorld( exitpoint ) then
			ply:SetPos( exitpoint )
			ply:SetEyeAngles( ( pos - exitpoint ):Angle() )
		end
	else
		local pos = ent:GetPos()
		local targetpos = (pos + ent:GetRight() * 80)

		local tr1 = util.TraceLine{
			start = targetpos,
			endpos = targetpos - Vector(0,0,100),
			filter = {}
		}
		local tr2 = util.TraceHull{
			start = targetpos,
			endpos = targetpos + Vector(0,0,80),
			maxs = HULL_SIZE,
			mins = -HULL_SIZE,
			filter = filter1
		}
		local traceto = util.TraceLine{
			start = center,
			endpos = targetpos,
			filter = filter2
		}

		local hitGround = tr1.Hit
		local hitWall = tr2.Hit or traceto.Hit

		local check0 = ( hitWall or hitGround == false or util.IsInWorld( targetpos ) == false ) and ( pos - ent:GetRight() * 80 ) or targetpos
		local tr = util.TraceHull{
			start = check0,
			endpos = check0 + Vector(0,0,80),
			maxs = HULL_SIZE,
			mins = -HULL_SIZE,
			filter = filter1
		}
		local traceto = util.TraceLine{
			start = center,
			endpos = check0,
			filter = filter2
		}

		hitWall = tr.Hit or traceto.hit
		local check1 = ( hitWall or hitGround == false or util.IsInWorld( check0 ) == false ) and ( pos + ent:GetUp() * 100 ) or check0


		local tr = util.TraceHull{
			start = check1,
			endpos = check1 + Vector(0,0,80),
			maxs = HULL_SIZE,
			mins = -HULL_SIZE,
			filter = filter1
		}
		local traceto = util.TraceLine{
			start = center,
			endpos = check1,
			filter = filter2
		}

		hitWall = tr.Hit or traceto.hit
		local check2 = ( hitWall or util.IsInWorld( check1 ) == false ) and ( pos - ent:GetUp() * 100 ) or check1

		local tr = util.TraceHull{
			start = check2,
			endpos = check2 + Vector(0,0,80),
			maxs = HULL_SIZE,
			mins = -HULL_SIZE,
			filter = filter1
		}
		local traceto = util.TraceLine{
			start = center,
			endpos = check2,
			filter = filter2
		}
		hitWall = tr.Hit or traceto.hit
		local check3 = ( hitWall or util.IsInWorld( check2 ) == false ) and b_ent:LocalToWorld( Vector( 0, radius, 0 ) ) or check2


		local tr = util.TraceHull{
			start = check3,
			endpos = check3 + Vector(0,0,80),
			maxs = HULL_SIZE,
			mins = -HULL_SIZE,
			filter = filter1
		}
		local traceto = util.TraceLine{
			start = center,
			endpos = check3,
			filter = filter2
		}

		hitWall = tr.Hit or traceto.hit
		local check4 = ( hitWall or util.IsInWorld( check3 ) == false ) and b_ent:LocalToWorld( Vector( 0, -radius, 0 ) ) or check3


		local tr = util.TraceHull{
			start = check4,
			endpos = check4 + Vector(0,0,80),
			maxs = HULL_SIZE,
			mins = -HULL_SIZE,
			filter = filter1
		}
		local traceto = util.TraceLine{
			start = center,
			endpos = check4,
			filter = filter2
		}

		hitWall = tr.Hit or traceto.hit
		local exitpoint = ( hitWall or util.IsInWorld( check4 ) == false ) and b_ent:GetPos() or check4

		if util.IsInWorld( exitpoint ) then
			ply:SetPos( exitpoint )
			ply:SetEyeAngles( ( pos - exitpoint ):Angle() )
		end
	end
end

local function ExitUsingAttachments( ent, ply, b_ent )
	local center = b_ent:LocalToWorld( b_ent:OBBcenter() )
	local Filter = { ent, ply, b_ent }
	local LinkedDoorAnims = b_ent.ModelInfo and b_ent.ModelInfo.LinkDoorAnims

	local wheels = b_ent.Wheels
	for i = 1, #wheels do
		filter[#filter + 1] = wheels[i]
	end

	local IsDriverSeat = ent == b_ent:GetDriverSeat()

	if IsDriverSeat then
		if LinkedDoorAnims then
			for i in pairs( b_ent.ModelInfo.LinkDoorAnims ) do
				print( "LinkedDoorAnims: " .. type( i ) .. " " .. i ) 
				local seq_att = b_ent.ModelInfo.LinkDoorAnims[ i ].exit
				local attachmentdata = b_ent:GetAttachment( b_ent:LookupAttachment( i ) )

				if attachmentdata then
					local targetpos = attachmentdata.Pos
					local targetang = attachmentdata.Ang
					targetang.r = 0

					local tr = util.TraceLine{
						start = center,
						endpos = targetpos,
						filter = Filter
					}

					if not tr.Hit or util.IsInWorld( targetpos ) then
						ply:SetPos( targetpos )
						ply:SetEyeAngles( targetang )
						b_ent:PlayAnimation( seq_att )
						b_ent:ForceLightsOff()

						return
					end
				end
			end
		else
			for i = 1, #b_ent.Exitpoints do
				local seq_att = b_ent.Exitpoints[i]
				local attachmentdata = b_ent:GetAttachment( b_ent:LookupAttachment( seq_att ) )
				if attachmentdata then
					local targetpos = attachmentdata.Pos
					local targetang = attachmentdata.Ang
					targetang.r = 0

					local tr = util.TraceLine{
						start = center,
						endpos = targetpos,
						filter = Filter
					}
					local Hit = tr.Hit
					local InWorld = util.IsInWorld( targetpos )
					local IsBlocked = Hit or not InWorld

					if not IsBlocked then
						ply:SetPos( targetpos )
						ply:SetEyeAngles( targetang )
						b_ent:PlayAnimation( seq_att )
						b_ent:ForceLightsOff()

						return
					end
				end
			end
		end
	end

	exitUsingMyTraces( ent, ply, b_ent )
end

local function exitVehicleSimple( ent, ply, b_ent )
	-- No need to check if the parameters are valid, because its handled below

	if b_ent.Exitpoints and b_ent:GetVelocity():Length() < 250 then
		ExitUsingAttachments( ent, ply, b_ent )
	else
		exitUsingMyTraces( ent, ply, b_ent )
	end
end

 local function handleVehicleExit( ply, vehicle )
	if not IsValid( ply ) then return end

	local vehicle = ply:GetVehicle()

	if not IsValid( vehicle ) then return end

	if vehicle.fphysSeat then
		local base = vehicle.base
		exitVehicleSimple( vehicle, ply, base )
	end
end


hook.Add( "PlayerLeaveVehicle", "simfphysVehicleExit", handleVehicleExit )
