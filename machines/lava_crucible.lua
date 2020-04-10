minetest.register_node("combat:lava_crucible", {
	description = "Lava Crucible",
	drawtype = "mesh",
	mesh = "combat_lava_crucible.b3d",
	tiles = {"combat_lava_crucible.png"},
	groups = {cracky = 3, stone = 1},

	selection_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 7 / 16, 7 / 16},
    },
	},
	collision_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 7 / 16, 7 / 16},
    },
	},

	on_rightclick = function(pos, node, clicker, itemstack)
		if itemstack:get_name() == "bucket:bucket_lava" then
			itemstack:replace("bucket:bucket_empty")
			minetest.set_node(pos, {name = "combat:lava_crucible_active"})
			return itemstack
		end
	end
})


minetest.register_node("combat:lava_crucible_active", {
	description = "Lava Crucible",
	drawtype = "mesh",
	mesh = "combat_lava_crucible.b3d",
	tiles = {"combat_lava_crucible_active.png"},
	groups = { not_in_creative_inventory = 1, cracky = 3, stone = 1 },
	drop = "combat:lava_crucible",
	light_source = 12,

	selection_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 7 / 16, 7 / 16},
    },
	},
	collision_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 7 / 16, 7 / 16},
    },
	},

	on_rightclick = function(pos, node, clicker, itemstack)
		if itemstack:get_name() == "bucket:bucket_empty" then


			local lava = ItemStack("bucket:bucket_lava")
			local inv = clicker:get_inventory()

			if (inv:room_for_item("main", lava)) then
				itemstack:take_item()
				minetest.after(0, function() inv:add_item("main", lava) end)
				minetest.set_node(pos, {name = "combat:lava_crucible"})
				return itemstack
			end
		end
	end,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)

		meta:set_float("progress", 0)
	end,

	_combat_power = function(pos)
		local meta = minetest.get_meta(pos)
		if meta:get_float("progress", 0) >= 60 then
			minetest.sound_play("combat_core_create", {pos = pos, max_hear_distance = 8}, true)
			minetest.set_node(pos, {name = "combat:lava_crucible_complete"})
			return
		end

		meta:set_float("progress", meta:get_float("progress")  + 1)

		for i = 0, 2 do
			local frame = math.floor(math.random() * 4)

			minetest.add_particle({
				pos = vector.add(pos, vector.new((math.random() - 0.5) * 0.6, 0.4 + (math.random() - 0.5) * 0.2, (math.random() - 0.5) * 0.6)),
				velocity = vector.new(0, math.random() * 0.2 + 0.3, 0),

				expirationtime = math.random() * 0.65 + 0.35,
				size = 3,
				collisiondetection = false,

				texture = "combat_lava_crucible_particle_a.png^[verticalframe:4:" .. frame,
				glow = 5
			})
		end

		for i = 0, 4 do
			local frame = math.floor(math.random() * 4)

			minetest.add_particle({
				pos = vector.add(pos, vector.new((math.random() - 0.5) * 0.6, 0.4 + (math.random() - 0.5) * 0.2, (math.random() - 0.5) * 0.6)),
				velocity = vector.new(0, math.random() * 0.2 + 0.3, 0),

				expirationtime = math.random() * 0.35 + 0.10,
				size = 3,
				collisiondetection = false,

				texture = "combat_smoke_particle.png^[verticalframe:4:" .. frame,
				glow = 5
			})
		end
	end
})

minetest.register_node("combat:lava_crucible_complete", {
	description = "Lava Crucible",
	drawtype = "mesh",
	mesh = "combat_lava_crucible.b3d",
	tiles = {"combat_lava_crucible_complete.png"},
	groups = { not_in_creative_inventory = 1, cracky = 3, stone = 1 },
	drop = "combat:lava_crucible",
	light_source = 14,

	selection_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 7 / 16, 7 / 16},
    },
	},
	collision_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 7 / 16, 7 / 16},
    },
	},

	on_dig = function(pos)
		if minetest.registered_nodes["tnt:tnt"] ~= nil then
			tnt.boom(pos, {radius = 4})
		end
	end,

	on_construct = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(0.2)
	end,

	on_timer = function(pos)
		for i = 0, 4 do
			local frame = math.floor(math.random() * 4)

			minetest.add_particle({
				pos = vector.add(pos, vector.new((math.random() - 0.5) * 0.4, 0.1 + (math.random() - 0.5) * 0.4, (math.random() - 0.5) * 0.4)),
				velocity = vector.new((math.random() - 0.5) * 0.5, (math.random() - 0.5) * 0.5, (math.random() - 0.5) * 0.5),
				acceleration = vector.new(0, -3, 0),

				expirationtime = math.random() * 0.25 + 0.10,
				size = 2,
				collisiondetection = false,

				texture = "combat_lava_crucible_particle_b.png^[verticalframe:4:" .. frame,
				glow = 5
			})
		end

		return true
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		local charge = ItemStack("combat:lava_charge")
		local inv = clicker:get_inventory()

		if (inv:room_for_item("main", charge)) then
			minetest.after(0, function() inv:add_item("main", charge) end)
			minetest.set_node(pos, {name = "combat:lava_crucible"})
			minetest.sound_play("combat_diamond_pickup", {pos = pos, max_hear_distance = 8}, true)
		end
	end
})

-- minetest.register_craft({
--   output = 'combat:diamond_empowerer',
--   recipe = {
--       {'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
--       {'default:glass', 'default:diamondblock', 'default:glass'},
--       {'default:ice', 'combat:mese_generator', 'default:ice'},
--   },
-- })
