minetest.register_node("aurora_tech:recharger", {
	description = "Recharger",
	drawtype = "mesh",
	mesh = "aurora_tech_node_recharger.b3d",
	tiles = {"aurora_tech_node_recharger.png", "[combine:16x16"},
	groups = {cracky = 3, stone = 1},
	paramtype2 = "facedir",

	selection_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 4 / 16, 7 / 16},
    },
	},
	collision_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 4 / 16, 7 / 16},
    },
	},

	on_rightclick = function(pos, node, clicker, itemstack)
		if itemstack:get_name():sub(0, ("aurora_tech:drone_remote"):len()) == "aurora_tech:drone_remote" then
			minetest.sound_play("aurora_tech_interact", {pos = pos, max_hear_distance = 8}, true)

			minetest.swap_node(pos, {name = "aurora_tech:recharger_charging_1", param2 = minetest.get_node(pos).param2})
			minetest.get_meta(pos):set_float("charge_done", itemstack:get_name():sub(("aurora_tech:drone_remote_0"):len()))

			local timer = minetest.get_node_timer(pos)
			timer:set(0.5, 0.4)

			itemstack:take_item()
			return itemstack
		end
	end
})
textures = {"aurora_tech_node_recharger_charging.png", "aurora_tech_node_recharger_charging_1.png"}
for i = 1, 2 do
	minetest.register_node("aurora_tech:recharger_charging_" .. i, {
		description = "Recharger",
		drawtype = "mesh",
		mesh = "aurora_tech_node_recharger.b3d",
		tiles = {textures[i], "aurora_tech_tool_drone_remote.png"},
		paramtype2 = "facedir",

		drop = "aurora_tech:recharger",
		light_source = 10,

		selection_box = {
	    type = "fixed",
	    fixed = {
	        {-7 / 16, -0.5, -7 / 16, 7 / 16, 4 / 16, 7 / 16},
	    },
		},
		collision_box = {
	    type = "fixed",
	    fixed = {
	        {-7 / 16, -0.5, -7 / 16, 7 / 16, 4 / 16, 7 / 16},
	    },
		},

		on_timer = function(pos)
			if minetest.get_node(pos).name == "aurora_tech:recharger_charging_1" then
				minetest.swap_node(pos, {name = "aurora_tech:recharger_charging_2", param2 = minetest.get_node(pos).param2})
			else 
				minetest.swap_node(pos, {name = "aurora_tech:recharger_charging_1", param2 = minetest.get_node(pos).param2})
			end

			local powered = 
				minetest.get_node(vector.add(pos, {x = 0, y = 0, z = 1})).name == "aurora_tech:mese_generator_active" or
				minetest.get_node(vector.add(pos, {x = 0, y = 0, z = -1})).name == "aurora_tech:mese_generator_active" or
				minetest.get_node(vector.add(pos, {x = 1, y = 0, z = 0})).name == "aurora_tech:mese_generator_active" or
				minetest.get_node(vector.add(pos, {x = -1, y = 0, z = 0})).name == "aurora_tech:mese_generator_active"

			if not powered then
				minetest.swap_node(pos, {name = "aurora_tech:recharger_no_power", param2 = minetest.get_node(pos).param2})
			end

			return true
		end,

		_aurora_tech_power = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_float("charge_done", meta:get_float("charge_done", 0) + 0.25)
			if meta:get_float("charge_done") >= 16 then
				minetest.set_node(pos, {name = "aurora_tech:recharger_complete", param2 = minetest.get_node(pos).param2})
			end
		end,

		on_rightclick = function(pos, node, clicker, itemstack)
			minetest.sound_play("combat_interact", {pos = pos, max_hear_distance = 8}, true)
			local meta = minetest.get_meta(pos)
			local remote = ItemStack("aurora_tech:drone_remote_" .. math.floor(meta:get_float("charge_done")))
			local inv = clicker:get_inventory()
			if (inv:room_for_item("main", remote)) then
				minetest.after(0, function() inv:add_item("main", remote) end)
				minetest.set_node(pos, {name = "aurora_tech:recharger", param2 = minetest.get_node(pos).param2})
			end
		end,
	})
end

minetest.register_node("aurora_tech:recharger_no_power", {
	description = "Recharger",
	drawtype = "mesh",
	mesh = "aurora_tech_node_recharger.b3d",
	tiles = {"aurora_tech_node_recharger_no_power.png", "aurora_tech_tool_drone_remote.png"},
	light_source = 3,
	paramtype2 = "facedir",

	selection_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 4 / 16, 7 / 16},
    },
	},
	collision_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 4 / 16, 7 / 16},
    },
	},

	drop = "aurora_tech:recharger",

	_aurora_tech_power = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:set(0.5, 0.4)
		minetest.swap_node(pos, {name = "aurora_tech:recharger_charging_1", param2 = minetest.get_node(pos).param2})
	end,

	on_rightclick = function(pos, node, clicker, itemstack)
		minetest.sound_play("combat_interact", {pos = pos, max_hear_distance = 8}, true)
		local meta = minetest.get_meta(pos)
		local remote = ItemStack("aurora_tech:drone_remote_" .. math.floor(meta:get_float("charge_done")))
		local inv = clicker:get_inventory()
		if (inv:room_for_item("main", remote)) then
			minetest.after(0, function() inv:add_item("main", remote) end)
			minetest.set_node(pos, {name = "aurora_tech:recharger", param2 = minetest.get_node(pos).param2})
		end
	end,
})


minetest.register_node("aurora_tech:recharger_complete", {
	description = "Recharger",
	drawtype = "mesh",
	mesh = "aurora_tech_node_recharger.b3d",
	tiles = {"aurora_tech_node_recharger_complete.png", "aurora_tech_tool_drone_remote.png"},
	paramtype2 = "facedir",

	drop = "aurora_tech:recharger",
	light_source = 15,

	selection_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 4 / 16, 7 / 16},
    },
	},
	collision_box = {
    type = "fixed",
    fixed = {
        {-7 / 16, -0.5, -7 / 16, 7 / 16, 4 / 16, 7 / 16},
    },
	},

	on_rightclick = function(pos, node, clicker, itemstack)
		minetest.sound_play("combat_interact", {pos = pos, max_hear_distance = 8}, true)
		local meta = minetest.get_meta(pos)
		local remote = ItemStack("aurora_tech:drone_remote_16")
		local inv = clicker:get_inventory()
		if (inv:room_for_item("main", remote)) then
			minetest.after(0, function() inv:add_item("main", remote) end)
			minetest.set_node(pos, {name = "aurora_tech:recharger", param2 = minetest.get_node(pos).param2})
		end
	end,
})

minetest.register_craft({
  output = 'aurora_tech:recharger',
  recipe = {
      {'default:steel_ingot', 'default:glass', 'default:steel_ingot'},
      {'default:tin_ingot', 'default:mese_crystal', 'default:tin_ingot'},
      {'default:steelblock', 'aurora_tech:mese_generator', 'default:steelblock'},
  },
})
