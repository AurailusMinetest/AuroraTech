local warp_wielders = {}

local function equip(p)
	warp_wielders[p:get_player_name()] = { state = false, lastPressed = 0 }
end

local function unequip(p)
	warp_wielders[p:get_player_name()] = nil
end

minetest.register_on_leaveplayer(function(player)
	unequip(player)
end)

armor:register_armor("aurora_tech:warp_boots", {
	description = "Warp Boots",
	inventory_image = "aurora_tech_icon_warp_boots.png",
	texture = "aurora_tech_model_warp_boots.png",
	preview = "aurora_tech_armor_warp_boots.png",
	groups = { armor_feet = 1, armor_use = 500 },
	armor_groups = { fleshy = 10, radiation = 10 },
	damage_groups = { cracky = 3, snappy = 3, choppy = 3, crumbly = 3, level = 1 },
	reciprocate_damage = true,

	on_equip = equip,
	on_unequip = unequip,
	on_destroy = unequip
})

local function attempt_teleport(player)
	local off = vector.multiply(vector.normalize({x = player:get_look_dir().x, y = 0.05, z = player:get_look_dir().z}), 3)
	local target = vector.add(player:get_pos(), off)

	if minetest.registered_nodes[minetest.get_node(target).name].walkable or minetest.registered_nodes[minetest.get_node(vector.add(target, vector.new(0, 1, 0))).name].walkable then
		minetest.sound_play("aurora_tech_warp_boots_fail", {pos = player:get_pos(), max_hear_distance = 8}, true)
	else
		minetest.sound_play("aurora_tech_warp_boots_warp", {pos = player:get_pos(), gain = 0.7, max_hear_distance = 8}, true)

		local move_step = 0

		local function partial_move()
			local target = vector.add(player:get_pos(), vector.multiply(off, 0.33))
			
			player:set_pos(target)

			move_step = move_step + 1
			if move_step <= 3 then
				minetest.after(1/60, partial_move)
			end
		end
		partial_move()

		minetest.after(3/60, function ()
			player:add_player_velocity(vector.multiply(off, 3))
		end)
	end
end

local time = 0
minetest.register_globalstep(function(delta)
	time = time + delta

	for name, props in pairs(warp_wielders) do
		local down = minetest.get_player_by_name(name):get_player_control().up
		
		if down then
			if not props.state then
				if time - props.lastPressed < 0.4 then
					attempt_teleport(minetest.get_player_by_name(name))
					props.state = true
					props.lastPressed = 0
				else
					props.state = true
					props.lastPressed = time
				end
			end
		else
			props.state = false
		end
	end

end)

minetest.register_craft({
  output = 'aurora_tech:warp_boots',
  recipe = {
      {'aurora_tech:empowered_diamond', '', 'aurora_tech:empowered_diamond'},
      {'default:copper_ingot', '', 'default:copper_ingot'},
      {'default:steel_ingot', '', 'default:steel_ingot'},
  },
})
