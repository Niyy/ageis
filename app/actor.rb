class Actor < DRObject
    attr_accessor :trail, :trail_end, :trail_start_time, :idle_ticks, 
                  :traded_tick, :task, :trail_max_range, :task_current


    def initialize(
        raiding: false, enemies: {}, 
        **argv
    )
        super
    
        @faction = faction
        @raiding = raiding
        @carrying = nil
        @idle_ticks = 0
        @task = nil
        @task_current = nil
        @type = :actor
        @traded_tick = 0

        # Combat
        @enemies = enemies
        @fight_range = 1
        @damage = 1
        @last_hit = 0
        @hit_refresh = 60
        
        setup_trail()
    end


    def update(tick_count, tasks, tiles, world, globals, audio)
        if(@task == nil && @trail_end == nil && tasks&.unassigned && !tasks.unassigned.empty?())
            @task = tasks.unassigned.shift()[1]
            @task_current = @task.start

            tasks.assigned[@task.uid] = @task
        end
        
        generate_personal_task(tick_count, world, tiles, tasks, globals)
        do_task(tick_count, world, tiles, tasks, globals)
        create_trail(tiles, tasks) if(@found.nil?() &&
                                      !@trail_end.nil?())
        move(tick_count, tiles, world, tasks, audio)
    end


    def do_task(tick_count, world, tiles, tasks, globals)
        if(@task.nil?() || @task_current.nil?())
            @idle_ticks += 1
            return
        end
        
        fetch(tick_count, world, tiles) if(@task_current == :fetch)
        build(tick_count, world, tiles) if(@task_current == :build)
        hunt(tick_count, world, tiles, tasks, globals) if(@task_current == :hunt)
        close_in(tick_count, world, tiles, globals) if(
            @task_current == :close_in
        )
        fight(tick_count, world, tiles, tasks, globals) if(
            @task_current == :fight
        )

        if(@task_current.nil?())
            setup_trail()
            tasks.assigned.delete(@task.uid)
            @task = nil
        end
    end


    def generate_personal_task(tick_count, world, tiles, tasks, globals)
        if(
           globals.wave.length > 0 && 
           globals.area_owner.faction == @faction &&
           !tasks.nil?() && (@task.nil?() ||
           !@task.has_key?(:fight))
          )
            if(!@task.nil?())
                tasks.assigned.delete(@task.uid)
                tasks.unassigned[@task.uid] = @task
            end

            @task = generate_fight(globals.wave.sample())
            @task_current = @task.start
        end 

        return if(@task)

        if((tasks&.assigned && tasks.assigned[[@x, @y]]) || 
           (tasks&.unassigned && tasks.unassigned[[@x, @y]]))
            setup_trail()
            @trail_end = nil 
            @trail_start_time = tick_count 
            @trail_max_range = 0
            trail_add_single(self, world, tiles, tasks)
            return
        end

        if(
           @raiding && globals.area_flag && 
           globals.area_owner.faction != @faction
        )
            @task = generate_fight(globals.area_flag)
            @task_current = @task.start

            return
        end
    end


    def fetch(tick_count, world, tiles)
        cur = @task[@task_current]
        
        if(!cur&.hit && in_range(self, cur.pos) > cur.range * cur.range)
            setup_trail()
            @trail_end = cur.pos 
            @trail_start_time = tick_count 
            @trail_max_range = cur.range
            cur.hit = true
        end

        if(in_range(self, cur.pos) <= cur.range * cur.range)
            @task_current = cur.nxt
            tiles[cur.pos].ground.reduce_supply()
        end
    end


    def build(tick_count, world, tiles)
        cur = @task[@task_current]
        
        if(!cur&.hit && in_range(self, cur.pos) > cur.range * cur.range)
            setup_trail()
            @trail_end = cur.pos 
            @trail_start_time = tick_count 
            @trail_max_range = cur.range
            cur.hit = true
        end

        if(in_range(self, cur.pos) <= cur.range * cur.range)
            @task_current = cur.nxt
            new_struct = Structure.new(cur.struct)

            new_struct.faction = @faction
            tiles[cur.pos][cur.spot] = new_struct
            world[new_struct.uid] = new_struct
        end
    end


    def hunt(tick_count, world, tiles, tasks, globals)
        if(globals.wave.length < 0)
            @task = nil
            @task_current = nil
            return
        end

        cur = @task[@task_current]

        if(@task.target)
            setup_trail
            @trail_end = @task.target 
            @trail_start_time = tick_count 
            @trail_max_range = @fight_range
            @task_current = :close_in
        end
    end


    def close_in(tick_count, world, tiles, globals)
        if(globals.wave.length < 0)
            @task = nil
            @task_current - nil
            return
        end

        cur = @task[@task_current]

        if(in_range(self, @task.target) <= @fight_range)
           @task_current = :fight

           return
        end

        if(@task.target.type == :actor)
            _queue = World_Tree.new()

            trail_add(tiles, self, [0, 1], @task.target, _queue)
            trail_add(tiles, self, [0, -1], @task.target, _queue)
            trail_add(tiles, self, [1, 0], @task.target, _queue)
            trail_add(tiles, self, [-1, 0], @task.target, _queue)
            trail_add(tiles, self, [1, 1], @task.target, _queue)
            trail_add(tiles, self, [1, -1], @task.target, _queue)
            trail_add(tiles, self, [-1, 1], @task.target, _queue)
            trail_add(tiles, self, [-1, -1], @task.target, _queue)


            @trail = [_queue.pop()]
        end
    end


    def generate_fight(target)
        return {
            start: :hunt,
            uid: target.uid,
            target: target, # Overall goal
            close_in: {
                nxt: :fight
            },
            fight: {
                nxt: :hunt
            },
            hunt: {
            }
        }
    end


    def search_in_range(tiles, search_range, search_angle, actor)
        x_lerp = Math.cos(search_angle)
        y_lerp = Math.sin(search_angle)
        range = search_range * search_range
        line_lerp = [actor.x, actor.y]

        while(
            search_range > ((line_lerp.x * line_lerp.x) + 
                            (line_lerp.y * line_lerp.y))
        )
            line_lerp.x += x_lerp 
            line_lerp.y += y_lerp
            s_tile = [line_lerp.x.abs, line_lerp.y.abs]

            if(
                tiles[s_tile] && tiles[s_tile].pawns&.faction && 
                @enemies[tiles[s_tile].pawns.faction]
            )
                return tiles[s_tile].pawns
            end
        end

        search_angle += 10

        return nil
    end


    def in_range(cur, pos)
        range = (cur.x - pos.x) * (cur.x - pos.x) +
                (cur.y - pos.y) * (cur.y - pos.y)

        return 1 if(range == 2)

        return range
    end


    def move(tick_count, tiles, world, tasks, audio)
        setup_trail if(@trail_end && @task == nil && in_range(self, @trail_end) <= @trail_max_range)
        return if(
            @trail.empty?() || 
            (tick_count - @trail_start_time) % 5 != 0
        )

        next_step = @trail.pop()

