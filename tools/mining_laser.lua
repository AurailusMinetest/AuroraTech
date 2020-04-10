local laser_users = {}
local dura = 1400

local function enable_laser(itemstack, player)
	minetest.sound_play("aurora_tech_mining_laser_start", {to_player = player:get_player_name()}, true)
	laser_users[player:get_player_name()] = {
		uses = 0,
		sound = minetest.sound_play("aurora_tech_mining_laser_run", {to_player = player:get_player_name(), gain = 0.3, loop = true})
	}

	local dura = itemstack:get_name():sub(("aurora_tech:mining_laser_0"):len())

	itemstack:replace("aurora_tech:mining_laser_active_" .. dura)
	return itemstack
end

local function laser_dead(player)
	minetest.sound_play("aurora_tech_mining_laser_stop", {to_player = player:get_player_name(), gain = 0.8}, true)
end

local function disable_laser(player)
	local inventory = player:get_inventory()
	for i = 1, inventory:get_size("main") do
		if inventory:get_stack("main", i):get_name():sub(0, ("aurora_tech:mining_laser_active"):len()) == "aurora_tech:mining_laser_active" then
			local dura = inventory:get_stack("main", i):get_name():sub(("aurora_tech:mining_laser_active_0"):len())
			inventory:set_stack("main", i, "aurora_tech:mining_laser_" .. dura)
			
			break
		end
	end

	if laser_users[player:get_player_name()] == nil then return end

	minetest.sound_stop(laser_users[player:get_player_name()].sound)
	minetest.sound_play("aurora_tech_mining_laser_stop", {to_player = player:get_player_name(), gain = 0.8}, true)
	laser_users[player:get_player_name()] = nil
end

local function gun_break_blocks(player)
 local dir = player:get_look_dir()
 local pos = vector.add(player:getpos(),{x=0,y=1.625,z=0})

	local ray = minetest.raycast(pos, vector.add(pos,vector.multiply(dir, 16)), false, false)
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

				texture = "aurora_tech_particle_blink_launcher_trail_dead.png^[verticalframe:4:" .. frame,
				glow = 14
			})
		end

		minetest.sound_play("aurora_tech_mining_laser_destroy", {pos = pos, gain = 0.7, max_hear_distance = 16}, true)
		minetest.node_dig(pos, minetest.registered_nodes[minetest.get_node(pos).name], player)
	end

	local stack = player:get_wielded_item()
	stack:get_meta():set_int("uses", laser_users[player:get_player_name()].uses)
	local newstack = aurora_tech.damage_tool(stack)
	local name = newstack:get_name()

	if name ~= player:get_wielded_item():get_name() then 
		player:set_wielded_item(newstack)
		laser_users[player:get_player_name()].uses = 0
	else
		laser_users[player:get_player_name()].uses = laser_users[player:get_player_name()].uses + 1
	end
end

local function gun_damage_entities(player)
	local dir = player:get_look_dir()
	local pos = vector.add(player:getpos(),{x=0,y=1.625,z=0})

	local ray = minetest.raycast(pos, vector.add(pos,vector.multiply(dir, 16)), true, false)
	local pos = nil
	for pointed_thing in ray do
		if pointed_thing.type == "object" and pointed_thing.ref ~= player then

			pointed_thing.ref:punch(player, 1000, {damage_groups = {fleshy=1}}, bil)
			
			for i = 0, 15 do
				local frame = math.floor(math.random() * 4)
				minetest.sound_play("aurora_tech_mining_laser_destroy", {pos = pointed_thing.ref:get_pos(), gain = 0.3, max_hear_distance = 16}, true)
				minetest.add_particle({
					pos = vector.add(vector.add(pointed_thing.ref:get_pos(), vector.new(0, 0.8, 0)), vector.new((math.random() - 0.5) * 0.7, (math.random() - 0.5) * 1.4, (math.random() - 0.5) * 0.7)),
					velocity = vector.new((math.random() - 0.5) * 0.7, (math.random() - 0.5) * 0.7, (math.random() - 0.5) * 0.7),

					expirationtime = math.random() * 0.2 + 0.05,
					collisiondetection = false,
					size = 3,

					texture = "aurora_tech_particle_blink_launcher_trail_dead.png^[verticalframe:4:" .. frame,
					glow = 14
				})
			end

			return
		end
	end
