$uid_file = 0


def get_uid()
    out_uid = $uid_file
    $uid_file += 1

    return out_uid 
end


class Game
    attr_accessor :player, :tiles
    attr_gtk


    def initialize()
    end


    def defaults()
        @player = {
            x: 0,
            y: 0,
            selected: nil
        }
        @world = World_Tree.new()
        @resources = {
            stone: {}
        }
        @ui = {
            selector: {
                x: 0, 
                y: 0, 
                w: 1, 
                h: 1,
                a: 125,
                r: 50,
                b: 50,
                g: 50
            }.solid!
        }
        @job_board = {build: {}}
        @tiles = {}
        @pawns = {}
        @dim = 58
        @tile_dim = 8
        @tasks = {}

        outputs[:view].w = 64
        outputs[:view].h = 64
        outputs[:view].transient!
        outputs[:view].primitives << @world.branches
        outputs[:view].primitives << @ui.values() 
    
        (64).times() do |y|
            (64).times() do |x|
                @tiles[[x, y]] = {
                    pawn: nil, 
                    flora: nil, 
                    ground: nil 
                }
            end
        end

        pawn = Actor.new(
            x: 0,
            y: 0,
            w: 1,
            h: 1,
            z: 1,
            r: 100,
            b: 50
        )

        @world << pawn
        @pawns[pawn.uid] = pawn 
        plant_stone()

        @update = true 
        update_tile(pawn, pawn)
    end


    def tick()
        defaults() if(state.tick_count <= 0)
        return if(state.tick_count <= 0)
        
        update_active_pawns()
        input()

        outputs.primitives << {
            x: 288, 
            y: 8, 
            w: 704, 
            h: 704, 
            path: :view
        }.sprite!
    end


    def input()
        mouse_x = ((inputs.mouse.x - 288) / 11).floor()
        mouse_y = ((inputs.mouse.y - 8) / 11).floor()

        @player.x = mouse_x
        @player.y = mouse_y

        if((inputs.mouse.down || inputs.mouse.held) && mouse_x > -1 && 
        mouse_x < @dim && mouse_y > -1 && mouse_y < @dim)
            puts "#{@player.x}, #{@player.y}"

            if(inputs.mouse.button_right)
                @player.selected = nil
                return
            end
                
            if(!@tiles[[mouse_x, mouse_y]].pawn.nil?())
                @player.selected = @tiles[[mouse_x, mouse_y]].pawn
            elsif(!@player.selected.nil?() && 
                  @tiles[[mouse_x, mouse_y]].pawn.nil?())

                if(inputs.mouse.down)
                    @player.selected.trail_end = [mouse_x, mouse_y]
                    @player.selected.trail_start_time = state.tick_count 

                    @player.selected.create_trail(@tiles) 
                end
            elsif(@tiles[[mouse_x, mouse_y]].ground.nil?() && 
            !@tasks.has_key?([mouse_x, mouse_y]) && inputs.mouse.down)
#                struct = {
#                    x: mouse_x,
#                    y: mouse_y,
#                    w: 1,
#                    h: 1,
#                    z: 0,
#                    uid: get_uid(),
#                    r: 23,
#                    g: 150,
#                    b: 150 
#                }.solid!
                pos = find_resource(@resources, :stone)
                @tasks[[mouse_x, mouse_y]] = {
                    in: {
                        x: pos.x,
                        y: pos.y,
                        type: :stone
                    },
                    out: {
                        x: mouse_x, 
                        y: mouse_y,
                        struct: {
                            x: mouse_x,
                            y: mouse_y,
                            w: 1,
                            h: 1,
                            z: 0,
                            uid: get_uid(),
                            r: 23,
                            g: 150,
                            b: 150 
                        }.solid!
                    }
                }
               
                @update = true
#                @tiles[[mouse_x, mouse_y]].ground = struct
#                @world << struct
            end
        end

        @update = true if(@ui.selector.x != @player.x)
        @update = true if(@ui.selector.y != @player.y)
        
        @ui.selector.x = @player.x
        @ui.selector.y = @player.y

#        if(@update)
            outputs[:view].transient!()
            outputs[:view].w = 64
            outputs[:view].h = 64
            outputs[:view].primitives << @world.branches 
            outputs[:view].primitives << @ui.values() 
            outputs[:view].primitives << @ui.values() 

            @update = false
