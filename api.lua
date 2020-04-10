combat = {}
minetest.register_on_mods_loaded(function() combat = nil end)

combat.register_tool_3d = function(name, defs, cb)
	defs.drawtype = "mesh"
	defs.node_placement_prediction = "air"

	defs.on_place = cb
	defs.on_secondary_use = cb

	defs.stack_max = defs.stack_max or 1

	minetest.register_node(name, defs)
end
