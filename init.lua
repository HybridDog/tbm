-- a tunnel boring machine
-- sound from http://www.freesound.org/people/nrn-/sounds/106255/

-- 10 or 2
local tbm_digging_speed = 10

local tbm = {}

-- offsets to determine block positions
-- access as [facedir][y][x].X for X offset from current position
-- Y for Y offset from current position and Z for Z offset etc.
-- This is a easy way to determine the 4x4 box that should be
-- mined from the current position based on the current facedir

--for y = 2,-1,-1 do
	--[[for a = -1,1,2 do
		for z = -1,1 do
		end
	end]]
--end

tbm.offsets = { -- facedir indexed (+1)
	{ -- facedir = 0
		{ -- first line
			{ X = -1, Y =  2, Z =  1 },
			{ X =  0, Y =  2, Z =  1 },
			{ X =  1, Y =  2, Z =  1 }
		},
		{ -- second line
			{ X = -1, Y =  1, Z =  1 },
			{ X =  0, Y =  1, Z =  1 },
			{ X =  1, Y =  1, Z =  1 }
		},
		{ -- third line
			{ X = -1, Y =  0, Z =  1 },
			{ X =  0, Y =  0, Z =  1 },
			{ X =  1, Y =  0, Z =  1 }
		},
		{ -- forth line
			{ X = -1, Y = -1, Z =  1 },
			{ X =  0, Y = -1, Z =  1 },
			{ X =  1, Y = -1, Z =  1 }
		}
	},
	{ -- facedir = 1
		{ -- first line
			{ X =  1, Y =  2, Z = -1 },
			{ X =  1, Y =  2, Z =  0 },
			{ X =  1, Y =  2, Z =  1 }
		},
		{ -- second line
			{ X =  1, Y =  1, Z = -1 },
			{ X =  1, Y =  1, Z =  0 },
			{ X =  1, Y =  1, Z =  1 }
		},
		{ -- third line
			{ X =  1, Y =  0, Z = -1 },
			{ X =  1, Y =  0, Z =  0 },
			{ X =  1, Y =  0, Z =  1 }
		},
		{ -- forth line
			{ X =  1, Y = -1, Z = -1 },
			{ X =  1, Y = -1, Z =  0 },
			{ X =  1, Y = -1, Z =  1 }
		}
	},
	{ -- facedir = 2
		{ -- first line
			{ X = -1, Y =  2, Z = -1 },
			{ X =  0, Y =  2, Z = -1 },
			{ X =  1, Y =  2, Z = -1 }
		},
		{ -- second line
			{ X = -1, Y =  1, Z = -1 },
			{ X =  0, Y =  1, Z = -1 },
			{ X =  1, Y =  1, Z = -1 }
		},
		{ -- third line
			{ X = -1, Y =  0, Z = -1 },
			{ X =  0, Y =  0, Z = -1 },
			{ X =  1, Y =  0, Z = -1 }
		},
		{ -- forth line
			{ X = -1, Y = -1, Z = -1 },
			{ X =  0, Y = -1, Z = -1 },
			{ X =  1, Y = -1, Z = -1 }
		}
	},
	{ -- facedir = 3
		{ -- first line
			{ X = -1, Y =  2, Z = -1 },
			{ X = -1, Y =  2, Z =  0 },
			{ X = -1, Y =  2, Z =  1 }
		},
		{ -- second line
			{ X = -1, Y =  1, Z = -1 },
			{ X = -1, Y =  1, Z =  0 },
			{ X = -1, Y =  1, Z =  1 }
		},
		{ -- third line
			{ X = -1, Y =  0, Z = -1 },
			{ X = -1, Y =  0, Z =  0 },
			{ X = -1, Y =  0, Z =  1 }
		},
		{ -- forth line
			{ X = -1, Y = -1, Z = -1 },
			{ X = -1, Y = -1, Z =  0 },
			{ X = -1, Y = -1, Z =  1 }
		}
	}
}

