local drone_refs = {}

-- Prevent 3d armor from fucking the model
local old_update_player_visuals = armor.update_player_visuals
armor.update_player_visuals = function(self, player)
	if drone_refs[player:get_player_name()] ~= nil then return end
	old_update_player_visuals(self, player)
end

-- Prevent players controlling drones from interacting with nodes
local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
	if drone_refs[name] ~= nil then return true end
	return old_is_protected(pos, name)
end

-- Prevents players from dropping drone control items
local old_item_drop = minetest.item_drop
function minetest.item_drop(itemstack, dropper, pos)
	if drone_refs[dropper:get_player_name()] ~= nil then return itemstack end
	return old_item_drop(itemstack, dropper, pos)
end

-- Functions to convert the player into the drone, and back again
local function enter_drone(name)
	local player = minetest.get_player_by_name(name)
	if not player then return end

	if drone_refs[name] ~= nil then return end

	drone_refs[name] = {
		collision = table.copy(player:get_properties().collisionbox),
		textures = table.copy(player:get_properties().textures),
		mesh = player:get_properties().mesh,
		eye_offset_first = player:get_eye_offset().offset_first,
		eye_offset_third = player:get_eye_offset().offset_third,
		vertical = player:get_look_vertical(),
		horizontal = player:get_look_horizontal(),
		inventory = player:get_inventory():get_lists(),
		formspec = player:get_inventory_formspec(),
		hotbar = player:hud_get_hotbar_itemcount(),
		nametag = player:get_nametag_attributes().text,
		hud = player:hud_add({hud_elem_type = "image", text = "aurora_tech_ui_drone_overlay.png", position = {x = 0.5, y = 0.5}, scale = {x = -100, y = -100}}),
		ent = minetest.add_entity(player:get_pos(), "aurora_tech:drone_player_ref", minetest.serialize({player = name})):get_luaentity()
	}

	minetest.sound_play("aurora_tech_drone_enter", {to_player = name}, true)

	player:set_properties({ 
    collisionbox = {-0.4, 0, -0.4, 0.4, 0.45, 0.4},
    visual_size = {x = 0.63, y = 0.63, z = 0.63},
    mesh = "aurora_tech_entity_remote_drone.b3d",
    textures = {"aurora_tech_entity_remote_drone.png"},
	})
	player:set_nametag_attributes({text = " "})
	player:set_eye_offset({ x = 0, y = -12, z = 0 }, player:get_eye_offset().offset_third)
	player:set_physics_override({ speed = 0.6, jump = 1.4, gravity = 2, sneak = false })
	player:hud_set_hotbar_itemcount(2)
	player:hud_set_flags({healthbar = false, breathbar = false, hotbar = false})
	player:set_inventory_formspec([[
		size[4, 2]
		real_coordinates[true]
		button[1,0.6;2,0.75;aurora_tech_detonate_drone;Detonate]
	]])

	minetest.after(0, function()
		for list in pairs(player:get_inventory():get_lists()) do
			player:get_inventory():set_list(list, {})

			player:get_inventory():set_stack("main", 2, "aurora_tech:drone_icon_detonate")

			while player:get_inventory():room_for_item('main', 'aurora_tech:drone_icon_interact') do
				player:get_inventory():add_item("main", "aurora_tech:drone_icon_interact")
			end
		end
	end)
end

local function exit_drone(name)
	local player = minetest.get_player_by_name(name)
	if not player then return end

	if not drone_refs[name] then return end
	local props = drone_refs[name]

	local exploder = minetest.add_entity(player:get_pos(), "aurora_tech:drone_exploding", minetest.serialize({player = name}))

	minetest.sound_play("aurora_tech_drone_exit", {to_player = name}, true)

	player:set_properties({visual_size = {x = 0, y = 0}})
	
	player:set_pos(props.ent.object:get_pos())
	player:set_eye_offset(props.eye_offset_first, props.eye_offset_third)
	player:set_physics_override({ speed = 1, jump = 1, gravity = 1, sneak = true })
	player:set_look_vertical(props.vertical)
	player:set_look_horizontal(props.horizontal)
	player:get_inventory():set_lists(props.inventory)
	player:set_inventory_formspec(props.formspec)
	player:hud_set_flags({healthbar = true, breathbar = true, hotbar = true})
	player:hud_set_hotbar_itemcount(props.hotbar)
	player:hud_remove(props.hud)

	player:set_properties({ 
		collisionbox = props.collision,
    mesh = props.mesh,
    textures = props.textures,
	})

	drone_refs[name] = nil

	minetest.after(0.6, function()
		if drone_refs[name] ~= nil then return end
		
		player:set_nametag_attributes({text = props.nametag})
		player:set_properties({ visual_size = {x = 1, y = 1} })

		props.ent.object:remove()
	end)


end

local function interact_remote(itemstack, player, pointed_thing)
	local name = player:get_player_name()
	local charge = itemstack:get_name():sub(26)

	if pointed_thing and pointed_thing.type == "node" and minetest.get_node(pointed_thing.under).name == "aurora_tech:recharger" then
		if charge == 16 then return itemstack end
		return minetest.registered_nodes["aurora_tech:recharger"].on_rightclick(pointed_thing.under, nil, player, itemstack)
	end

	if not drone_refs[name] then minetest.after(0, function() enter_drone(name) end) end
end

minetest.register_on_joinplayer(function(player)
	minetest.register_on_player_receive_fields(function(player, _, fields)
    if fields.aurora_tech_detonate_drone then
    	exit_drone(player:get_player_name())
    	minetest.close_formspec(player:get_player_name(), "")
    end
	end)
end)

