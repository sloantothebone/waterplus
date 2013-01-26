-- Water Plus
-- By Rubenwardy
-- License: cc-by-sa

-- Setup Finite
waterplus.finite_water_inc=1/(waterplus.finite_water_steps /(1+waterplus.finite_water_inc_skip))
waterplus.finite_water_max=1.43/waterplus.finite_water_inc --how many finite water values (give a new style water effect)

-- Debug log print settings
dPrint("Water steps: "..waterplus.finite_water_steps)
dPrint("Water max: "..waterplus.finite_water_max)
dPrint("Water inc: "..waterplus.finite_water_inc)
dPrint("Water inc_skip: "..waterplus.finite_water_inc_skip)

-- Locals
local h=waterplus.finite_water_inc
local c=1

dPrint("C: "..c)
dPrint("H: "..h)

-- Block create function
waterplus.finite_blocks = {}
waterplus.register_step = function(a,height)
	print("Register finite block "..a.." with a height of "..height)
	minetest.register_node("waterplus:finite_"..a, {
		description = "Finite Water "..a,
		tiles = {
                       {name="default_water_source_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}}
		},
		drawtype = "nodebox",
		paramtype = "light",
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		post_effect_color = {a=64, r=100, g=100, b=200},
		groups = {water=3,finite_water=((a/waterplus.finite_water_steps)*100), puts_out_fire=1},
		node_box = {
			type="fixed",
			fixed={
				{-0.5,-0.5,-0.5,0.5,height-0.5,0.5},
			},
		},
	})
	table.insert(waterplus.finite_blocks,"waterplus:finite_"..a)
	bucket.register_liquid(
		"waterplus:finite_"..a,
		"",
		":bucket:bucket_finite_"..a,
		"bucket_water.png"
	)
end

--Create blocks
for a=1, waterplus.finite_water_max do
	c=c+1
	
	if c>waterplus.finite_water_inc_skip then
        	c = 0
        	h = h + waterplus.finite_water_inc
	end

	waterplus.register_step(a,h)
end

--The ABM
minetest.register_abm({
	nodenames = waterplus.finite_blocks,
	interval = 1/10,
	chance = 1,
	action = function(pos,node)
		local node_id = getNumberFromName(node.name)

		dPrint("")
		dPrint("Waterplus [finite] - Calculating for "..node_id.." at "..pos.x..","..pos.y..","..pos.z)
		
		local target = {x=pos.x,y=pos.y,z=pos.z}
		target.y=target.y-1
		dPrint(target.x..","..target.z)
		performDrop(pos,target)

		target = {x=pos.x,y=pos.y,z=pos.z}
		target.x=target.x+1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)

		target = {x=pos.x,y=pos.y,z=pos.z}
		target.x=target.x-1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)

		target = {x=pos.x,y=pos.y,z=pos.z}
		target.z=target.z+1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)
		
		target = {x=pos.x,y=pos.y,z=pos.z}
		target.z=target.z-1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)

		target = {x=pos.x,y=pos.y,z=pos.z}
		target.x=target.x+1
		target.z=target.z+1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)

		target = {x=pos.x,y=pos.y,z=pos.z}
		target.x=target.x+1
		target.z=target.z-1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)

		target = {x=pos.x,y=pos.y,z=pos.z}
		target.x=target.x-1
		target.z=target.z+1
		dPrint(target.x..","..target.z)
		performFlow(pos,target)

		dPrint("--Calculation Complete")
		dPrint("")
	end,
})

-- name (string)
function getNumberFromName(name)
	return tonumber(string.gsub(name, "waterplus:finite_", ""),10)
end

--from (pos): position of the node the abm is being run on
--to (pos): position of the node to check
function performFlow(from,to)
	dPrint("> Flow Calculation")
	local target = minetest.env:get_node(to).name
	local target_id = getNumberFromName(target)
	local source = minetest.env:get_node(from).name
	local id = getNumberFromName(source)
	
	if id == nil then
	   id = 0
	end

	if target ~= "air" and tonumber(target_id) == nil then
		dPrint("  > Exit on is not finite liquid")
		return
	end

	if target_id == nil then
		target_id=0
	end
	
	dPrint("  > Testing Heights: "..id.." vs "..target_id)

	if id == 1 and target_id == 0 and math.random(1,4) == 1 then
		if performDrop(from, {x=to.x,y=to.y-1,z=to.z}) then 
			return 
		end
	end

	if id > target_id and id > 0 then
		dPrint("    > Flowing")

		local nh_to = "waterplus:finite_"..(target_id+1)
		local nh_from = "waterplus:finite_"..(id-1)

		if (id-1) < 1 or (target_id+1) > waterplus.finite_water_max then
			dPrint("    > Exit on too high, or too low")
			return
		end
		
		minetest.env:set_node(from,{name = nh_from})
		minetest.env:set_node(to,{name = nh_to})

		dPrint("    > Done")
	end
end

--from (pos): position of the node the abm is being run on
--to (pos): position of the node to check
function performDrop(from,to)
	dPrint("> Drop Calculation")
	local target = minetest.env:get_node(to).name
	local target_id = getNumberFromName(target)
	local source = minetest.env:get_node(from).name
	local id = getNumberFromName(source)

	if target ~= "air" and tonumber(target_id) == nil then
		dPrint("  > Exit on is not finite liquid")
		return
	end

	if target_id == nil then
		target_id=0
	end
	
	if id == nil then
	   id = 0
	end

	target_id = target_id + id
	id=0

	if target_id > waterplus.finite_water_max then
	   id = target_id - waterplus.finite_water_max
	   target_id = waterplus.finite_water_max
	end

	local nh_to = "waterplus:finite_"..(target_id)
	local nh_from = "waterplus:finite_"..(id)

	if id == 0 or id == nil then
	   nh_from = "air"
	end

	minetest.env:set_node(from,{name = nh_from})
	minetest.env:set_node(to,{name = nh_to})

	return 1

end

minetest.register_alias("default:water_source","waterplus:finite_20")
minetest.register_alias("default:water_flowing","waterplus:finite_10")

minetest.register_craftitem(":bucket:bucket_water", {
	inventory_image = "bucket_water.png",
	stack_max = 1,
	liquids_pointable = true,
	on_use = function(itemstack, user, pointed_thing)
		-- Must be pointing to node
		if pointed_thing.type ~= "node" then
			return
		end
		-- Check if pointing to a buildable node
		n = minetest.env:get_node(pointed_thing.under)
		if minetest.registered_nodes[n.name].buildable_to then
			-- buildable; replace the node
			minetest.env:add_node(pointed_thing.under, {name="waterplus:finite_20"})
		else
			-- not buildable to; place the liquid above
			-- check if the node above can be replaced
			n = minetest.env:get_node(pointed_thing.above)
			if minetest.registered_nodes[n.name].buildable_to then
				minetest.env:add_node(pointed_thing.above, {name="waterplus:finite_20"})
			else
				-- do not remove the bucket with the liquid
				return
			end
		end
		return {name="bucket:bucket_empty"}
	end
})