tbm.newposline = 3
tbm.newposcolumn = 2
tbm.rowbelownewpos = 4

local tbm_spec = "list[current_name;main;0,0;1,4;]"..
	"item_image[1,0;1,1;default:coal_lump]"..
	"item_image[1,1;1,1;default:cobble]"..
	"item_image[1,2;1,1;default:torch]"..
	"item_image[1,3;1,1;default:rail]"..
	"list[current_name;inv;2,0;6,4;]"..
	"list[current_player;main;0,5;8,4;]"

tbm.placetbm = function(pos, fuel)
	-- will correctly pace a TBM at the position indicated
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", tbm_spec)
	meta:set_string("infotext", "Tunnel Boring Machine - " .. fuel)
	meta:set_string("fuel", fuel)
	local inv = meta:get_inventory()
	inv:set_size("main", 4)
	inv:set_size("inv", 24) --6*4
end

tbm.findnewpos = function(pos, facing)
	-- will return the position where the machine will go in the next cicle
	local newpos = {}
	local box = tbm.offsets[facing + 1]
	newpos.x = pos.x + box[tbm.newposline][tbm.newposcolumn].X
	newpos.y = pos.y + box[tbm.newposline][tbm.newposcolumn].Y
	newpos.z = pos.z + box[tbm.newposline][tbm.newposcolumn].Z
	return newpos
end

tbm.findoldpos = function(pos, facing)
	-- will return the position where the machine was before (to drop items)
	local oldpos = {}
	if facing==0 then
		oldpos.x = pos.x
		oldpos.z = pos.z - 1
		oldpos.y = pos.y
	elseif facing==1 then
		oldpos.x = pos.x - 1
		oldpos.z = pos.z
		oldpos.y = pos.y
	elseif facing==2 then
		oldpos.x = pos.x
		oldpos.z = pos.z + 1
		oldpos.y = pos.y
	else
		oldpos.x = pos.x + 1
		oldpos.z = pos.z
		oldpos.y = pos.y
	end;
	return oldpos
end

tbm.dropitem = function(pos, item)
    -- Take item in any format
    --[[
    local obj = minetest.add_entity(pos, "__builtin:item")
    obj:get_luaentity():set_item(stack:to_string())
    return obj
    ]]--
    local stack = ItemStack(item)
	local inv = minetest.get_meta(pos):get_inventory()
    if inv:room_for_item("inv", stack) then
		inv:add_item("inv", stack)
    end
end

tbm.findstack = function(inv, name)
	-- will find name in the inventory inv and return its stack or nil
	if inv:is_empty("main") then
		return
	end
	for h = 1, inv:get_size("main") do
		local stack = inv:get_stack("main", h)
		if stack:get_name() == name then
			return stack
		end
	end
end

tbm.getstackcount = function(pos, name)
	-- will return the ammount of name in all stacks at position pos
	local inv = minetest.get_meta(pos):get_inventory()
	if inv:is_empty("main") then
		return 0
	end
	local found = 0
	for h = 1, inv:get_size("main") do
		local stack = inv:get_stack("main", h)
		if stack:get_name() == name
		and not stack:is_empty() then
			found = found + stack:get_count()
		end
	end
	return found
end

tbm.setstackcount = function(pos, name, count)
	-- will make n stacks at position pos so that they
	-- together makes up for count items of the item name
	local inv = minetest.get_meta(pos):get_inventory()
	local found = tbm.getstackcount(pos, name) + count
	for _ = 1, math.floor(found / 99) do
		inv:add_item("main", name.." 99")
	end
	inv:add_item("main", name.." ".. found % 99)
end

