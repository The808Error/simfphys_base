simfphys = istable( simfphys ) and simfphys or {}

AddCSLuaFile("simfphys/init.lua")
include("simfphys/init.lua")

if SERVER then
    resource.AddWorkshop("3115781297")
end
