aurora_tech = {}

local function register_tool(name, defs, cb)
	defs.drawtype = "mesh"
	defs.node_placement_prediction = "air"

	defs.on_place = cb
	defs.on_secondary_use = cb

	defs.stack_max = defs.stack_max or 1

	minetest.register_node(name, defs)
end

local function register_tool_durability(name, defs, cb, dura, auto, cb_dead)
	local count = math.min(dura, 16)

	if auto then
		local old_cb = cb
		cb = function(itemstack, placer, pt)
			old_cb(itemstack, placer, pt)
			return aurora_tech.damage_tool(itemstack)
		end
	end

	for i = 1, count do
		local cb = cb
		if i == 1 then cb = cb_dead end

		local factor = (i - 1) / (count - 1)
		local pixels = math.floor(factor * 16)
		local opac = 255 - math.floor(factor * 255)

		local defs = table.copy(defs)
		local groups = table.copy(defs.groups or {})
		if i ~= count then groups["not_in_creative_inventory"] = 1 end
		defs._aurora_tech_dura = dura
		defs._aurora_tech_name = name
		defs.groups = groups
		defs.inventory_image =
			defs.inventory_image .. "^((aurora_tech_ui_durability_full.png^[resize:" .. pixels .. "x16)^(aurora_tech_ui_durability_empty.png^[resize:" .. pixels .. "x16^[opacity:" .. opac .. ")^[mask:aurora_tech_ui_durability_mask.png)"
		register_tool(name .. "_" .. i, defs, cb)
	end
end

aurora_tech.register_tool_3d = function(name, defs, cb, dura, auto, cb_dead)
	if dura == nil then register_tool(name, defs, cb)
	else register_tool_durability(name, defs, cb, dura, auto, cb_dead) end
end

aurora_tech.register_repair = function(tool, material, amount, return_tool)
	if return_tool == nil then return_tool = tool end

	local tool_dura = math.min(minetest.registered_nodes[tool .. "_1"]._aurora_tech_dura, 16)

	for i = 1, tool_dura - 1 do
		for j = 1, 8 do
			local recipe = { tool .. "_" .. i }
			local res = i + amount * j

			for k = 1, j do
				table.insert(recipe, material)
			end

			minetest.register_craft({
	      type = "shapeless",
	      output = return_tool .. "_" .. math.min(res, tool_dura),
	      recipe = recipe
			})

			if res >= tool_dura then
				break
			end
		end
	end
end

aurora_tech.damage_tool = function(itemstack)
	if not itemstack or not minetest.registered_nodes[itemstack:get_name()] then return itemstack end

	local dura = minetest.registered_nodes[itemstack:get_name()]._aurora_tech_dura
	local name = minetest.registered_nodes[itemstack:get_name()]._aurora_tech_name

	if dura <= 16 then
		itemstack:replace(name .. "_" .. (itemstack:get_name():sub(name:len() + 2) - 1))
		return itemstack
	else
		local max_uses = math.floor(dura / 16)
		local meta = itemstack:get_meta()
		meta:set_int("uses", meta:get_int("uses", 0) + 1)

		if meta:get_int("uses", 0) >= max_uses then
			itemstack:replace(name .. "_" .. (itemstack:get_name():sub(name:len() + 2) - 1))
		end

		return itemstack
	end
end
