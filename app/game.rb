$uid_file = 0


def get_uid()
    out_uid = $uid_file
    $uid_file += 1

    return out_uid 
end


class Game
    attr_accessor :player, :tiles, :world, :tasks
    attr_gtk


    def initialize()
    end


    def defaults()
        @invasion_tick = 30
        @day_cycle = 0
        @day_step = (255 / 60).floor()
    
        @player = {
            x: 0,
            y: 0,
            faction: 1,
            selected: nil,
            tasks: {
                assigned: {}, 
                unassigned: {}
            },
            flag: DRObject.new(
                x: 32,
                y: 32,
                w: 1,
                h: 1,
                z: 10,
                r: 100,
                g: 100,
                b: 0
            )
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
            }.solid!,
            timer: {
                x: 0, 
                y: 64,
                text: "%03d" % @invasion_tick,
                font: 'fonts/NotJamPixel5.ttf',
                r: 255,
                g: 255,
                b: 255,
                size_px: 5
            }.label!
        }
        @job_board = {build: {}}
        @tiles = {}
        @pawns = {}
        @dim = 64
        @tile_dim = 8
        @tasks = {assigned: {}, unassigned: {}}

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

        @world << @player.flag
        @tiles[[@player.flag.x, @player.flag.y]].ground = @player.flag
        spawns = [
            [@player.flag.x + 1, @player.flag.y],
            [@player.flag.x - 1, @player.flag.y],
            [@player.flag.x, @player.flag.y + 1],
            [@player.flag.x, @player.flag.y - 1]
        ]
