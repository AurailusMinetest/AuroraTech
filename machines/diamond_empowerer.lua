minetest.register_node("aurora_tech:diamond_empowerer", {
	description = "Diamond Empowerer",
	drawtype = "mesh",
	mesh = "aurora_tech_node_diamond_empowerer.b3d",
	tiles = {"aurora_tech_node_diamond_empowerer.png"},
	groups = {cracky = 3, stone = 1},

	selection_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 23.5 / 16, 7 / 16},
    },
	},
	collision_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 23.5 / 16, 7 / 16},
    },
	},

	on_rightclick = function(pos, node, clicker, itemstack)
		minetest.sound_play("aurora_tech_interact", {pos = pos, max_hear_distance = 8}, true)
		local meta = minetest.get_meta(pos) 
		if itemstack:get_name() == "default:diamond" then
			itemstack:take_item()
			minetest.set_node(pos, {name = "aurora_tech:diamond_empowerer_active"})
			return itemstack
		end
	end
})


minetest.register_node("aurora_tech:diamond_empowerer_active", {
	description = "Diamond Empowerer",
	drawtype = "mesh",
	mesh = "aurora_tech_node_diamond_empowerer_active.b3d",
	tiles = {"aurora_tech_node_diamond_empowerer.png"},
	groups = { not_in_creative_inventory = 1, cracky = 3, stone = 1 },
	drop = "aurora_tech:diamond_empowerer",
	light_source = 4,

	selection_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 23.5 / 16, 7 / 16},
    },
	},
	collision_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 23.5 / 16, 7 / 16},
    },
	},

	on_rightclick = function(pos, node, clicker, itemstack)
		minetest.sound_play("combat_interact", {pos = pos, max_hear_distance = 8}, true)
		if itemstack:get_name() == "" then
			itemstack:replace("default:diamond")
			minetest.set_node(pos, {name = "aurora_tech:diamond_empowerer"})
			return itemstack
		else
			local diamond = ItemStack("default:diamond")
			local inv = clicker:get_inventory()

			if (inv:room_for_item("main", diamond)) then
				minetest.after(0, function() inv:add_item("main", diamond) end)
				minetest.set_node(pos, {name = "aurora_tech:diamond_empowerer"})
			end
		end
	end,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)

		meta:set_float("progress", 0)
	end,

	_aurora_tech_power = function(pos)
		local meta = minetest.get_meta(pos)
		if meta:get_float("progress", 0) >= 60 then
			minetest.set_node(pos, {name = "aurora_tech:diamond_empowerer_complete"})
			return
		end

		meta:set_float("progress", meta:get_float("progress")  + 1)

		for i = 0, 4 do
			local frame = math.floor(math.random() * 6)

			minetest.add_particle({
				pos = vector.add(pos, vector.new((math.random() - 0.5) * 0.6, 0.6 + (math.random() - 0.5) * 0.6, (math.random() - 0.5) * 0.6)),
				velocity = vector.new((math.random() - 0.5) * 0.9, (math.random() - 0.5) * 0.9, (math.random() - 0.5) * 0.9),

				expirationtime = math.random() * 0.15 + 0.05,
				size = 3,
				collisiondetection = false,

				texture = "aurora_tech_particle_diamond_empowerer_active.png^[verticalframe:6:" .. frame,
				glow = 5
			})
		end
	end
})

minetest.register_node("aurora_tech:diamond_empowerer_complete", {
	description = "Diamond Empowerer",
	drawtype = "mesh",
	mesh = "aurora_tech_node_diamond_empowerer_active.b3d",
	tiles = {"aurora_tech_node_diamond_empowerer_complete.png"},
	groups = { not_in_creative_inventory = 1, cracky = 3, stone = 1 },
	drop = "aurora_tech:diamond_empowerer",
	light_source = 10,

	selection_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 23.5 / 16, 7 / 16},
    },
	},
	collision_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 23.5 / 16, 7 / 16},
    },
	},

	on_construct = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(0.2)
	end,

	on_timer = function(pos)
		for i = 0, 4 do
			local frame = math.floor(math.random() * 4)

			minetest.add_particle({
				pos = vector.add(pos, vector.new((math.random() - 0.5) * 0.5, 0.6 + (math.random() - 0.5) * 0.5, (math.random() - 0.5) * 0.5)),
				velocity = vector.new((math.random() - 0.5) * 0.5, (math.random() - 0.5) * 0.5, (math.random() - 0.5) * 0.5),
				acceleration = vector.new(0, 5, 0),

				expirationtime = math.random() * 0.25 + 0.10,
				size = 2,
				collisiondetection = false,

				texture = "aurora_tech_particle_diamond_empowerer_complete.png^[verticalframe:4:" .. frame,
				glow = 5
			})
		end

		return true
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		local diamond = ItemStack("aurora_tech:empowered_diamond")
		local inv = clicker:get_inventory()

		if (inv:room_for_item("main", diamond)) then
			minetest.after(0, function() inv:add_item("main", diamond) end)
			minetest.set_node(pos, {name = "aurora_tech:diamond_empowerer"})
			minetest.sound_play("aurora_tech_empowered_diamond_pickup", {pos = pos, max_hear_distance = 8}, true)
		end
	end
})

minetest.register_craft({
  output = 'aurora_tech:diamond_empowerer',
  recipe = {
      {'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
      {'default:glass', 'default:diamondblock', 'default:glass'},
      {'default:ice', 'aurora_tech:mese_generator', 'default:ice'},
  },
})