tbm.breakstones = function(pos, facing)
	-- will break all stones in front of the machine
	local block = tbm.offsets[facing + 1]
	local bpos = {}
	local oldpos = tbm.findoldpos(pos, facing)
	local cobbleresult = 0
	for i = 1, 3 do
		for j = 1, 3 do
			bpos.x = pos.x + block[i][j].X
			bpos.y = pos.y + block[i][j].Y
			bpos.z = pos.z + block[i][j].Z
			local current = minetest.get_node(bpos)
			if current.name ~= "air"
			and current.name ~= "ignore" then
				if current.name == "default:mese" then
					tbm.dropitem(pos, "default:mese")
				else
					for _,item in pairs(minetest.get_node_drops(current.name, "")) do
						tbm.dropitem(pos, item)
					end
					--[[if dropped ~= "default:cobble" then
						tbm.dropitem(pos, dropped)
					else
						tbm.dropitem(pos, dropped)
						--cobbleresult = cobbleresult + 1
					end]]
				end
				minetest.dig_node(bpos)
			end
		end
	end
	return cobbleresult
end

tbm.placecobble = function(pos, facing)
	-- place cobblestone below where the machine will be
	local box = tbm.offsets[facing + 1]
	local i = 1
	local ppos = {}
	for i = 1, 3 do
		ppos.x = pos.x + box[tbm.rowbelownewpos][i].X
		ppos.y = pos.y + box[tbm.rowbelownewpos][i].Y
		ppos.z = pos.z + box[tbm.rowbelownewpos][i].Z
		minetest.add_node(ppos, { name = "default:cobble" })
	end
end

tbm.placetorch = function(pos, facing)
	-- places a torch besides the track
	local box = tbm.offsets[facing + 1]
	local ppos = {}
	ppos.x = pos.x + box[tbm.newposline][1].X
	ppos.y = pos.y + box[tbm.newposline][1].Y
	ppos.z = pos.z + box[tbm.newposline][1].Z
	minetest.place_node(ppos, { name = "default:torch" })
end

tbm.placetrack = function(pos, facing)
	-- places a track behind the machine
	-- checks if carts mod is present
	minetest.place_node(tbm.findoldpos(pos, facing), { name = "default:rail" } )
end
--[[
local box = {
	{-3/16, 0, -8/16, 4/16, -7/16, 4/16},
	{-4/16, 1/16, 2/16, 5/16, -8/16, 3/16},
	{-2/16, -1/16, 4/16, 3/16, -6/16, 5/16},
	{-1/16, -2/16, 5/16, 2/16, -5/16, 6/16},
	{0, -3/16, 6/16, 1/16, -4/16, 7/16},
	{-3/16, -7/16, -2/16, 4/16, -8/16, 0},
	{-3/16, -7/16, -7/16, 4/16, -8/16, -5/16},
}
local selbox = {}
for n = 1, #box do
	selbox[n] = {}
	local sb = box[n]
	for i,v in pairs(sb) do
		selbox[n][i] = v*3
	end
	sb[2] = sb[2] + 0.5
	sb[5] = sb[5] + 0.5
end
local nodebox = {
	type = "fixed",
	fixed = box,
}
selbox = {
	type = "fixed",
	fixed = selbox,
}visual_scale = 3,--]]

minetest.register_node("tbm:tbm", {
	description = "Tunnel Boring Machine",
	tiles = {"tbm_top.png", "tbm_bottom.png", "tbm_side.png", "tbm_side.png^[transformFX", "tbm_front.png", "tbm_back.png"},
	paramtype = "light",
	paramtype2 = 'facedir',
	drawtype = "nodebox",
	node_box = {
	type = "fixed",
	fixed = {
		{-3/16, 0, -8/16, 4/16, -7/16, 4/16},
		{-4/16, 1/16, 2/16, 5/16, -8/16, 3/16},
		{-2/16, -1/16, 4/16, 3/16, -6/16, 5/16},
		{-1/16, -2/16, 5/16, 2/16, -5/16, 6/16},
		{0, -3/16, 6/16, 1/16, -4/16, 7/16},
		{-3/16, -7/16, -2/16, 4/16, -8/16, 0},
		{-3/16, -7/16, -7/16, 4/16, -8/16, -5/16},
		},
	},
	groups = {
		snappy=2,
		choppy=2,
		oddly_breakable_by_hand=2
	},
	on_construct = function(pos)
		tbm.placetbm(pos, "0")
		minetest.after(tbm_digging_speed, function()
			tbm.drill(pos)
		end)
	end,
	can_dig = function(pos,player)
		local inv = minetest.get_meta(pos):get_inventory()
		return inv:is_empty("main") and inv:is_empty("inv")
	end,
	on_metadata_inventory_put = function(pos, listname)
		if listname ~= "main" then
			return
		end
		minetest.after(tbm_digging_speed, function()
			tbm.drill(pos)
		end)
	end,
--	on_punch = function(pos)
--		tbm.drill(pos)
--	end
})

