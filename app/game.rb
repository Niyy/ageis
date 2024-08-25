$uid_file ||= 0
$paused ||= false


def get_uid()
    out_uid = $uid_file
    $uid_file += 1

    return out_uid.to_s
end


class Game < View
    attr_accessor :player, :tiles, :world, :tasks, :admin_mode, :resources, 
                  :globals, :pawns


    def initialize(args)
        self.args = args

        defaults()
    end


    def defaults()
        @survived = 0
        @invasion_temp = 2 
        @invasion_tick = @invasion_temp
        @day_cycle = 0
        @day_step = (510 / (@invasion_temp)).floor()
        @load = 10
    
        @player = {
            x: 0,
            y: 0,
            faction: 1,
            selected: nil,
            selected_structure: :wall,
            build_interface: Build_Interface.new(),
            tasks: {
                assigned: {}, 
                unassigned: {}
            },
            flag: Structure.new(
                x: 32,
                y: 32,
                w: 1,
                h: 1,
                z: 10,
                r: 100,
                g: 100,
                b: 0,
                faction: 1,
                max_supply: 100,
                type: :struct
            )
        }
        @world = World_Tree.new()
        @resources = {
            stone: {}
        }
        @ui = {
            selected_structure: {
                x: 32, 
                y: 64,
                text: @player.selected_structure.to_s,
                font: 'fonts/NotJamPixel5.ttf',
                r: 255,
                g: 255,
                b: 255,
                size_px: 5
            },
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
                @tiles[[x, y]] = Tile.new()
            end
        end

        @world << @player.flag
        @tiles[[@player.flag.x, @player.flag.y]][:ground] = @player.flag
        spawns = [
            [@player.flag.x + 1, @player.flag.y],
            [@player.flag.x - 1, @player.flag.y],
            [@player.flag.x, @player.flag.y + 1],
            [@player.flag.x, @player.flag.y - 1]
        ]

        2.times do |i|
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
            @tiles[[pawn.x, pawn.y]][:pawn] = pawn
        end

        @admin_mode = false 

        plant_stone()

        @globals = {
            wave: {},
            factions: {},
            faction_pawn_count: {},
            area_owner: @player,
            area_flag: @player.flag,
            area_dim: @dim
        }

        @globals.factions[:'1'] = @player
        @globals.faction_pawn_count[:'1'] = 3
        @globals.factions[:'2'] = {tasks: nil} 
        @globals.faction_pawn_count[:'2'] = 0 

        @sound_files = {
            building: {name: 'building', path: 'sounds/hall_of_kings.mp3'},
            enemies_at_gate: {name: 'combat', path: 'sounds/ghost_castle.mp3'},
            effect_place: {name: 'ploop', 
                           path: 'sounds/effects/place_sound.wav'}
        }
#        audio[:bgm] = {
#            input: @sound_files.building.path,
#            screenx: 0,
#            screeny: 0,
#            x: 0,
#            y: 0,
#            z: 0,
#            gain: 1.0,
#            pitch: 1.0,
#            looping: true,
#            paused: false,
#            mode: 0
#        }
    end


    def tick()
#        puts "Selected: #{@player.selected}" if(state.tick_count % 60 == 0)

        if(@load > 0)
            @load -= 1
            return nil
        end

        if(@player.flag.supply <= 0 && !$paused)
            puts "->"
            puts "player: #{@player.flag}"
            puts "flag: #{@world[@player.flag.uid]}"
            audio.clear
            
#            @pause = !@pause
            return :title
        end

        update_active_pawns() if(!$paused)
        spawn_enemies() if(@invasion_tick <= 0)
        restart_counter()
        input()
        audio()
        overhead()

        outputs[:view].transient!()
        outputs[:view].w = 64
        outputs[:view].h = 64
        outputs[:view].primitives << @world.branches 
        outputs[:view].primitives << @ui.values() 
        outputs[:view].primitives << @player.tasks.unassigned.values.map do |task|
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

        if(@player.selected)
            outputs[:view].debug << {x: @player.selected.x - 1, 
                                     y: @player.selected.y - 1,
                                     w: @player.selected.w + 2,
                                     h: @player.selected.h + 2,
                                     r: 255,
                                     g: 255,
                                     b: 255,
                                     a: 100}.solid!
        end

        outputs.primitives

        return nil
    end


    def overhead()
        if(!$paused && @globals.wave.values.length <= 0)
            @invasion_tick -= 1 if(tick_count % 60 == 0 && @invasion_tick > 0)
            @day_dir = -1 if(tick_count % 60 == 0 && @day_cycle >= @invasion_temp / 2)
            @day_dir = 1 if(tick_count % 60 == 0 && @day_cycle <= 0)
            @day_cycle += @day_dir if(tick_count % 60 == 0)

            puts @day_cycle
        end

        current_dif = @day_step * @day_cycle
        text_color = 255 - current_dif
        @ui.timer.text = "%03d" % @invasion_tick
        @ui.timer.r = \
            @ui.selected_structure.r = text_color
        @ui.timer.g = \
            @ui.selected_structure.g = text_color
        @ui.timer.b = \
            @ui.selected_structure.b = text_color
        @ui.selector.r = text_color
        @ui.selector.g = text_color
        @ui.selector.b = text_color
        @ui.selected_structure.text = @player.selected_structure.to_s

        outputs[:view].background_color = [
            current_dif, 
            current_dif,
            current_dif
        ] 
    end


    def input()
        mouse_x = ((inputs.mouse.x - 288) / 11).floor()
        mouse_y = ((inputs.mouse.y - 8) / 11).floor()
        @tick_on_down = tick_count if(inputs.mouse.down || inputs.mouse.held)

        @player.x = mouse_x
        @player.y = mouse_y

        @player.selected_structure = :gate if(inputs.keyboard.key_down.one)
        @player.selected_structure = :wall if(inputs.keyboard.key_down.two)
        @player.selected_structure = :erase if(inputs.keyboard.key_down.three)

        $paused = !$paused if(inputs.keyboard.key_down.space)

        if((inputs.mouse.down || inputs.mouse.held) && mouse_x > -1 && 
        mouse_x < @dim && mouse_y > -1 && mouse_y < @dim)
            puts "#{@player.x}, #{@player.y}"

            if(inputs.mouse.button_right)
                @player.selected = nil
                return
            end
                
            if(!@tiles[[mouse_x, mouse_y]].pawn.nil?())
                @player.selected = @tiles[[mouse_x, mouse_y]].pawn
            elsif(
                  !@player.selected.nil?() && 
                  @tiles[[mouse_x, mouse_y]].pawn.nil?()
                 )
                if(inputs.mouse.down)
                    @player.selected.setup_trail()
                    @player.selected.trail_end = [mouse_x, mouse_y]
                    @player.selected.trail_start_time = state.tick_count 
                    @player.selected.trail_max_range = 1
                    
                    if(@player.selected.task)
                        @player.selected.task.hit = false if(
                            @player.selected.task.start == :fetch
                        )
                        @player.tasks.unassigned[@player.selected.task.uid] = \
                            @player.selected.task
                        @player.tasks.assigned.delete(@player.selected.task.uid)
                        @player.selected.task = nil
                        @player.selected.task_current = nil
                    end
                end
            elsif(
                @tiles[[mouse_x, mouse_y]].ground.nil?() && 
                !player.tasks.assigned.has_key?([mouse_x, mouse_y]) &&
                !player.tasks.unassigned.has_key?([mouse_x, mouse_y]) &&
                !@admin_mode
            )
                pos = find_resource(@resources, :stone)
                ntask = player.build_interface.build(@player.selected_structure, 
                                                     mouse_x, 
                                                     mouse_y,
                                                     pos,
                                                     world, 
                                                     tiles)

                if(ntask)
                    player.tasks.unassigned[[mouse_x, mouse_y]] = ntask
                end
            elsif(
                @tiles[[mouse_x, mouse_y]].ground.nil?() && 
                @admin_mode
            )
                @tiles[[mouse_x, mouse_y]].ground = Structure.new(
                    x: mouse_x,
                    y: mouse_y,
                    w: 1,
                    h: 1,
                    z: 0,
                    faction: @player.faction,
                    r: 23,
                    g: 100,
                    b: 150,
                    type: :struct,
                    passable: true,
                    name: 'gate'
                ) if(@player.selected_structure == :gate)

                @tiles[[mouse_x, mouse_y]].ground = Structure.new(
                    x: mouse_x,
                    y: mouse_y,
                    w: 1,
                    h: 1,
                    z: 0,
                    faction: @player.faction,
                    r: 23,
                    g: 200,
                    b: 150,
                    passable: false,
                    type: :struct,
                    name: 'wall'
                ) if(@player.selected_structure == :wall)

                if(@player.selected_structure != :erase)
                    @world << @tiles[[mouse_x, mouse_y]].ground
                end
            elsif(@player.selected_structure == :erase)
                if(@admin_mode)
                    @world.delete(@tiles[[mouse_x, mouse_y]].ground)
                    @tiles[[mouse_x, mouse_y]].ground = nil
                else
                    ntask = player.build_interface.build(
                        @player.selected_structure, 
                        mouse_x, 
                        mouse_y,
                        pos,
                        world, 
                        tiles
                    )
                end
            end
        end

        if(@tick_on_down == tick_count - 1)
            audio[get_uid] = {
                input: @sound_files[:effect_place].path,
                screenx: 0,
                screeny: 0,
                x: 0,
                y: 0,
                z: 0,
                gain: 1.0,
                pitch: 1.0,
                looping: false,
                paused: false
            }
        end

        @ui.selector.x = @player.x
        @ui.selector.y = @player.y
    end


    def select_troops()
    end


    def update_active_pawns()
        @pawns.delete_if do |key, pawn|
            _player = @globals.factions[pawn.faction.to_s.to_sym]

            if(pawn.supply <= 0)
                puts "pawn killed #{pawn.uid}"
                @tiles[[pawn.x, pawn.y]].pawn = nil
                @globals.faction_pawn_count[pawn.faction.to_s.to_sym] -= 1
                @globals.wave.delete(pawn.uid)
                @world.delete(pawn)

                true
            else
                old_pos = {x: pawn.x, y: pawn.y}
                pawn.update(tick_count, _player.tasks, @tiles, @world, @globals, 
                            audio, player)

                update_tile(pawn, old_pos, spot: :pawn)

                false
            end
        end

        @pawns.compact!()
    end


    def update_tile(obj, old_pos, spot: :pawn)
        return if(old_pos.x == obj.x && old_pos.y == obj.y)

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
            @tiles[next_pos.uid][:ground].nil?()
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

        12.times do |i|
            break if(queue.empty?())
            res = Structure.new(
                x: start.x,
                y: start.y,
                r: 31,
                g: 46,
                b: 46,
                tick: state.tick_count,
                type: :stone
            )
            
            cur = queue.sample()
            visited[cur.uid] = cur
            queue.delete(id)

            res.x = cur.x
            res.y = cur.y
            
            @resources[res.type] = {} if(!@resources.has_key?(res.type))

            @resources[res.type][res.uid] = res
            @tiles[cur.uid][:ground] = res
            @world << res 

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


    def restart_counter()
        if(@globals.wave.values.length <= 0 && @invasion_tick <= 0)
            @survived += 1
            @invasion_tick = @invasion_temp 
        end
    end

    
    def spawn_enemies()
        spawn_count = 3 + 1 * @survived

        if(@globals.wave.values.length <= 0)
            @survived += 1
            @invasion_tick = @invasion_temp 
        end

        puts "need to spawn #{spawn_count - @globals.wave.length}"
      
        return if(@globals.wave.values.length > spawn_count)

        spawns = [
            [@dim - 1, 0],
            [0, @dim - 1],
            [@dim - 1, @dim - 1],
            [0, 0]
        ]
        (spawn_count - @globals.wave.length).times do |i|
            break if(spawns.empty?())

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
            
            if(@tiles[a_spawn].pawn.nil?() && @tiles[a_spawn].pawn.nil?())
                @world << pawn
                @pawns[pawn.uid] = pawn 
                @globals.faction_pawn_count[:'2'] += 1
                @globals.wave[pawn.uid] = pawn 
                @tiles[a_spawn].pawn = pawn
                update_tile(pawn, pawn)
            end
        end
    end


    def bgm_transition()
        
    end
end


def tick(args)
    args.outputs.background_color = [0, 0, 0]

    $views ||= {
        game: nil, 
        title: Title.new(args), 
        current: :title, 
        last: nil,
        debuggery: nil
    }

    if($views.current == :debuggery)
        $views.debuggery ||= Debuggery.new(args)
    end

    if($views.current != $views.last)
        puts "--view change--> #{$views.current}"
        $view = $views[$views.current]
        $views.last = $views.current
    end

    $view.args = args
    change = $view.tick()

    if(!change.nil?())
        $views[$views.current] = nil
        $views.current = change
        $views.game = Game.new(args) if(change == :game)
        $views.title = Title.new(args) if(change == :title)
        $view = $views[$views.current]
    end
end