#        end
    end


    def update_active_pawns()
        @pawns.values.map!() do |pawn|
            old_pos = {x: pawn.x, y: pawn.y}
            pawn.update(tick_count, @tasks.values(), tiles)

            update_tile(pawn, old_pos, spot: :pawn)
            pawn
        end
    end


    def move(pawn)
        return if(
            pawn.trail_end.nil?() || 
            (state.tick_count - pawn.trail_start_time) % 120 != 0
        )

        dx = pawn.trail_end.x - pawn.x
        dy = pawn.trail_end.y - pawn.y

        dx = dx != 0 ? (dx / dx.abs).round : 0
        dy = dy != 0 ? (dy / dy.abs).round : 0

        # Need to choose a direction with the lowest deveiation from the original.
        if(!@tiles[[pawn.x + dx, pawn.y + dy]].ground.nil?())
            north = [pawn.x, pawn.y + 1]
            south = [pawn.x, pawn.y - 1]
            east = [pawn.x + 1, pawn.y]
            west = [pawn.x - 1, pawn.y]
        end

        pawn.x += dx
        pawn.y += dy

        @update = true

        if(pawn.x == pawn.trail_end.x && pawn.y == pawn.trail_end.y)
            pawn.trail_end = nil 
            return false
        end

        @update = true

        return true
    end


    def move2(pawn)
         return if(
            pawn.trail.empty?() || 
            (state.tick_count - pawn.trail_start_time) % 30 != 0
        )       

        next_step = pawn.trail.pop()

        pawn.x = next_step.x
        pawn.y = next_step.y

        @update = true

        return false if(pawn.trail.empty?())
        return true
    end


    def create_trail(obj, trail_end)
        found = nil 
        queue = World_Tree.new()
        parents = {}

        queue << {x: obj.x, y: obj.y, z: 0, uid: [obj.x, obj.y]} 
        parents[[obj.x, obj.y]] = {x: obj.x, y: obj.y, z: 0, uid: [obj.x, obj.y]}

        while(!queue.empty?())
            cur = queue.pop()

            if(cur.x == trail_end.x && cur.y == trail_end.y)
                found = cur
                break
            end
            
            trail_add(cur, [0, 1], trail_end, queue, parents)
            trail_add(cur, [0, -1], trail_end, queue, parents)
            trail_add(cur, [1, 0], trail_end, queue, parents)
            trail_add(cur, [-1, 0], trail_end, queue, parents)
            trail_add(cur, [1, 1], trail_end, queue, parents)
            trail_add(cur, [1, -1], trail_end, queue, parents)
            trail_add(cur, [-1, 1], trail_end, queue, parents)
            trail_add(cur, [-1, -1], trail_end, queue, parents)
        end
   
        obj.trail.clear()

        if(!found.nil?())
            child = found 

            while(parents[child.uid].uid != child.uid)
                obj.trail << child 
                child = parents[child.uid]
            end
        end
    end


    def update_tile(obj, old_pos, spot: :pawn)
        @tiles[[old_pos.x, old_pos.y]][spot] = nil
        @tiles[[obj.x, obj.y]][spot] = obj

        @update = true
    end


    def assess(next_pos, og, dir = [0, 0])
        if(dir.x != 0 && dir.y != 0)
            return (
                @tiles.has_key?(next_pos.uid) && 
                @tiles[next_pos.uid].ground.nil?() &&
                @tiles.has_key?([next_pos.x, og.y]) && 
                @tiles[[next_pos.x, og.y]].ground.nil?() && 
                @tiles.has_key?([og.x, next_pos.y]) && 
                @tiles[[og.x, next_pos.y]].ground.nil?()
            )
        end
        
        return (
            @tiles.has_key?(next_pos.uid) && 
            @tiles[next_pos.uid].ground.nil?()
        )
    end


    def accessable(pos)
        return (
            @tiles[[pos.x + 1, pos.y]]&.ground.nil?() ||
            @tiles[[pos.x - 1, pos.y]]&.ground.nil?() ||
            @tiles[[pos.x, pos.y + 1]]&.ground.nil?() ||
            @tiles[[pos.x, pos.y - 1]]&.ground.nil?()
        )
    end


    def trail_add(cur, dif, trail_end = {x: 0, y: 0}, queue = [], parents = {})
        next_step = {
            x: cur.x + dif.x, 
            y: cur.y + dif.y, 
            uid: [cur.x + dif.x, cur.y + dif.y]
        }
        step_dist = sqr(trail_end.x - next_step.x) + 
            sqr(trail_end.y - next_step.y) 
        
        if(!parents.has_key?(next_step.uid) && 
            assess(next_step, cur, dif)
        )
            queue << next_step.merge({z: step_dist}) 
            parents[next_step.uid] = cur 
        end
    end


    def plant_stone()
        start = [(rand() * @dim).floor(), (rand() * @dim).floor()]

        queue = [{x: start.x, y: start.y, uid: start, z: 0}]
        visited = {}

        res = DRObject.new(
            x: start.x,
            y: start.y,
            r: 31,
            g: 46,
            b: 46,
            tick: state.tick_count,
            type: :stone
        )

        12.times do |i|
            break if(queue.empty?())
            
            cur = queue.sample()
            visited[cur.uid] = cur
            queue.delete(id)

            res.x = cur.x
            res.y = cur.y
            cp = res.copy()
            cp.type = :stone
            
            @resources[cp.type] = {} if(!@resources.has_key?(cp.type))

            @resources[cp.type][cp.uid] = cp
            @tiles[cur.uid].ground = cp 
            @world << cp

            trail_add(cur, [0, 1], start, queue, visited)
            trail_add(cur, [0, -1], start, queue, visited)
            trail_add(cur, [1, 0], start, queue, visited)
            trail_add(cur, [-1, 0], start, queue, visited)
        end
    end


    def find_resource(resources, type)
        return nil if(!resources.has_key?(type))
        
        resources[type].values.each() do |obj|
            return obj if(accessable(obj))
        end

        return nil
    end
end


def tick(args)
    args.outputs.background_color = [0, 0, 0]
    $game ||= Game.new()

    $game.args = args
    $game.tick()
end