minetest.register_on_shutdown(function()
	for p,_ in pairs(drone_refs) do
		exit_drone(p)
	end
end)

minetest.register_on_leaveplayer(function(player)
	exit_drone(player:get_player_name())
end)

minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if drone_refs[player:get_player_name()] ~= nil then
		exit_drone(player:get_player_name())
		return 0
	else return hp_change end
end, true)

aurora_tech.register_tool_3d("aurora_tech:drone_remote", {
	description = "Drone Remote",
	description = "Drone Remote",
	tiles = { "aurora_tech_tool_drone_remote.png" },
	-- groups = {not_in_creative_inventory = 1},
	inventory_image = "aurora_tech_icon_drone_remote.png",
	mesh = "aurora_tech_tool_drone_remote.b3d",
}, function(itemstack, placer, pointed_thing) return interact_remote(itemstack, placer, pointed_thing) end, 16, true, nil)

minetest.register_entity("aurora_tech:drone_player_ref", {
	initial_properties = {
    mesh = "character.b3d",
    visual = "mesh",
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
    stepheight = 1,
    physical = true,
    collide_with_objects = false,
	},
	on_activate = function(self, static)
		local static = minetest.deserialize(static) or {}

		if not static.player then self.object:remove() return end

		self.player = static.player
		local player = minetest.get_player_by_name(self.player)

		if not player then self.object:remove() return end

		self.object:set_properties({ 
			textures = player:get_properties().textures,
			nametag = self.player
		})
		self.object:set_armor_groups({ immortal = 1 })
		self.object:set_yaw(player:get_look_horizontal())
	end,
	get_staticdata = function(self)
		return ""
	end,
	on_punch = function(self)
		minetest.after(0, function() exit_drone(self.player) end)
		self.object:remove()
	end,
	on_step = function(self, delta)
		self.object:set_velocity(vector.new())
	end,
})

minetest.register_entity("aurora_tech:drone_exploding", {
	initial_properties = {
    mesh = "aurora_tech_entity_remote_drone.b3d",
    textures = {"aurora_tech_entity_remote_drone.png"},
    collisionbox = {-0.4, 0, -0.4, 0.4, 0.45, 0.4},
    visual_size = {x = 0.63, y = 0.63, z = 0.63},
    visual = "mesh",
    stepheight = 1,
    physical = true,
    collide_with_objects = false,
    backface_culling = false,
	},

	on_activate = function(self, static)
		local static = minetest.deserialize(static) or {}
		if not static.player then self.object:remove() return end

		local player = minetest.get_player_by_name(static.player)
		if not player then self.object:remove() return end

		self.object:set_yaw(player:get_look_horizontal())
		self.life = 0

		self.object:set_velocity(vector.new(0, -10, 0))
		self.object:set_hp(10)
	end,

	on_step = function (self, delta)
		self.life = self.life + delta;

		local texture = "aurora_tech_entity_remote_drone.png"
		if self.life * 40 % 20 > 10 and self.life * 40 % 20 < 20 then texture = "aurora_tech_entity_remote_drone.png^[colorize:#ffcccc:120" end

		self.object:set_properties({ textures = { texture } })

		if self.life > 3 then
			if minetest.registered_nodes["tnt:tnt"] ~= nil then
				tnt.boom(self.object:get_pos(), {radius = 2.5})
			end
			self.object:remove()
		end
	end
})

aurora_tech.register_tool_3d("aurora_tech:drone_icon_interact", {
	description = "",
	
	tiles = { "aurora_tech_entity_remote_drone.png" },
	mesh = "aurora_tech_tool_drone_turret.b3d",

	range = 0,
	groups = {not_in_creative_inventory = 1},
}, function(_, player)
	minetest.sound_play("aurora_tech_interact", {pos = pos, max_hear_distance = 32}, true)
	
	local dir = player:get_look_dir()
	local pos = vector.add(player:getpos(),{x=0,y=0.3,z=0})

	local ray = minetest.raycast(pos, vector.add(pos,vector.multiply(dir, 32)), true, false)
	local pos = nil
	for pointed_thing in ray do
		if pointed_thing.type == "object" and pointed_thing.ref ~= player then

			pointed_thing.ref:punch(player, 1000, {damage_groups = {fleshy=3}}, nil)
			return
		end
	end

end)

aurora_tech.register_tool_3d("aurora_tech:drone_icon_detonate", {
	description = "Detonate",

	tiles = { "aurora_tech_entity_remote_drone.png" },
	mesh = "aurora_tech_tool_remote_drone_detonate.b3d",

	range = 0,
	groups = {not_in_creative_inventory = 1},
}, function(_, placer) minetest.after(0, function() exit_drone(placer:get_player_name()) end) end)

local t = 0
minetest.register_globalstep(function(delta)
	t = t + delta
	if t < 0.1 then return end
	t = t - 0.1

	for p,_ in pairs(drone_refs) do
		local player = minetest.get_player_by_name(p)

		if vector.length(player:get_player_velocity()) > 0 then
			local texture = player:get_properties().textures[1]
			if texture == "aurora_tech_entity_remote_drone.png" then texture = "aurora_tech_entity_remote_drone_1.png"
			else texture = "aurora_tech_entity_remote_drone.png" end

			player:set_properties({textures = {texture}})
		end
	end
end)

minetest.register_craft({
  output = 'aurora_tech:drone_remote_16',
  recipe = {
      {'', '', 'aurora_tech:lava_charge'},
      {'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
      {'default:tin_ingot', 'aurora_tech:empowered_diamond', 'default:tin_ingot'},
  },
})
