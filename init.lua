local path = minetest.get_modpath("aurora_tech")

dofile(path .. "/api.lua")

dofile(path .. "/items/empowered_diamond.lua")
dofile(path .. "/items/lava_charge_and_core.lua")

dofile(path .. "/machines/diamond_empowerer.lua")
dofile(path .. "/machines/lava_crucible.lua")
dofile(path .. "/machines/mese_generator.lua")
dofile(path .. "/machines/recharger.lua")

dofile(path .. "/tools/blink_launcher.lua")
dofile(path .. "/tools/mining_laser.lua")
dofile(path .. "/tools/remote_drone.lua")
dofile(path .. "/tools/warp_boots.lua")