end

local break_time = 0
local damage_time = 0
minetest.register_globalstep(function(delta)
	break_time = break_time + delta
	damage_time = damage_time + delta

	local trigger_break = false
	local trigger_damage = false

	if break_time > 0.05 then
		trigger_break = true
		break_time = break_time - 0.05
	end
	if damage_time > 0.15 then
		trigger_damage = true
		damage_time = damage_time - 0.15
	end

	if not trigger_break and not trigger_damage then return end

	for p,_ in pairs(laser_users) do
		local player = minetest.get_player_by_name(p)

		if not player:get_player_control().RMB 
			or player:get_wielded_item():get_name():sub(0, ("aurora_tech:mining_laser_active"):len()) ~= "aurora_tech:mining_laser_active" 
			or player:get_wielded_item():get_name() == "aurora_tech:mining_laser_active_1" then
			disable_laser(player)
		else
			if trigger_break then
				gun_break_blocks(player)
			end
			if trigger_damage then
				gun_damage_entities(player)
			end
		end
	end
end)

-- Prevents players from dropping active mining lasers
local old_item_drop = minetest.item_drop
function minetest.item_drop(itemstack, dropper, pos)
	if laser_users[dropper:get_player_name()] ~= nil then return itemstack end
	if itemstack:get_name() == "aurora_tech:mining_laser" then
		itemstack:replace("aurora_tech:mining_laser_dropped")
		return old_item_drop(itemstack, dropper, pos)
	end
	return old_item_drop(itemstack, dropper, pos)
end

aurora_tech.register_tool_3d("aurora_tech:mining_laser_active", {
	description = "Mining Laser",
	tiles = { "aurora_tech_tool_mining_laser_active.png" },
	mesh = "aurora_tech_tool_mining_laser.b3d",
	inventory_image = "aurora_tech_icon_mining_laser_active.png",
	groups = { not_in_creative_inventory = 1 },
	range = 0
}, function(_, placer) minetest.after(0, function() disable_laser(placer) end) end, dura, false, function(_, placer) minetest.after(0, function() disable_laser(placer) end) end)


aurora_tech.register_tool_3d("aurora_tech:mining_laser", {
	description = "Mining Laser",
	tiles = { "aurora_tech_tool_mining_laser.png" },
	mesh = "aurora_tech_tool_mining_laser.b3d",
	inventory_image = "aurora_tech_icon_mining_laser.png",
	range = 0
}, function(stack, placer) return enable_laser(stack, placer) end, dura, false, function(_, placer) laser_dead(placer) end)


aurora_tech.register_tool_3d("aurora_tech:mining_laser_dropped", {
	description = "Mining Laser",
	tiles = { "aurora_tech_tool_mining_laser.png" },
	mesh = "aurora_tech_tool_mining_laser_dropped.b3d",
	groups = { not_in_creative_inventory = 1 },
	inventory_image = "aurora_tech_icon_mining_laser.png",
	range = 0
}, function(stack, placer) return enable_laser(stack, placer) end, dura, false, function(_, placer) laser_dead(placer) end)

minetest.register_craft({
  output = 'aurora_tech:mining_laser_16',
  recipe = {
      {'default:bronze_ingot', 'default:meselamp', ''},
      {'', 'aurora_tech:lava_core', 'default:meselamp'},
      {'', 'default:steel_ingot', 'default:bronze_ingot'},
  },
})

aurora_tech.register_repair("aurora_tech:mining_laser", "aurora_tech:lava_charge", 2)
aurora_tech.register_repair("aurora_tech:mining_laser_dropped", "aurora_tech:lava_charge", 2, "aurora_tech:mining_laser")
aurora_tech.register_repair("aurora_tech:mining_laser", "aurora_tech:lava_core", 16)
aurora_tech.register_repair("aurora_tech:mining_laser_dropped", "aurora_tech:lava_core", 16, "aurora_tech:mining_laser")
