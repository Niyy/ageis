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
        @active_pawns = {}
        @dim = 58
        @tile_dim = 8

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

        pawn = {
            x: 0,
            y: 0,
            w: 1,
            h: 1,
            z: 1,
            trail_end: nil,
            trail: [],
            job: :builder,
            path: 'sprites/characters/tribesman.png',
            uid: get_uid()
        }

        @world << pawn

        @update = true 
        update_tile(@world[pawn.uid], @world[pawn.uid])
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

        if((inputs.mouse.down || inputs.mouse.held))
                
            puts "#{@player.x}, #{@player.y}"
            if(!@tiles[[mouse_x, mouse_y]].pawn.nil?())
                @player.selected = @tiles[[mouse_x, mouse_y]].pawn
            elsif(!@player.selected.nil?() && 
                  @tiles[[mouse_x, mouse_y]].pawn.nil?())

                if(inputs.mouse.down)
                    @player.selected.trail_end = [mouse_x, mouse_y]
                    @player.selected.trail_start_time = state.tick_count 
                    @active_pawns[@player.selected.uid] = @player.selected

                    create_trail(@player.selected, @player.selected.trail_end)
                end
            elsif(@tiles[[mouse_x, mouse_y]].ground.nil?())
                struct = {
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
                
                @update = true
                @tiles[[mouse_x, mouse_y]].ground = struct
                @world << struct
            end
        end

        @update = true if(@ui.selector.x != @player.x)
        @update = true if(@ui.selector.y != @player.y)
        
        @ui.selector.x = @player.x
        @ui.selector.y = @player.y

        if(@update)
            outputs[:view].w = 64
            outputs[:view].h = 64
            outputs[:view].primitives << @world.branches 
            outputs[:view].primitives << @ui.values() 
            outputs[:view].primitives << @ui.values() 

            @update = false
        end
    end


    def update_active_pawns()
        @active_pawns.values.map!() do |pawn|
            continue = move2(pawn)
            
            pawn if(continue)
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
            (state.tick_count - pawn.trail_start_time) % 60 != 0
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

        puts 'parent'
        puts parents

        if(!found.nil?())
            child = found 
        
            puts 'found'
            puts found

            while(parents[child.uid].uid != child.uid)
                puts '---------------'
                puts child

                obj.trail << child 
                child = parents[child.uid]
            end
        end

        puts 'trail'
        puts obj.trail
    end


    def update_tile(obj, new_pos, spot: :pawn)
        @tiles[[obj.x, obj.y]][spot] = nil
        @tiles[[new_pos.x, new_pos.y]][spot] = obj

        obj.x = new_pos.x
        obj.y = new_pos.y

        @update = true
    end
    

    def assess(dir, og)
        if(dir.x != 0 && dir.y != 0)
            return (@tiles.has_key?(dir.uid) && @tiles[dir.uid].ground.nil?() &&
                @tiles.has_key?([dir.x, og.y]) && @tiles[[dir.x, og.y]].ground.nil?() && 
                @tiles.has_key?([og.x, dir.y]) && @tiles[[og.x, dir.y]].ground.nil?()
            )
        end

        return (@tiles.has_key?(dir.uid) && @tiles[dir.uid].ground.nil?())
    end


    def trail_add(cur, dif, trail_end, queue, parents)
        next_step = {
            x: cur.x + dif.x, 
            y: cur.y + dif.y, 
            uid: [cur.x + dif.x, cur.y + dif.y]
        }
        step_dist = sqr(trail_end.x - next_step.x) + 
            sqr(trail_end.y - next_step.y) 

        if(next_step.y < @dim && !parents.has_key?(next_step.uid) && 
            assess(next_step, cur)
        )
            queue << next_step.merge({z: step_dist}) 
            parents[next_step.uid] = cur 
        end
    end
end


def tick(args)
    args.outputs.background_color = [0, 0, 0]
    $game ||= Game.new()

    $game.args = args
    $game.tick()
end
