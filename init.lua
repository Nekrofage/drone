
minetest.register_craftitem("drone:remotecontrol", {
    description = "A remote control for Drone",
    inventory_image = "drone_remotecontrol.png",
})

local turtle_formspec_positions = {}

minetest.register_node("drone:blackdrone", {
    description = "Drone",

    drawtype = "mesh",
    mesh = "drone.obj",
    tiles = {"drone.png"},

    groups={oddly_breakable_by_hand=1},
    paramtype = "light",
    paramtype2 = "facedir",
    
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local wielditem = clicker:get_wielded_item()
        local wieldname = wielditem:get_name()
        if wieldname ~= "drone:remotecontrol" then
            minetest.chat_send_player(clicker:get_player_name(), "Remote control")
        else
            -- When the player does a right click on this node
            local player_name = clicker:get_player_name()
             -- Save the last turtle in a table
            turtle_formspec_positions[player_name] = pos
        
            minetest.show_formspec(player_name, "drone:control_formspec", 
                "size[9,4]" ..
                "label[0,0;Click buttons to move the drone]" ..
                "button_exit[5,1;2,1;exit;Exit]" ..
                "image_button[1,1;1,1;arrow_up.png;up;]" ..
                "image_button[2,1;1,1;arrow_fw.png;forward;]" ..
                "image_button[1,2;1,1;arrow_left.png;turnleft;]"..
                "image_button[3,2;1,1;arrow_right.png;turnright;]" ..
                "image_button[1,3;1,1;arrow_down.png;down;]" ..
                "image_button[2,3;1,1;arrow_bw.png;backward;]"
                )
            return itemstack
          
        end
        
    end,
})

-- image_button[X,Y;W,H;image;name;label]

local function nextrangeright(x)
    x = x + 1
    if x > 3 then
        x = 0
    end
    return x
end

local function nextrangeleft(x)
    x = x - 1
    if x < 0 then
        x = 3
    end
    return x
end

-- Catch user inputs from the formspec
minetest.register_on_player_receive_fields(function(sender, formname, fields)
    if formname ~= "drone:control_formspec" then
        return -- Not a turtle formspec
    end
    local player_name = sender:get_player_name()
    local pos = turtle_formspec_positions[player_name]
   
    if not pos then
        return -- Something went wrong. No position found for this player
    end
   
    local node = minetest.get_node(pos)
    
    if node.name ~= "drone:blackdrone" then
        turtle_formspec_positions[player_name] = nil
        return -- Data invalid. There's no drone at the given position
    end
   
    local new_pos = vector.new(pos)
    
    local dir = minetest.facedir_to_dir(node.param2)
    local dirx= dir.x
    local dirz= dir.z
    
    if fields.up then
        new_pos.y = new_pos.y + 1
    end
   
    if fields.down then
        new_pos.y = new_pos.y - 1
    end
   
    if fields.forward then
        new_pos.z = new_pos.z - dirz
        new_pos.x = new_pos.x - dirx
    end
   
    if fields.backward then
        new_pos.z = new_pos.z + dirz
        new_pos.x = new_pos.x + dirx
    end
    
    if fields.turnright then
        local ndef = minetest.registered_nodes[node.name]

        -- Compute param2
        local rotationPart = node.param2 % 32 -- get first 4 bits
        local preservePart = node.param2 - rotationPart
        local axisdir = math.floor(rotationPart / 4)
        local rotation = rotationPart - axisdir * 4
        rotationPart = axisdir * 4 + nextrangeright(rotation)
        
        local new_param2 = preservePart + rotationPart
        
        node.param2 = new_param2
        minetest.swap_node(pos, node)
        minetest.sound_play("moveokay", {to_player = player_name,gain = 1.0,})
        return
    end

    if fields.turnleft then
        local ndef = minetest.registered_nodes[node.name]

        -- Compute param2
        local rotationPart = node.param2 % 32 -- get first 4 bits
        local preservePart = node.param2 - rotationPart
        local axisdir = math.floor(rotationPart / 4)
        local rotation = rotationPart - axisdir * 4
        rotationPart = axisdir * 4 + nextrangeleft(rotation)
        
        local new_param2 = preservePart + rotationPart
        
        node.param2 = new_param2
        minetest.swap_node(pos, node)
        minetest.sound_play("moveokay",{to_player = player_name,gain = 1.0,})
        return
    end 
    

    -- Check new position if empty
    local newposchecktable = minetest.get_node(new_pos)
    local newposcheck = newposchecktable.name
    local walkable = minetest.registered_nodes[newposcheck].walkable
    
    if not walkable then
        if not vector.equals(pos, new_pos) then
        -- Move node to new position
            minetest.remove_node(pos)
            minetest.set_node(new_pos, node) --move node to new position
            minetest.get_meta(new_pos):from_table(meta) --set metadata of new node
      
            -- Update formspec reference position, wait for next instructions
            turtle_formspec_positions[player_name] = new_pos
            
            minetest.sound_play("moveokay", {to_player = player_name,gain = 1.0,})
        end
    else
        minetest.sound_play("moveerror", {
            to_player = player_name,
            gain = 1.0,
        })
    end
end)