#        puts "moving #{next_step}"

        dir = [
            next_step.x - @x,
            next_step.y - @y
        ]

        dir.x = (dir.x / dir.x.abs()) if(dir.x != 0)
        dir.y = (dir.y / dir.y.abs()) if(dir.y != 0)
        
        if(
            !assess(tiles, next_step, self, dir) && 
            combat_assess(tiles, next_step, self, dir)
        )
            tile = tiles[next_step.uid]

            if(!tile.ground.nil?() && tick_count - @last_hit > @hit_refresh)
                tile.ground.reduce_supply(@damage)
               
                @last_hit = tick_count
                audio[get_uid] = {
                    input: 'sounds/effects/hit_sound.wav',
                    screenx: 0,
                    screeny: 0,
                    x: 0,
                    y: 0,
                    z: 0,
                    gain: 0.3,
                    pitch: 1.0,
                    looping: false,
                    paused: false
                }

                if(tile.ground.supply <= 0)
                    world.delete(tile.ground) 
                    tile.ground = nil
                end
            elsif(!tile.pawn.nil?())
                tile.pawn.reduce_supply(@damage)
    
                if(tile.pawn.supply <= 0)
                    world.delete(tile.pawn) 
                    tile.pawn = nil
                end
            end

            @trail.push(next_step)

            return
        elsif(
            !assess(tiles, next_step, self, dir)
        )
            @trail = []
            @trail_end = @task[@task_current].pos
            @found = nil
            @queue = World_Tree.new()
            @parents = {}
            return
        elsif(!assess(tiles, next_step, self, dir))
            if(tiles[next_step.uid].pawn == nil)
                @trail.push(next_step)
                @idle_ticks += 1             
                return
            elsif(!tiles[next_step.uid].pawn.nil?() && 
                  tiles[next_step.uid].pawn.traded_tick < tick_count &&
                  @traded_tick < tick_count
                 )