minetest.register_craft({
	output = "tbm:tbm",
	recipe = {
		{'default:steel_ingot', 'default:pick_steel', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:furnace', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
	}
})

--local creative_enabled = minetest.setting_getbool("creative_mode")
local creative_enabled = false

tbm.drill = function(pos)
	local node = minetest.get_node(pos)
	if node.name ~= "tbm:tbm" then
		return minetest.log("error", "[tbm] no tbm here")
	end
	local facing = node.param2
	local newpos = tbm.findnewpos(pos, facing)
	local oldpos = tbm.findoldpos(pos, facing)
	local coalcount = tbm.getstackcount(pos, "default:coal_lump")
	local cobblecount = tbm.getstackcount(pos, "default:cobble")
	local torchcount = tbm.getstackcount(pos, "default:torch")
	local railcount = tbm.getstackcount(pos, "default:rail")
	-- Current metadata
	local meta = minetest.get_meta(pos)
	-- Current inventory
	local inv = meta:get_inventory()
	local fuel = tonumber(meta:get_string("fuel")) or 0
	-- check fuel, if below 1, grab a coal if coal > 0 else, do nothing
	if fuel == 0
	and coalcount > 0 then
		fuel = 3
		coalcount = coalcount - 1
	end
	-- only work if there is fuel, three cobblestones, one track and one torch
	if fuel == 0
	or cobblecount < 3
	or railcount == 0
	or torchcount == 0 then
		meta:set_string("fuel", "0")
		return
	end

	fuel = fuel - 1
	-- break nodes ahead of the machine
	local addcobble = tbm.breakstones(pos, facing)
	-- put cobble to make bridges
	tbm.placecobble(pos, facing)
	cobblecount = cobblecount - 3
	if cobblecount < 99 then
		cobblecount = cobblecount + addcobble
	end
	if fuel == 0
	and torchcount > 0 then
		tbm.placetorch(pos, facing)
		torchcount = torchcount - 1
	end
	if railcount > 0 then
		tbm.placetrack(pos, facing)
		railcount = railcount - 1
	end
	-- create new TBM at the new position
	minetest.add_node(newpos, node)
	-- create inventary and other meta data at the new position
	tbm.placetbm(newpos, tostring(fuel))
	if not creative_enabled then
		-- move tbm stack to the new position
		tbm.setstackcount(newpos, "default:coal_lump", coalcount)
		tbm.setstackcount(newpos, "default:cobble", cobblecount)
		tbm.setstackcount(newpos, "default:torch", torchcount)
		tbm.setstackcount(newpos, "default:rail", railcount)
	else
		tbm.setstackcount(newpos, "default:coal_lump", 99)
		tbm.setstackcount(newpos, "default:cobble", 99)
		tbm.setstackcount(newpos, "default:torch", 99)
		tbm.setstackcount(newpos, "default:rail", 99)
	end

	local list = inv:get_list("inv")
	minetest.get_meta(newpos):get_inventory():set_list("inv", list)

	-- remove tbm from old position
	minetest.remove_node(pos)

	--play sound
	minetest.sound_play("tbm", {pos = pos, gain = 1.0, max_hear_distance = 16,})
end
