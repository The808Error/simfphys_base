local checkinterval = 3
local NextCheck = CurTime() + checkinterval

local mat = Material( "sprites/light_ignorez" )
local mat2 = Material( "sprites/light_glow02_add_noz" )

if file.Exists( "materials/sprites/glow_headlight_ignorez.vmt", "GAME" ) then
    mat2 = Material( "sprites/glow_headlight_ignorez" )
end

local SpritesDisabled = false
local FrontProjectedLights = true
local RearProjectedLights = true
local Shadows = false
local vehiclesTable = {}

local IsValid = IsValid

cvars.AddChangeCallback( "cl_simfphys_hidesprites", function( _, _, newValue ) SpritesDisabled = tonumber( newValue ) ~= 0 end)
cvars.AddChangeCallback( "cl_simfphys_frontlamps", function( _, _, newValue ) FrontProjectedLights = tonumber( newValue ) ~= 0 end)
cvars.AddChangeCallback( "cl_simfphys_rearlamps", function( _, _, newValue ) RearProjectedLights = tonumber( newValue ) ~= 0 end)
cvars.AddChangeCallback( "cl_simfphys_shadows", function( _, _, newValue ) Shadows = tonumber( newValue ) ~= 0 end)


SpritesDisabled = GetConVar( "cl_simfphys_hidesprites" ):GetBool()

FrontProjectedLights = GetConVar( "cl_simfphys_frontlamps" ):GetBool()

RearProjectedLights = GetConVar( "cl_simfphys_rearlamps" ):GetBool()

Shadows = GetConVar( "cl_simfphys_shadows" ):GetBool()


local groups, mygroup

local function bodyGroupIsValid( bodygroups, entity )
    --for i, groups in ipairs( bodygroups ) do
    for i = 1, #bodygroups do
        groups = bodygroups[i]
        mygroup = entity:GetBodygroup( i )

        for i2 = 1, #groups do
            if mygroup == groups[i2] then
                return true
            end
        end
    end

    return false
end

