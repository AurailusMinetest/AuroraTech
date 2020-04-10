local laser_users = {}

local function enable_laser(itemstack, player)
	minetest.sound_play("combat_mining_laser_start", {to_player = player:get_player_name()}, true)
	laser_users[player:get_player_name()] = minetest.sound_play("combat_mining_laser_run", {to_player = player:get_player_name(), gain = 0.3, loop = true})

	itemstack:replace("combat:mining_laser")
	return itemstack
end

local function disable_laser(player)
	local inventory = player:get_inventory()
	if inventory:contains_item("main", "combat:mining_laser") then
		for i = 1, inventory:get_size("main") do
			if inventory:get_stack("main", i):get_name() == "combat:mining_laser" then
				inventory:set_stack("main", i, "combat:mining_laser_off")
				break
			end
		end
	end
	minetest.sound_stop(laser_users[player:get_player_name()])
	minetest.sound_play("combat_mining_laser_stop", {to_player = player:get_player_name(), gain = 0.8}, true)
	laser_users[player:get_player_name()] = nil
end

local function gun_trigger(player)
 local dir = player:get_look_dir()
 local pos = vector.add(player:getpos(),{x=0,y=1.625,z=0})

	local ray = minetest.raycast(pos, vector.add(pos,vector.multiply(dir, 16)), false, true)
	local pos = nil
	for pointed_thing in ray do
	  local cname = minetest.get_node(pointed_thing.under).name
	  if minetest.registered_nodes[cname] ~= nil and cname ~= "air" then pos = pointed_thing.under break end
	end

	if pos ~= nil then
		for i = 0, 15 do
			local frame = math.floor(math.random() * 4)
			minetest.add_particle({
				pos = vector.add(pos, vector.new((math.random() - 0.5) * 0.7, (math.random() - 0.5) * 0.7, (math.random() - 0.5) * 0.7)),
				velocity = vector.new((math.random() - 0.5) * 0.7, (math.random() - 0.5) * 0.7, (math.random() - 0.5) * 0.7),

				expirationtime = math.random() * 0.2 + 0.05,
				collisiondetection = false,
				size = 3,

				texture = "combat_blink_launcher_particle_dead.png^[verticalframe:4:" .. frame,
				glow = 14
			})
		end

		minetest.sound_play("combat_mining_laser_break", {pos = pos, gain = 0.7, max_hear_distance = 16}, true)
		minetest.node_dig(pos, minetest.registered_nodes[minetest.get_node(pos).name], player)
	end
end

local time = 0
minetest.register_globalstep(function(delta)
	time = time + delta

	for p,_ in pairs(laser_users) do
		local player = minetest.get_player_by_name(p)

		if not player:get_player_control().RMB or player:get_wielded_item():get_name() ~= "combat:mining_laser" then
			disable_laser(player)
		else
			if time > 0.05 then
				gun_trigger(player)
				time = time - 0.05
			end
		end
	end
end)

-- Prevents players from dropping active mining lasers
local old_item_drop = minetest.item_drop
function minetest.item_drop(itemstack, dropper, pos)
	if laser_users[dropper:get_player_name()] ~= nil then return itemstack end
	if itemstack:get_name() == "combat:mining_laser_off" then
		itemstack:replace("combat:mining_laser_dropped")
		return old_item_drop(itemstack, dropper, pos)
	end
	return old_item_drop(itemstack, dropper, pos)
end

combat.register_tool_3d("combat:mining_laser", {
	description = "Mining Laser",
	tiles = { "combat_mining_laser.png" },
	mesh = "combat_mining_laser.b3d",
	inventory_image = "combat_mining_laser_icon.png",
	groups = { not_in_creative_inventory = 1 },
	range = 0
}, function(_, placer) minetest.after(0, function() disable_laser(placer) end) end)


combat.register_tool_3d("combat:mining_laser_off", {
	description = "Mining Laser",
	tiles = { "combat_mining_laser_off.png" },
	mesh = "combat_mining_laser.b3d",
	inventory_image = "combat_mining_laser_off_icon.png",
	range = 0
}, function(stack, placer) return enable_laser(stack, placer) end)


combat.register_tool_3d("combat:mining_laser_dropped", {
	description = "Mining Laser",
	tiles = { "combat_mining_laser_off.png" },
	mesh = "combat_mining_laser_dropped.b3d",
	groups = { not_in_creative_inventory = 1 },
	inventory_image = "combat_mining_laser_off_icon.png",
	range = 0
}, function(stack, placer) return enable_laser(stack, placer) end)

minetest.register_craft({
  output = 'combat:mining_laser_off',
  recipe = {
      {'default:bronze_ingot', 'default:meselamp', ''},
      {'', 'combat:lava_core', 'default:meselamp'},
      {'', 'default:steel_ingot', 'default:bronze_ingot'},
  },
})