#        spawns = [
#            [@dim - 1, 0],
#            [0, @dim - 1],
#            [@dim - 1, @dim - 1],
#            [0, 0]
#        ]

        


        3.times do |i|
            a_spawn = spawns.sample()
            spawns.delete(a_spawn)

            pawn = Actor.new(
                x: a_spawn.x,
                y: a_spawn.y,
                faction: 1,
                raiding: false,
                w: 1, 
                h: 1,
                z: 1,
                r: 150,
                g: 150,
                b: 0
            )

            @world << pawn
            @pawns[pawn.uid] = pawn 
            update_tile(pawn, pawn)
        end

        @pause = true
        @admin_mode = false

        plant_stone()

        @globals = {
            factions: {},
            area_owner: @player,
            area_flag: @player.flag,
            area_dim: @dim
        }

        @globals.factions[1.to_s.to_sym] = @player
        @globals.factions[2.to_s.to_sym] = {tasks: nil} 
    end


    def tick()
        defaults() if(state.tick_count <= 0)
        return if(state.tick_count <= 0)
        
        update_active_pawns() if(!@pause)
        spawn_enemies() if(@invasion_tick <= 0)
        input()
        overhead() if(!@pause)

        outputs[:view].transient!()
        outputs[:view].w = 64
        outputs[:view].h = 64
        outputs[:view].primitives << @world.branches 
        outputs[:view].primitives << @ui.values() 
        outputs[:view].primitives << player.tasks.unassigned.values.map do |task|
            if(task.has_key?(:build))
                struct = task.build.struct

                {
                    x: struct.x,
                    y: struct.y,
                    w: struct.w,
                    h: struct.h,
                    r: struct.r,
                    g: struct.g,
                    b: struct.b,
                    a: 50
                }.solid! 
            end
        end
        outputs[:view].primitives << player.tasks.assigned.values.map do |task|
            if(task.has_key?(:build))
                struct = task.build.struct

                {
                    x: struct.x,
                    y: struct.y,
                    w: struct.w,
                    h: struct.h,
                    r: struct.r,
                    g: struct.g,
                    b: struct.b,
                    a: 50
                }.solid! 
            end
        end if(state.tick_count % 30 < 15)
        outputs.primitives << {
            x: 288, 
            y: 8, 
            w: 704, 
            h: 704, 
            path: :view
        }.sprite!
    end


    def overhead()
        @invasion_tick -= 1 if(tick_count % 60 == 0 && @invasion_tick > 0)
        @day_dir = -1 if(tick_count % 60 == 0 && @day_cycle >= 60)
        @day_dir = 1 if(tick_count % 60 == 0 && @day_cycle <= 0)
        @day_cycle += @day_dir if(tick_count % 60 == 0)
        current_dif = @day_step * @day_cycle
        text_color = 255 - current_dif
        @ui.timer.text = "%03d" % @invasion_tick
        @ui.timer.r = text_color
        @ui.timer.g = text_color
        @ui.timer.b = text_color
        @ui.selector.r = text_color
        @ui.selector.g = text_color
        @ui.selector.b = text_color

        outputs[:view].background_color = [
            current_dif, 
            current_dif,
            current_dif
        ] 
    end


    def input()
        mouse_x = ((inputs.mouse.x - 288) / 11).floor()
        mouse_y = ((inputs.mouse.y - 8) / 11).floor()

        @player.x = mouse_x
        @player.y = mouse_y

        @pause = !@pause if(inputs.keyboard.key_down.space)

        if((inputs.mouse.down || inputs.mouse.held) && mouse_x > -1 && 
        mouse_x < @dim && mouse_y > -1 && mouse_y < @dim)
            puts "#{@player.x}, #{@player.y}"

            if(inputs.mouse.button_right)
                @player.selected = nil
                return
            end
                
            if(!@tiles[[mouse_x, mouse_y]].pawn.nil?())
                @player.selected = @tiles[[mouse_x, mouse_y]].pawn
                puts "selected #{@player.selected}"
            elsif(!@player.selected.nil?() && 
            @tiles[[mouse_x, mouse_y]].pawn.nil?())
                if(inputs.mouse.down)
                    @player.selected.trail_end = [mouse_x, mouse_y]
                    @player.selected.trail_start_time = state.tick_count 

                    @player.selected.create_trail(@tiles) 
                end
            elsif(
                @tiles[[mouse_x, mouse_y]].ground.nil?() && 
                !player.tasks.assigned.has_key?([mouse_x, mouse_y]) &&
                !player.tasks.unassigned.has_key?([mouse_x, mouse_y]) &&
                !@admin_mode
            )
                pos = find_resource(@resources, :stone)

                player.tasks.unassigned[[mouse_x, mouse_y]] = {
                    start: :fetch,
                    action: :build,
                    uid: [mouse_x, mouse_y],
                    fetch: {
                        pos: [pos.x, pos.y],
                        range: 1,
                        type: :stone,
                        hit: false,
                        nxt: :build
                    },
                    build: {
                        pos: [mouse_x, mouse_y],
                        hit: false,
                        nxt: nil,
                        range: 1,
                        spot: :ground,
                        struct: {
                            x: mouse_x,
                            y: mouse_y,
                            w: 1,
                            h: 1,
                            z: 0,
                            type: :struct,
                            faction: @player.faction,
                            max_supply: 10,
                            r: 23,
                            g: 150,
                            b: 150
                        }
                    }
                }
            elsif(
                @tiles[[mouse_x, mouse_y]].ground.nil?() && 
                @admin_mode
            )
                @tiles[[mouse_x, mouse_y]].ground = DRObject.new(
                    x: mouse_x,
                    y: mouse_y,
                    w: 1,
                    h: 1,
                    z: 0,
                    type: :struct,
                    faction: @player.faction,
                    r: 23,
                    g: 150,
                    b: 150 
                )
                @world << @tiles[[mouse_x, mouse_y]].ground
            end
        end

        @ui.selector.x = @player.x
        @ui.selector.y = @player.y
    end


    def update_active_pawns()
        @pawns.values.map!() do |pawn|
            _player = @globals.factions[pawn.faction.to_s.to_sym]

            old_pos = {x: pawn.x, y: pawn.y}
            pawn.update(tick_count, _player.tasks, @tiles, @world, @globals)

            update_tile(pawn, old_pos, spot: :pawn)
            pawn
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

    
    def spawn_enemies()
        @invasion_tick = 120
        spawns = [
            [@dim - 1, 0],
            [0, @dim - 1],
            [@dim - 1, @dim - 1],
            [0, 0]
        ]
        3.times do |i|
            a_spawn = spawns.sample()
            spawns.delete(a_spawn)

            pawn = Actor.new(
                x: a_spawn.x,
                y: a_spawn.y,
                faction: 2,
                raiding: true,
                enemies: {'1': 1},
                w: 1, 
                h: 1,
                z: 1,
                r: 150,
                g: 0,
                b: 0
            )

            @world << pawn
            @pawns[pawn.uid] = pawn 
            update_tile(pawn, pawn)
        end
    end
end


def tick(args)
    args.outputs.background_color = [0, 0, 0]
    $game ||= Game.new()

    $game.args = args
    $game.tick()
end
