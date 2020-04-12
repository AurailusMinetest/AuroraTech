local gun_projectiles = {}

local function shoot_gun(player)
	local name = player:get_player_name()

	if gun_projectiles[name] then 
		gun_projectiles[name]:trigger_teleport()
		return false
	end

	local pos = vector.add(player:get_pos(), {x = 0, y = 1.35, z = 0})
 	local dir = player:get_look_dir()

 	minetest.sound_play("aurora_tech_blink_launcher_send", {pos = pos, max_hear_distance = 8, gain = 0.8}, true)

	local ent = minetest.add_entity(pos, "aurora_tech:blink_launcher_bullet", minetest.serialize({shooter = name}))
	ent:set_velocity(vector.add(vector.multiply(dir, 16), vector.multiply(player:get_player_velocity(), 0.25)))

	return true
end

local function gun_dead(player)
	local pos = player:get_pos()
 	minetest.sound_play("aurora_tech_blink_launcher_no_power", {pos = pos, max_hear_distance = 8}, true)
end

aurora_tech.register_tool_3d("aurora_tech:blink_launcher", {
	description = "Blink Launcher",
	tiles = { "aurora_tech_tool_blink_launcher.png" },
	mesh = "aurora_tech_tool_blink_launcher.b3d",
	inventory_image = "aurora_tech_icon_blink_launcher.png",
	range = 0,
}, function(_, placer) return shoot_gun(placer) end, 80, true, function(_, placer) gun_dead(placer) end)

minetest.register_entity("aurora_tech:blink_launcher_bullet", {
	initial_properties = {
		visual = "sprite",
		textures = {"aurora_tech_particle_blink_launcher_bullet.png"},
		visual_size = {x = 0.2, y = 0.2},

		physical = false,
		collide_with_objects = false,
		collisionbox = {},

		glow = 14
	},

	on_activate = function(self, static)
		self.shooter = minetest.deserialize(static).shooter
		self.lifetime = 0

		self.object:set_armor_groups({ immortal = 1 })

		gun_projectiles[self.shooter] = self
	end,

	get_staticdata = function(self)
		return minetest.serialize({shooter = self.shooter})
	end,

	on_step = function(self, delta)
		self.lifetime = self.lifetime + delta
		if self.lifetime > 2 then 
			for i = 0, 20 do
				local dead_opac = 180 + math.floor(math.random() * 70)
				local frame = math.floor(math.random() * 4)
				minetest.add_particle({
					pos = vector.add(self.object:get_pos(), vector.new((math.random() - 0.5) * 0.5, (math.random() - 0.5) * 0.5, (math.random() - 0.5) * 0.5)),
					velocity = {x = 0, y = -0.05, z = 0},

					expirationtime = math.random() * 0.25 + 0.25,
					size = 3,
					collisiondetection = false,

					texture = "aurora_tech_particle_blink_launcher_trail.png^[verticalframe:4:" .. frame .. 
					"^(aurora_tech_particle_blink_launcher_trail_dead.png^[verticalframe:4:" .. frame .. "^[opacity:" .. tostring(dead_opac) .. ")",
					glow = 14
				})
			end
			self:remove() 
 			minetest.sound_play("aurora_tech_blink_launcher_timeout", {to_player = self.shooter, gain = 0.4}, true)
			return 
		end

		local dead_opac = math.floor(math.pow(self.lifetime / 2, 3) * 255)
		local frame = math.floor(self.lifetime * 5) % 4

		if (math.floor(self.lifetime * 16) % 2 == 0) then
			minetest.add_particle({
				pos = vector.add(vector.add(self.object:get_pos(), vector.multiply(self.object:get_velocity(), -0.125)), 
					vector.new((math.random() - 0.5) * 0.125, (math.random() - 0.5) * 0.125, (math.random() - 0.5) * 0.125)),
				velocity = {x = 0, y = -0.05, z = 0},

				expirationtime = 0.5,
				size = 1,
				collisiondetection = false,

				texture = "aurora_tech_particle_blink_launcher_trail.png^[verticalframe:4:" .. frame .. 
				"^(aurora_tech_particle_blink_launcher_trail_dead.png^[verticalframe:4:" .. frame .. "^[opacity:" .. tostring(dead_opac + 40) .. ")",
				glow = 14
			})
		end

		self.object:set_properties({
			textures = {"aurora_tech_particle_blink_launcher_bullet.png^[verticalframe:4:" .. frame .. 
				"^(aurora_tech_particle_blink_launcher_bullet_dead.png^[verticalframe:4:" .. frame .. "^[opacity:" .. tostring(dead_opac) .. ")"}
		})

		local node_def = minetest.registered_nodes[minetest.get_node(self.object:get_pos()).name]

		if not node_def or node_def.walkable then
			self:trigger_teleport()
		end
	end,

	trigger_teleport = function(self)
		local player = minetest.get_player_by_name(self.shooter)
		if not player then self:remove() return end

		local test = vector.add(self.object:get_pos(), {x = 0, y = -1.3, z = 0})
		local back = vector.multiply(vector.normalize(self.object:get_velocity()), -1)

		local valid = nil

		while valid == nil do
			if self:test_empty(test) then valid = test
			elseif self:test_empty(vector.add(test, {x = 0, y = 1, z = 0})) then valid = vector.add(test, {x = 0, y = 1, z = 0})
			elseif self:test_empty(vector.add(test, {x = 0, y = 2, z = 0})) then valid = vector.add(test, {x = 0, y = 2, z = 0})
			elseif self:test_empty(vector.add(test, {x = 0, y = -1, z = 0})) then valid = vector.add(test, {x = 0, y = -1, z = 0}) end

			test = vector.add(test, back)
		end

		player:set_pos(valid)
		local on_ground = minetest.get_node(vector.add(player:get_pos(), {x = 0, y = -0.8, z = 0})).name ~= "air"
		local add_vel = vector.multiply(self.object:get_velocity(), on_ground and 1 or 0.5)
		player:add_player_velocity(add_vel)
		
	 	minetest.sound_play({name = "aurora_tech_blink_launcher_recv"}, {pos = valid, max_hear_distance = 8}, true)

		for i = 0, 60 do
			local frame = math.floor(math.random() * 4)
			minetest.add_particle({
				pos = vector.add(vector.add(valid, vector.new((math.random() - 0.5) * 2, 1.3 + (math.random() - 0.5) * 2, (math.random() - 0.5) * 2)), vector.multiply(add_vel, 0.135)),
				velocity = {x = 0, y = -0.05, z = 0},

				expirationtime = math.random() * 0.25 + 0.25,
				size = 3,
				collisiondetection = false,

				texture = "aurora_tech_particle_blink_launcher_trail.png^[verticalframe:4:" .. frame,
				glow = 14
			})
		end

		self:remove()
	end,
	test_empty = function(self, pos)
		return minetest.get_node(pos).name == "air" and minetest.get_node(vector.add(pos, {x = 0, y = 1, z = 0})).name == "air"
	end,
	remove = function(self)
		gun_projectiles[self.shooter] = nil
		self.object:remove()
	end
})

minetest.register_craft({
  output = 'aurora_tech:blink_launcher_16',
  recipe = {
      {'', 'default:obsidian_glass', ''},
      {'default:tin_ingot', 'aurora_tech:empowered_diamond', 'default:steel_ingot'},
      {'', 'default:copper_ingot', 'default:steel_ingot'},
  },
})

aurora_tech.register_repair("aurora_tech:blink_launcher", "aurora_tech:empowered_diamond", 6)