local function UpdateSubMats( ent, entTable, Lowbeam, Highbeam, IsBraking, IsReversing )
    if not entTable.SubMaterials then return end

    if entTable.SubMaterials.turnsignals then
        local IsTurningLeft = entTable.signal_left
        local IsTurningRight = entTable.signal_right
        local IsFlashing = ent:GetFlasher() == 1

        if entTable.WasTurningLeft ~= IsTurningLeft or entTable.WasTurningRight ~= IsTurningRight or entTable.WasFlashing ~= IsFlashing then
            if entTable.SubMaterials.turnsignals.left then
                for k,v in pairs( entTable.SubMaterials.turnsignals.left ) do
                    local mat = (IsFlashing and IsTurningLeft) and v or ""
                    ent:SetSubMaterial( k, mat )
                end
            end
            if entTable.SubMaterials.turnsignals.right then
                for k,v in pairs( entTable.SubMaterials.turnsignals.right ) do
                    local mat = (IsFlashing and IsTurningRight) and v or ""
                    ent:SetSubMaterial( k, mat )
                end
            end

            entTable.WasTurningLeft = IsTurningLeft
            entTable.WasTurningRight = IsTurningRight
            entTable.WasFlashing = IsFlashing
        end
    end

    if entTable.WasReversing == IsReversing and entTable.WasBraking == IsBraking and entTable.WasLowbeam == Lowbeam and entTable.WasHighbeam == Highbeam then return end

    if Lowbeam then
        if Highbeam then
            if entTable.SubMaterials.on_highbeam then
                if not IsReversing and not IsBraking then
                    if entTable.SubMaterials.on_highbeam.Base then
                        for k,v in pairs( entTable.SubMaterials.on_highbeam.Base ) do
                            ent:SetSubMaterial( k, v )
                        end
                    end
                elseif IsBraking then
                    if IsReversing then
                        if entTable.SubMaterials.on_highbeam.Brake_Reverse then
                            for k,v in pairs( entTable.SubMaterials.on_highbeam.Brake_Reverse ) do
                                ent:SetSubMaterial( k, v )
                            end
                        end
                    else
                        if entTable.SubMaterials.on_highbeam.Brake then
                            for k,v in pairs( entTable.SubMaterials.on_highbeam.Brake ) do
                                ent:SetSubMaterial( k, v )
                            end
                        end
                    end
                else
                    if entTable.SubMaterials.on_highbeam.Reverse then
                        for k,v in pairs( entTable.SubMaterials.on_highbeam.Reverse ) do
                            ent:SetSubMaterial( k, v )
                        end
                    end
                end
            end
        else
            if entTable.SubMaterials.on_lowbeam then
                if not IsReversing and not IsBraking then
                    if entTable.SubMaterials.on_lowbeam.Base then
                        for k,v in pairs( entTable.SubMaterials.on_lowbeam.Base ) do
                            ent:SetSubMaterial( k, v )
                        end
                    end
                elseif IsBraking then
                    if IsReversing then
                        if entTable.SubMaterials.on_lowbeam.Brake_Reverse then
                            for k,v in pairs( entTable.SubMaterials.on_lowbeam.Brake_Reverse ) do
                                ent:SetSubMaterial( k, v )
                            end
                        end
                    else
                        if entTable.SubMaterials.on_lowbeam.Brake then
                            for k,v in pairs( entTable.SubMaterials.on_lowbeam.Brake ) do
                                ent:SetSubMaterial( k, v )
                            end
                        end
                    end
                else
                    if entTable.SubMaterials.on_lowbeam.Reverse then
                        for k,v in pairs( entTable.SubMaterials.on_lowbeam.Reverse ) do
                            ent:SetSubMaterial( k, v )
                        end
                    end
                end
            end
        end
    else
        if entTable.SubMaterials.off then
            if not IsReversing and not IsBraking then
                if entTable.SubMaterials.off.Base then
                    for k,v in pairs( entTable.SubMaterials.off.Base ) do
                        ent:SetSubMaterial( k, v )
                    end
                end
            elseif IsBraking then
                if IsReversing then
                    if entTable.SubMaterials.off.Brake_Reverse then
                        for k,v in pairs( entTable.SubMaterials.off.Brake_Reverse ) do
                            ent:SetSubMaterial( k, v )
                        end
                    end
                else
                    if entTable.SubMaterials.off.Brake then
                        for k,v in pairs( entTable.SubMaterials.off.Brake ) do
                            ent:SetSubMaterial( k, v )
                        end
                    end
                end
            else
                if entTable.SubMaterials.off.Reverse then
                    for k,v in pairs( entTable.SubMaterials.off.Reverse ) do
                        ent:SetSubMaterial( k, v )
                    end
                end
            end
        end
    end

    entTable.WasReversing = IsReversing
    entTable.WasBraking = IsBraking
    entTable.WasLowbeam = Lowbeam
    entTable.WasHighbeam = Highbeam
end

