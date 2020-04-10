minetest.register_node("combat:mese_generator", {
	description = "Mese Generator",
	drawtype = "mesh",
	mesh = "combat_mese_charger.b3d",
	tiles = {"combat_mese_charger.png"},
	groups = {cracky = 3, stone = 1},

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
		if itemstack:get_name() == "default:mese_crystal" then
			itemstack:take_item()
			minetest.set_node(pos, {name = "combat:mese_generator_active"})
			return itemstack
		end
	end
})

minetest.register_node("combat:mese_generator_active", {
	description = "Mese Generator",
	drawtype = "mesh",
	mesh = "combat_mese_charger_active.b3d",
	tiles = {"combat_mese_charger_active.png"},
	groups = { not_in_creative_inventory = 1, cracky = 3, stone = 1 },
	drop = "combat:mese_generator",
	light_source = 9,

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

	on_dig = function(pos)
		if minetest.registered_nodes["tnt:tnt"] ~= nil then
			tnt.boom(pos, {radius = 4})
		end
	end,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local timer = minetest.get_node_timer(pos)

		meta:set_float("power_left", 50)
		timer:start(0.3)
	end,
	on_timer = function(pos)
		local meta = minetest.get_meta(pos)
		if meta:get_float("power_left", 0) <= 0 then
			minetest.set_node(pos, {name = "combat:mese_generator"})
			return false
		end

		local consumed = 1

		for i = 0, 4 do
			local frame = math.floor(math.random() * 6)

			minetest.add_particle({
				pos = vector.add(pos, vector.new((math.random() - 0.5) * 0.6, 0.6 + (math.random() - 0.5) * 0.6, (math.random() - 0.5) * 0.6)),
				velocity = vector.new((math.random() - 0.5) * 0.9, (math.random() - 0.5) * 0.9, (math.random() - 0.5) * 0.9),

				expirationtime = math.random() * 0.15 + 0.05,
				size = 3,
				collisiondetection = false,

				texture = "combat_mese_charger_particle.png^[verticalframe:6:" .. frame,
				glow = 5
			})
		end

		local check = vector.add(pos, {x = 0, y = 0, z = -1})
		if (minetest.registered_nodes[minetest.get_node(check).name]._combat_power ~= nil) then 
			minetest.registered_nodes[minetest.get_node(check).name]._combat_power(check)
			consumed = consumed + 0.5
		end
		check = vector.add(pos, {x = 0, y = 0, z = 1})
		if (minetest.registered_nodes[minetest.get_node(check).name]._combat_power ~= nil) then 
			minetest.registered_nodes[minetest.get_node(check).name]._combat_power(check) 
			consumed = consumed + 0.5
		end
		check = vector.add(pos, {x = -1, y = 0, z = 0})
		if (minetest.registered_nodes[minetest.get_node(check).name]._combat_power ~= nil) then 
			minetest.registered_nodes[minetest.get_node(check).name]._combat_power(check) 
			consumed = consumed + 0.5
		end
		check = vector.add(pos, {x = 1, y = 0, z = 0})
		if (minetest.registered_nodes[minetest.get_node(check).name]._combat_power ~= nil) then 
			minetest.registered_nodes[minetest.get_node(check).name]._combat_power(check) 
			consumed = consumed + 0.5
		end


		meta:set_float("power_left", meta:get_float("power_left") - consumed)

		return true
	end
})

minetest.register_craft({
  output = 'combat:mese_generator',
  recipe = {
      {'default:steel_ingot', 'default:mese_crystal', 'default:steel_ingot'},
      {'default:tin_ingot', 'default:copperblock', 'default:tin_ingot'},
      {'default:steelblock', 'default:steelblock', 'default:steelblock'},
  },
})
