minetest.register_node("aurora_tech:lava_charge", {
	description = "Lava Charge",
	tiles = { "aurora_tech_node_lava_crucible_complete.png" },
	drawtype = "mesh",
	mesh = "aurora_tech_node_lava_charge.b3d",
	light_source = 10,
	groups = {cracky = 1, level = 2},

	selection_box = {
    type = "fixed",
    fixed = { {-2 / 16, -2 / 16, -2 / 16, 2 / 16, 2 / 16, 2 / 16} }
	},
	collision_box = {
    type = "fixed",
    fixed = { {-2 / 16, -2 / 16, -2 / 16, 2 / 16, 2 / 16, 2 / 16} },
	},
})

minetest.register_node("aurora_tech:lava_core", {
	description = "Lava Charge",
	tiles = { "aurora_tech_node_lava_crucible_active.png" },
	drawtype = "mesh",
	mesh = "aurora_tech_node_lava_core.b3d",
	light_source = 14,
	groups = {cracky = 1, level = 2},

	selection_box = {
    type = "fixed",
    fixed = { {-5 / 16, -5 / 16, -5 / 16, 5 / 16, 5 / 16, 5 / 16} }
	},
	collision_box = {
    type = "fixed",
    fixed = { {-5 / 16, -5 / 16, -5 / 16, 5 / 16, 5 / 16, 5 / 16} }
	},
})


minetest.register_craft({
  output = 'aurora_tech:lava_core',
  recipe = {
    {'aurora_tech:lava_charge', 'aurora_tech:lava_charge', 'aurora_tech:lava_charge'},
    {'aurora_tech:lava_charge', 'aurora_tech:lava_charge', 'aurora_tech:lava_charge'},
    {'aurora_tech:lava_charge', 'aurora_tech:lava_charge', 'aurora_tech:lava_charge'}
  },
})