local function ManageProjTextures()
    if not vehiclesTable then return end

    local entTable
    local vel

    local frametime = RealFrameTime()

    for i, ent in ipairs( vehiclesTable ) do
        if not IsValid( ent ) then
            vehiclesTable[i] = nil

            continue
        end

        if ent:IsDormant() then continue end


        entTable = ent:GetTable()
        vel = ent:GetVelocity() * frametime

        entTable.triggers = {
            [1] = ent:GetLightsEnabled(),
            [2] = ent:GetLampsEnabled(),
            [3] = ent:GetFogLightsEnabled(),
            [4] = ent:GetIsBraking(),
            [5] = ent:GetGear() == 1,
            [6] = entTable.signal_left,
            [7] = entTable.signal_right,
            [8] = ent:GetIsBraking(),
            [9] = ent:GetIsBraking(),
        }

        UpdateSubMats( ent, entTable, entTable.triggers[1], entTable.triggers[2], entTable.triggers[4], entTable.triggers[5] )

        for _, proj in pairs( entTable.simfphys_projectedTextures ) do
            local trigger = entTable.triggers[proj.trigger]
            local enable = entTable.triggers[1] or trigger

            if proj.Damaged or ( proj.trigger == 2 and not FrontProjectedLights ) or ( proj.trigger == 4 and not RearProjectedLights ) then
                trigger = false
                enable = false
            end

            if entTable.HasSpecialTurnSignals then
                if proj.trigger == 4 and ( entTable.triggers[6] or entTable.triggers[7] ) then
                    trigger = false
                end
            end

            if proj.Active ~= enable then
                proj.Active = enable

                if enable then
                    proj.istriggered = trigger
                    local brightness = ( trigger and proj.ontrigger.brightness ) or proj.brightness

                    local lamp = ProjectedTexture()
                    lamp:SetBrightness( brightness )
                    lamp:SetTexture( proj.mat )
                    lamp:SetColor( proj.col )
                    lamp:SetEnableShadows( Shadows )
                    lamp:SetFarZ( proj.FarZ )
                    lamp:SetNearZ( proj.NearZ )
                    lamp:SetFOV( proj.Fov )

                    proj.lamp = lamp
                elseif IsValid( proj.lamp ) then
                    proj.lamp:Remove()
                    proj.lamp = nil
                end
            end

            if IsValid( proj.lamp ) then
                local pos = ent:LocalToWorld( proj.pos )
                local ang = ent:LocalToWorldAngles( proj.ang )

                if proj.istriggered ~= trigger then
                    proj.istriggered = trigger

                    if proj.ontrigger.brightness then
                        local brightness = trigger and proj.ontrigger.brightness or proj.brightness
                        proj.lamp:SetBrightness( brightness )
                    end

                    if proj.ontrigger.mat then
                        local mat = trigger and proj.ontrigger.mat or proj.mat
                        proj.lamp:SetTexture( mat )
                    end

                    if proj.ontrigger.FarZ then
                        local FarZ = trigger and proj.ontrigger.FarZ or proj.FarZ
                        proj.lamp:SetFarZ( FarZ )
                    end
                end

                proj.lamp:SetPos( pos + vel )
                proj.lamp:SetAngles( ang )
                proj.lamp:Update()
            end
        end
    end
end


local CLR_LIGHTS = Color( 220, 205, 160 )
local CLR_LIGHTS_MODERN = Color( 215, 240, 255 )

local CLR_LIGHTS_REAR = Color( 30, 0, 0 )

local function SetupProjectedTextures( ent, vehiclelist )
    local projectedTextures = {}
    ent.simfphys_projectedTextures = projectedTextures

    local proj_col = vehiclelist.ModernLights and CLR_LIGHTS_MODERN or CLR_LIGHTS

    if vehiclelist.L_HeadLampPos and vehiclelist.L_HeadLampAng then
        projectedTextures.FL = {
            trigger = 2,
            ontrigger = {
                mat = "effects/flashlight/headlight_highbeam",
                FarZ = 3000,
                brightness = 2.5,
            },
            pos = vehiclelist.L_HeadLampPos,
            ang = vehiclelist.L_HeadLampAng,
            mat = "effects/flashlight/headlight_lowbeam",
            col = proj_col,
            brightness = 2,
            FarZ = 1000,
            NearZ = 75,
            Fov = 80,
        }
    end

    if vehiclelist.R_HeadLampPos and vehiclelist.R_HeadLampAng then
        projectedTextures.FR = {
            trigger = 2,
            ontrigger = {
                mat = "effects/flashlight/headlight_highbeam",
                FarZ = 3000,
                brightness = 2.5,
            },
            pos = vehiclelist.R_HeadLampPos,
            ang = vehiclelist.R_HeadLampAng,
            mat = "effects/flashlight/headlight_lowbeam",
            col = proj_col,
            brightness = 2,
            FarZ = 1000,
            NearZ = 75,
            Fov = 80,
        }
    end

    if vehiclelist.L_RearLampPos and vehiclelist.L_RearLampAng then
        projectedTextures.RL = {
            trigger = 4,
            ontrigger = {
                brightness = 1,
            },
            pos = vehiclelist.L_RearLampPos,
            ang = vehiclelist.L_RearLampAng,
            mat = "effects/flashlight/soft",
            col = CLR_LIGHTS_REAR,
            brightness = 0.2,
            FarZ = 80,
            NearZ = 45,
            Fov = 140,
        }
    end

    if vehiclelist.R_RearLampPos and vehiclelist.R_RearLampAng then
        projectedTextures.RR = {
            trigger = 4,
            ontrigger = {
                brightness = 1,
            },
            pos = vehiclelist.R_RearLampPos,
            ang = vehiclelist.R_RearLampAng,
            mat = "effects/flashlight/soft",
            col = CLR_LIGHTS_REAR,
            brightness = 0.2,
            FarZ = 80,
            NearZ = 45,
            Fov = 140,
        }
    end

    ent:CallOnRemove( "remove_projected_textures", function()
        for _, proj in pairs( projectedTextures ) do
            local lamp = proj.lamp

            if IsValid( lamp ) then
                lamp:Remove()
            end
        end
    end)