#                trail_add_single(self, world, tiles, tasks)
                trade_spots(tiles, next_step)
                @traded_tick = tick_count 
            end
        end
       
        @idle_ticks = 0
        @x = next_step.x
        @y = next_step.y

        return false if(@trail.empty?())
        return true
    end


    def trade_spots(tiles, next_step)
        in_way = tiles[next_step.uid].pawn
        tiles[next_step.uid].pawn = self
        tiles[[@x, @y]].pawn = in_way
    end


    def fight(tick_count, world, tiles, tasks, globals)
        if(globals.wave.length < 0)
            @task = nil
            @current_task = nil
            return
        end

        @task.target.reduce_supply(@damage)
        tile = [@task.target.x, @task.target.y]

        if(@task.target.supply <= 0)
            puts "#{@uid} [#{[@x, @y]}] ->killed: #{@task.target}"
            world.delete(@task.target) 
            tiles[tile].ground = nil if(@task.target.type == :struct)
            tiles[tile].pawn = nil if(@task.target.type == :actor)

#            globals.area_flag = nil if(
#                globals.area_flag.faction != @faction
#                @task.target.uid == globals.area_flag.uid 
#            )

            tasks.assigned.delete(@task.uid) if(tasks)
            @current_task = nil
            @task = nil

        end
    end


#    def trail_hunting(world, tiles)
#        world_center = @dim / 2
#    end


    def trail_add(tiles, cur, dif, trail_end = {x: -1, y: -1}, queue = [], 
                  parents = {})
        next_step = {
            x: cur.x + dif.x, 
            y: cur.y + dif.y, 
            uid: [cur.x + dif.x, cur.y + dif.y]
        }
        step_dist = sqr(trail_end.x - next_step.x) + 
            sqr(trail_end.y - next_step.y) 
        
        if(
            !parents.has_key?(next_step.uid) && 
            (
                assess(tiles, next_step, cur, dif) || 
                combat_assess(tiles, next_step, cur, dif) || 
                (
                    trail_end.x == cur.x &&
                    trail_end.y == cur.y
                )
            )
        )
            queue << next_step.merge({z: step_dist}) 
            parents[next_step.uid] = cur 
            return next_step
        end
    end


    def trail_add_single(cur, world, tiles, tasks = {})
        move_points = [
            [1, 0],
            [0, 1],
            [-1, 0],
            [0, -1],
            [1, 1],
            [-1, 1],
            [1, -1],
            [-1, -1]
        ]

        while(!move_points.empty?())
            delta = move_points.sample()
            move_points.delete(delta)

            next_step = {
                x: cur.x + delta.x, 
                y: cur.y + delta.y, 
                uid: [cur.x + delta.x, cur.y + delta.y]
            } 
            
            if(
                (tasks == nil || tasks.unassigned[next_step.uid] == nil) &&
                (tasks == nil || tasks.assigned[next_step.uid] == nil) &&
                assess(tiles, next_step, cur, delta)
            )
                @trail << next_step
                @trail_end = next_step if(@trail_end == nil)
                @found = @trail_end if(@found == nil)
                return
            end
        end
    end


    def setup_trail()
        @queue = World_Tree.new()
        @parents = {}
        @found = nil
        @trail = []
        @trail_end = nil
        @trail_start_time = -1
        @trail_max_range = 1
    end


    def create_trail(tiles, tasks)
        @queue << {x: @x, y: @y, z: 0, uid: [@x, @y]} 
        @parents[[@x, @y]] = {x: @x, y: @y, z: 0, uid: [@x, @y]}
        
        15.times() do |i|
            if(!@queue.empty?() && @found.nil?())
                cur = @queue.pop()

                if(in_range(cur, @trail_end) <= @trail_max_range * @trail_max_range)
                    @found = cur 
                    break
                end
                
                trail_add(tiles, cur, [0, 1], @trail_end, @queue, @parents)
                trail_add(tiles, cur, [0, -1], @trail_end, @queue, @parents)
                trail_add(tiles, cur, [1, 0], @trail_end, @queue, @parents)
                trail_add(tiles, cur, [-1, 0], @trail_end, @queue, @parents)
                trail_add(tiles, cur, [1, 1], @trail_end, @queue, @parents)
                trail_add(tiles, cur, [1, -1], @trail_end, @queue, @parents)
                trail_add(tiles, cur, [-1, 1], @trail_end, @queue, @parents)
                trail_add(tiles, cur, [-1, -1], @trail_end, @queue, @parents)
            end
        end

        if(!@found.nil?())
            @trail.clear()
            @trail_end = @found
            child = @found 

            while(@parents[child.uid].uid != child.uid)
                @trail << child 
                child = @parents[child.uid]
            end

            return
        end

        if(@queue.empty?() && @found.nil?())
            tasks.assigned.delete(@task.uid) if(tasks && @task)
            @task = nil
            @task_current = nil
        end
    end


    def assess(tiles, next_pos, og, dir = [0, 0])
        if(dir.x != 0 && dir.y != 0)
            return (
                tiles.has_key?(next_pos.uid) && 
                (
                    tiles[next_pos.uid].ground.nil?() || 
                    tiles[next_pos.uid].ground.passable
                ) &&
                tiles[next_pos.uid].pawn.nil?() &&
                tiles.has_key?([next_pos.x, og.y]) && 
                (
                    tiles[[next_pos.x, og.y]].ground.nil?() || 
                    tiles[[next_pos.x, og.y]].ground.passable
                ) && 
                tiles[[next_pos.x, og.y]].pawn.nil?() && 
                tiles.has_key?([og.x, next_pos.y]) && 
                (
                    tiles[[og.x, next_pos.y]].ground.nil?() ||
                    tiles[[og.x, next_pos.y]].ground.passable 
                ) &&
                tiles[[og.x, next_pos.y]].pawn.nil?()
            )
        end
        
        return (
            tiles.has_key?(next_pos.uid) && 
            (
                tiles[next_pos.uid].ground.nil?() || 
                tiles[next_pos.uid].ground.passable
            ) &&
            tiles[next_pos.uid].pawn.nil?()
        )
    end


    def combat_assess(tiles, next_pos, og, dir = [0, 0])
        if(dir.x != 0 && dir.y != 0)
            return (
                tiles.has_key?(next_pos.uid) && 
                tiles[next_pos.uid].ground.nil?() &&
                tiles[next_pos.uid].pawn.nil?() &&
                tiles.has_key?([next_pos.x, og.y]) && 
                tiles[[next_pos.x, og.y]].ground.nil?() && 
                tiles[[next_pos.x, og.y]].pawn.nil?() && 
                tiles.has_key?([og.x, next_pos.y]) && 
                tiles[[og.x, next_pos.y]].ground.nil?() &&
                tiles[[og.x, next_pos.y]].pawn.nil?()
            )
        end

        return (
            @enemies.has_key?(tiles[next_pos.uid]&.ground&.faction.to_s.to_sym) ||
            @enemies.has_key?(tiles[next_pos.uid]&.pawn&.faction.to_s.to_sym)
        )
    end


    def find_resource(world, type)
        world.resources.each() do |obj|
            if(obj&.type && obj.type == type)
                return obj
            end
        end

        return nil
    end


    def wander_for(world, tiles, tasks, ticks) 
        
    end


    def serialize()
        super().merge({
            idle_ticks: @idle_ticks,
            trail: @trail, 
            trail_end: @trail_end, 
            task: @task,
            task_current: @task_current
        })
    end
end