end

local function SetUpLights( vehName, ent )
    local sprites = {}
    ent.simfphys_sprites = sprites

    local vehiclelist = list.Get( "simfphys_lights" )[vehName]
    if not vehiclelist then
        ent.SubMaterials = false
        
        return
    end

    ent.LightsEMS = vehiclelist.ems_sprites or false
    local hl_col = vehiclelist.ModernLights and { 215, 240, 255 } or { 220, 205, 160 }

    SetupProjectedTextures( ent , vehiclelist )

    if not vehiclelist or not vehiclelist.SubMaterials then
        ent.SubMaterials = false
    else
        ent.SubMaterials = vehiclelist.SubMaterials
    end

    if vehiclelist.ems_sprites then
        ent.PixVisEMS = {}
        for i = 1, #vehiclelist.ems_sprites do
            ent.PixVisEMS[i] = util.GetPixelVisibleHandle()

            ent.LightsEMS[i].material = ent.LightsEMS[i].material and Material( ent.LightsEMS[i].material ) or mat2
        end
    end

    if vehiclelist.Headlight_sprites then
        for _, data in pairs( vehiclelist.Headlight_sprites ) do
            local s = {}
            s.PixVis = util.GetPixelVisibleHandle()
            s.trigger = 1

            if not isvector(data) then
                s.color = data.color and data.color or Color( hl_col[1], hl_col[2], hl_col[3],  255)
                s.material = data.material and Material( data.material ) or mat2
                s.size = data.size and data.size or 16
                s.pos = data.pos
                if (data.OnBodyGroups) then s.bodygroups = data.OnBodyGroups end
                sprites[#sprites + 1] = s
            else
                s.pos = data
                s.color = Color( hl_col[1], hl_col[2], hl_col[3],  255)
                s.material = mat
                s.size = 16
                sprites[#sprites + 1] = s

                local s2 = {}
                s2.PixVis = util.GetPixelVisibleHandle()
                s2.trigger = s.trigger
                s2.pos = data
                s2.color = Color( hl_col[1], hl_col[2], hl_col[3],  150)
                s2.material = mat2
                s2.size = 64
                sprites[#sprites + 1] = s2
            end
        end
    end

    if vehiclelist.Rearlight_sprites then
        for _, data in pairs( vehiclelist.Rearlight_sprites ) do
            local s = {}
            s.PixVis = util.GetPixelVisibleHandle()
            s.trigger = 1

            if not isvector(data) then
                s.color = data.color and data.color or Color( 255, 0, 0,  125)
                s.material = data.material and Material( data.material ) or mat2
                s.size = data.size and data.size or 16
                s.pos = data.pos
                if (data.OnBodyGroups) then s.bodygroups = data.OnBodyGroups end
                sprites[#sprites + 1] = s
            else
                local s2 = {}
                s2.PixVis = util.GetPixelVisibleHandle()
                s2.trigger = s.trigger
                s2.pos = data
                s2.color = Color( 255, 120, 0,  125 )
                s2.material = mat2
                s2.size = 12
                sprites[#sprites + 1] = s2

                s.pos = data
                s.color = Color( 255, 0, 0,  90 )
                s.material = mat
                s.size = 32
                sprites[#sprites + 1] = s
            end
        end
    end

    -- Brakelights
    if vehiclelist.Brakelight_sprites then
        for _, data in ipairs( vehiclelist.Brakelight_sprites ) do
            local s = {}
            s.PixVis = util.GetPixelVisibleHandle()
            s.trigger = 4

            if not isvector(data) then
                s.color = data.color and data.color or Color( 255, 0, 0,  125)
                s.material = data.material and Material( data.material ) or mat2
                s.size = data.size and data.size or 16
                s.pos = data.pos
                if (data.OnBodyGroups) then s.bodygroups = data.OnBodyGroups end
                sprites[#sprites + 1] = s
            else
                s.pos = data
                s.color = Color( 255, 0, 0,  90 )
                s.material = mat
                s.size = 32
                sprites[#sprites + 1] = s

                local s2 = {}
                s2.PixVis = util.GetPixelVisibleHandle()
                s2.trigger = s.trigger
                s2.pos = data
                s2.color = Color( 255, 120, 0,  125 )
                s2.material = mat2
                s2.size = 12
                sprites[#sprites + 1] = s2
            end
        end
    end

    if vehiclelist.Reverselight_sprites then
        for _, data in pairs( vehiclelist.Reverselight_sprites ) do
            local s = {}
            s.PixVis = util.GetPixelVisibleHandle()
            s.trigger = 5

            if not isvector(data) then
                s.color = data.color and data.color or Color( 255, 255, 255,  255)
                s.material = data.material and Material( data.material ) or mat2
                s.size = data.size and data.size or 16
                s.pos = data.pos
                if (data.OnBodyGroups) then s.bodygroups = data.OnBodyGroups end
                sprites[#sprites + 1] = s
            else
                s.pos = data
                s.color = Color( 255, 255, 255,  150)
                s.material = mat
                s.size = 12
                sprites[#sprites + 1] = s

                local s2 = {}
                s2.PixVis = util.GetPixelVisibleHandle()
                s2.trigger = s.trigger
                s2.pos = data
                s2.color =  Color( 255, 255, 255,  80 )
                s2.material = mat2
                s2.size = 25
                sprites[#sprites + 1] = s2
            end
        end
    end

    if vehiclelist.FrontMarker_sprites then
        for _, data in pairs( vehiclelist.FrontMarker_sprites ) do
            local s = {}
            s.PixVis = util.GetPixelVisibleHandle()
            s.trigger = 1

            if isvector(data) then
                s.pos = data
                s.color = Color( 200, 100, 0,  150)
                s.material = mat
                s.size = 12
                sprites[#sprites + 1] = s
            end
        end
    end

    if vehiclelist.RearMarker_sprites then
        for _, data in pairs( vehiclelist.RearMarker_sprites ) do
            local s = {}
            s.PixVis = util.GetPixelVisibleHandle()
            s.trigger = 1

            if isvector(data) then
                s.pos = data
                s.color = Color( 205, 0, 0,  150 )
                s.material = mat
                s.size = 12
                sprites[#sprites + 1] = s
            end
        end
    end

    if vehiclelist.Headlamp_sprites then
        for _, data in pairs( vehiclelist.Headlamp_sprites ) do
            local s = {}
            s.PixVis = util.GetPixelVisibleHandle()
            s.trigger = 2

            if not isvector(data) then
                s.color = data.color and data.color or Color( hl_col[1], hl_col[2], hl_col[3],  255)
                s.material = data.material and Material( data.material ) or mat2
                s.size = data.size and data.size or 16
                s.pos = data.pos
                if (data.OnBodyGroups) then s.bodygroups = data.OnBodyGroups end
                sprites[#sprites + 1] = s
            else
                s.pos = data
                s.color = Color( hl_col[1], hl_col[2], hl_col[3],  255)
                s.material = mat
                s.size = 16
                sprites[#sprites + 1] = s

                local s2 = {}
                s2.PixVis = util.GetPixelVisibleHandle()
                s2.trigger = s.trigger
                s2.pos = data
                s2.color = Color( hl_col[1], hl_col[2], hl_col[3],  150)
                s2.material = mat2
                s2.size = 64
                sprites[#sprites + 1] = s2
            end
        end
    end

    if vehiclelist.FogLight_sprites then
        for _, data in pairs( vehiclelist.FogLight_sprites ) do
            local s = {}
            s.PixVis = util.GetPixelVisibleHandle()
            s.trigger = 3

            if not isvector(data) then
                s.color = data.color and data.color or Color( hl_col[1], hl_col[2], hl_col[3],  255)
                s.material = data.material and Material( data.material ) or mat2
                s.size = data.size and data.size or 32
                s.pos = data.pos
                if (data.OnBodyGroups) then s.bodygroups = data.OnBodyGroups end
                sprites[#sprites + 1] = s
            else
                s.pos = data
                s.color = Color( hl_col[1], hl_col[2], hl_col[3],  200)
                s.material = mat2
                s.size = 32
                sprites[#sprites + 1] = s
            end
        end
    end

    if vehiclelist.Turnsignal_sprites then
        ent.HasTurnSignals = true

        if vehiclelist.Turnsignal_sprites.Left then
            for _, data in pairs( vehiclelist.Turnsignal_sprites.Left ) do
                local s = {}
                s.PixVis = util.GetPixelVisibleHandle()
                s.trigger = 6

                if not isvector( data ) then
                    s.color = data.color and data.color or Color( 200, 100, 0,  255)
                    s.material = data.material and Material( data.material ) or mat2
                    s.size = data.size and data.size or 24
                    s.pos = data.pos
                    if (data.OnBodyGroups) then s.bodygroups = data.OnBodyGroups end
                    sprites[#sprites + 1] = s
                else
                    s.pos = data
                    s.color = Color( 255, 150, 0,  150)
                    s.material = mat
                    s.size = 20
                    sprites[#sprites + 1] = s

                    local s2 = {}
                    s2.PixVis = util.GetPixelVisibleHandle()
                    s2.trigger = s.trigger
                    s2.pos = data
                    s2.color = Color( 200, 100, 0,  80)
                    s2.material = mat2
                    s2.size = 70
                    sprites[#sprites + 1] = s2
                end
            end
        end

        if vehiclelist.Turnsignal_sprites.Right then
            for _, data in pairs( vehiclelist.Turnsignal_sprites.Right ) do
                local s = {}
                s.PixVis = util.GetPixelVisibleHandle()
                s.trigger = 7

                if not isvector( data ) then
                    s.color = data.color and data.color or Color( 200, 100, 0,  255)
                    s.material = data.material and Material( data.material ) or mat2
                    s.size = data.size and data.size or 24
                    s.pos = data.pos
                    if (data.OnBodyGroups) then s.bodygroups = data.OnBodyGroups end
                    sprites[#sprites + 1] = s
                else
                    s.pos = data
                    s.color = Color( 255, 150, 0,  150)
                    s.material = mat
                    s.size = 20
                    sprites[#sprites + 1] = s

                    local s2 = {}
                    s2.PixVis = util.GetPixelVisibleHandle()
                    s2.trigger = s.trigger
                    s2.pos = data
                    s2.color = Color( 200, 100, 0,  80)
                    s2.material = mat2
                    s2.size = 70
                    sprites[#sprites + 1] = s2
                end
            end
        end

        if vehiclelist.Turnsignal_sprites.TurnBrakeLeft then
            ent.HasSpecialTurnSignals = true
            for _, data in pairs( vehiclelist.Turnsignal_sprites.TurnBrakeLeft ) do
                local s = {}
                s.PixVis = util.GetPixelVisibleHandle()
                s.trigger = 8

                if not isvector(data) then
                    s.color = data.color and data.color or Color( 255, 0, 0,  125)
                    s.material = data.material and Material( data.material ) or mat2
                    s.size = data.size and data.size or 16
                    s.pos = data.pos
                    if (data.OnBodyGroups) then s.bodygroups = data.OnBodyGroups end
                    sprites[#sprites + 1] = s
                else
                    s.pos = data
                    s.color = Color( 255, 60, 0,  90 )
                    s.material = mat
                    s.size = 40
                    sprites[#sprites + 1] = s

                    local s2 = {}
                    s2.PixVis = util.GetPixelVisibleHandle()
                    s2.trigger = s.trigger
                    s2.pos = data
                    s2.color = Color( 255, 120, 0,  125 )
                    s2.material = mat2
                    s2.size = 16
                    sprites[#sprites + 1] = s2
                end
            end
        end

        if vehiclelist.Turnsignal_sprites.TurnBrakeRight then
            ent.HasSpecialTurnSignals = true
            for _, data in pairs( vehiclelist.Turnsignal_sprites.TurnBrakeRight ) do
                local s = {}
                s.PixVis = util.GetPixelVisibleHandle()
                s.trigger = 9

                if not isvector(data) then
                    s.color = data.color and data.color or Color( 255, 0, 0,  125)
                    s.material = data.material and Material( data.material ) or mat2
                    s.size = data.size and data.size or 16
                    s.pos = data.pos
                    if (data.OnBodyGroups) then s.bodygroups = data.OnBodyGroups end
                    sprites[#sprites + 1] = s
                else
                    s.pos = data
                    s.color = Color( 255, 60, 0,  90 )
                    s.material = mat
                    s.size = 40
                    sprites[#sprites + 1] = s

                    local s2 = {}
                    s2.PixVis = util.GetPixelVisibleHandle()
                    s2.trigger = s.trigger
                    s2.pos = data
                    s2.color = Color( 255, 120, 0,  125 )
                    s2.material = mat2
                    s2.size = 16
                    sprites[#sprites + 1] = s2
                end
            end
        end
    end

    ent.EnableLights = true
    vehiclesTable[#vehiclesTable + 1] = ent
end


local CLR_EMPTY = Color( 0, 0, 0, 0 )

local function DrawEMSLights( ent )
    local time = CurTime()
    local lightsEMS = ent.LightsEMS

    if not lightsEMS then return end

    for i = 1, #lightsEMS do
        if lightsEMS[i].Damaged then continue end

        local size = lightsEMS[i].size
        local LightPos = ent:LocalToWorld( lightsEMS[i].pos )
        local visible = util.PixelVisible( LightPos, 4, ent.PixVisEMS[i] )
        local mat = lightsEMS[i].material
        local numcolors = table.Count( lightsEMS[i].Colors )

        lightsEMS[i].timer = lightsEMS[i].timer or 0
        lightsEMS[i].Index = lightsEMS[i].Index or 0

        if numcolors > 1 then

            if lightsEMS[i].timer < time then

                lightsEMS[i].timer = time + lightsEMS[i].Speed
                lightsEMS[i].Index = lightsEMS[i].Index + 1

                if lightsEMS[i].Index > numcolors then
                    lightsEMS[i].Index = 1
                end
            end
        end

        local col = lightsEMS[i].Colors[lightsEMS[i].Index]

        if lightsEMS[i].OnBodyGroups then
            visible = ent:BodyGroupIsValid( lightsEMS[i].OnBodyGroups ) and visible or 0
        end

        if visible and visible >= 0.6 and col ~= CLR_EMPTY then
            visible = ( visible - 0.6 ) / 0.4

            render.SetMaterial( mat )
            render.DrawSprite( LightPos, size, size,  Color( col.r, col.g, col.b,  col.a * visible ) )
        end
    end
end

hook.Add( "Tick", "simfphys_lights_managment", function()
    ManageProjTextures()

    curtime = CurTime()

    if NextCheck < curtime then
        NextCheck = curtime + checkinterval

        for _, veh in ipairs( ents.FindByClass( "gmod_sent_vehicle_fphysics_base" ) ) do
            if veh.EnableLights then continue end
        
            local listname = veh:GetLights_List()

            if listname ~= "no_lights" then
                SetUpLights( listname, veh )
            else
                veh.EnableLights = true
            end
        end
    end
end )

hook.Add( "PostDrawTranslucentRenderables", "simfphys_draw_sprites", function( _, skybox, skybox3d )
    if skybox or skybox3d then return end

    local visible
    local lightPos
    local entTable

    local spriteClr
    local spriteSize

    for _, ent in ipairs( vehiclesTable ) do
        if not IsValid( ent ) or ent:IsDormant() then continue end

        entTable = ent:GetTable()

        if ent:GetEMSEnabled() then
            DrawEMSLights( ent )
        end

        if SpritesDisabled then return end
        if not entTable.triggers then return end

        for _, sprite in ipairs( entTable.simfphys_sprites ) do
            if sprite.Damaged then continue end

            local regTrigger = entTable.triggers[sprite.trigger]
            local typeSpecial = ( sprite.trigger == 8 and entTable.triggers[6] ) or ( sprite.trigger == 9 and entTable.triggers[7] )
            if typeSpecial then
                regTrigger = false
            end

            if regTrigger or typeSpecial then
                lightPos = ent:LocalToWorld( sprite.pos )
                visible = util.PixelVisible( lightPos, 4, sprite.PixVis )

                spriteClr = sprite.color
                spriteSize = sprite.size

                if sprite.bodygroups then
                    visible = bodyGroupIsValid( sprite.bodygroups, ent ) and visible or 0
                end

                if visible and visible >= 0.6 then
                    visible = ( visible - 0.6 ) / 0.4
                    render.SetMaterial( sprite.material )

                    local clrAlpha = spriteClr.a * visible
                    if sprite.trigger == 6 or sprite.trigger == 7 or typeSpecial then
                        clrAlpha = clrAlpha * ent:GetFlasher() ^ 7
                    end

                    render.DrawSprite( lightPos, spriteSize, spriteSize,  Color( spriteClr.r, spriteClr.g, spriteClr.b,  clrAlpha ) )
                end
            end
        end
    end
end )

local glassimpact = Sound( "Glass.BulletImpact" )
local function spriteDamage( length )
    if not simfphys.DamageEnabled then return end

    local veh = net.ReadEntity()
    if not IsValid( veh ) then return end

    local pos = veh:LocalToWorld( net.ReadVector() )
    local rad = net.ReadBool() and 26 or 8
    local curtime = CurTime()

    local dist

    veh.NextImpactsnd = veh.NextImpactsnd or 0

    if veh.simfphys_sprites then
        local sprites = veh.simfphys_sprites
        local sprite
        local spritePos

        for i = 1, #sprites do
            sprite = sprites[i]
            if sprite.Damaged then continue end

            spritePos = veh:LocalToWorld( sprite.pos )
            dist = ( spritePos - pos ):Length()

            if dist < rad then
                sprites[i].Damaged = true

                if sprite.trigger >= 6 then
                    veh.turnsignals_damaged = true
                end

                local effectdata = EffectData()
                effectdata:SetOrigin( spritePos )
                util.Effect( "GlassImpact", effectdata, true, true )

                if veh.NextImpactsnd < curtime then
                    veh.NextImpactsnd = curtime + 0.05
                    sound.Play( glassimpact, spritePos, 75 )
                end
            end
        end
    end

    if veh.simfphys_projectedTextures then
        local projectedTexures = veh.simfphys_projectedTextures

        for i, proj in pairs( projectedTexures ) do
            if proj.Damaged then continue end

            dist = ( veh:LocalToWorld( proj.pos ) - pos ):Length()

            if dist < rad * 2 then
                projectedTexures[i].Damaged = true
            end
        end
    end

    if veh.LightsEMS then
        local lightsEMS = veh.LightsEMS
        local light

        for i = 1, #lightsEMS do
            light = lightsEMS[i]
            if lightsEMS[i].Damaged then continue end

            local spritePos = veh:LocalToWorld( light.pos )
            dist = ( spritePos - pos ):Length()

            if dist < rad then
                light.Damaged = true

                local effectdata = EffectData()
                effectdata:SetOrigin( spritePos )
                util.Effect( "GlassImpact", effectdata, true, true )

                if veh.NextImpactsnd < curtime then
                    veh.NextImpactsnd = curtime + 0.05
                    sound.Play( glassimpact, spritePos, 75 )
                end
            end
        end
    end
end
net.Receive( "simfphys_spritedamage", spriteDamage )

local function spriteRepair()
    local veh = net.ReadEntity()
    if not IsValid( veh ) then return end

    veh.turnsignals_damaged = nil

    local sprites = veh.simfphys_sprites

    if sprites then
        for i = 1, #sprites do
            sprites[i].Damaged = false
        end
    end


    local projectedTextures = veh.simfphys_projectedTextures

    if projectedTextures then
        for _, proj in pairs( projectedTextures ) do
            proj.Damaged = false
        end
    end


    local lightsEMS = veh.LightsEMS

    if lightsEMS then
        for i = 1, #lightsEMS do
            lightsEMS[i].Damaged = false
        end
    end
end
net.Receive( "simfphys_lightsfixall", spriteRepair )


net.Receive( "simfphys_turnsignal", function()
    local ent = net.ReadEntity()
    local turnmode = net.ReadInt( 3 )

    if not IsValid( ent ) then return end

    if turnmode == 0 then
        ent.signal_left = false
        ent.signal_right = false
    end

    if turnmode == 1 then
        ent.signal_left = true
        ent.signal_right = true
    end

    if turnmode == 2 then
        ent.signal_left = true
        ent.signal_right = false
    end

    if turnmode == 3 then
        ent.signal_left = false
        ent.signal_right = true
    end
end )
