class Pawn < DRObject
    attr_accessor :path_start, :path_max_range, :task
    attr_reader :target, :path_cur, :path_end, :path_start, :path_parents


    def initialize(**argv)
        super
        
        @task = nil
        @speed = 20
        @faction = argv.faction

        # Pathing
        clear_path()
    end


    def update(tick_count, tiles, player, factions = nil, world = nil, 
               globals = nil, audio = nil)
        get_task(player.tasks)
        assess_task(player.tasks, tiles)
        
        create_path(tiles)
        move(tick_count, tiles, world, audio)
    end


    def clear_path()
        @path_max_range = 1
        @target = nil
        @path_end = nil
        @path_parents = {}
        @path_queue = Min_Tree.new()
        @path_cur = []
        @path_start = -1
    end


    def path_queue_add(tiles, cur, dif, trail_end = [-1, -1], queue = [], 
        parents = {}
    )
        next_step = {
            tx: cur.tx + dif[0], 
            ty: cur.ty + dif[1], 
            uid: [cur.tx + dif[0], cur.ty + dif[1]]
        }
        step_dist = sq(trail_end[0] - next_step.tx) + 
            sq(trail_end[1] - next_step.ty) 

        step_dist += 2 if(dif[0] != 0 && dif[1] != 0)

        if(
            !parents.has_key?(next_step.uid) && 
            (
                assess(tiles, next_step, cur, dif)# || 
#                combat_assess(tiles, next_step, cur, dif) || 
#                (
#                    trail_end.x == cur.x &&
#                    trail_end.y == cur.y
#                )
            )
        )
            queue << next_step.merge({z: step_dist}) 
            parents[next_step.uid] = cur 
            return next_step
        end
    end


    def path_current_add_single(cur, world, tiles, tasks = {})
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



    def create_path(tiles)
        return if(@path_end || @target.nil?())

        _path_found = nil

        @path_queue << {tx: @tx, ty: @ty, z: 0, uid: [@tx, @ty]} 
        @path_parents[[@tx, @ty]] = {tx: @tx, ty: @ty, z: 0, uid: [@tx, @ty]}
        
        15.times() do |i|
            if(!@path_queue.empty?() && @path_found.nil?())
                cur = @path_queue.pop()
                puts "current: #{cur}"

                if(in_range(cur, @target) <= @path_max_range * @path_max_range)
                    puts "found #{cur}"
                    _path_found = cur 
                    break
                end

#                if(tiles[cur.uid] && tiles[cur.uid][:paths] && tiles[cur.uid][:paths][@target.tile])
#                    step_dist = sq(trail_end[0] - next_step.tx) + 
#                        sq(trail_end[1] - next_step.ty) 
#                    queue << next_step.merge({z: step_dist + cur.z}) 
#                    parents[tiles[cur.uid].paths[@target.tile].uid] = cur   
#                end
                
                path_queue_add(tiles, cur, [0, 1], @target.tile, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [0, -1], @target.tile, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [1, 0], @target.tile, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [-1, 0], @target.tile, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [1, 1], @target.tile, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [1, -1], @target.tile, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [-1, 1], @target.tile, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [-1, -1], @target.tile, @path_queue, 
                               @path_parents)
            end
        end

        if(!_path_found.nil?())
            puts 'found a path: creating final.'
            @path_cur.clear()
            @path_end = _path_found
            child = _path_found 

            while(@path_parents[child.uid].uid != child.uid)
                puts "adding #{child}"
                @path_cur << child 
#                tiles[child.uid][:path] = @target.tile
                child = @path_parents[child.uid]
            end

            return
        end

        if(@path_queue.empty?() && @path_found.nil?())
            tasks.assigned.delete(@task.uid) if(tasks && @task)
            @task = nil
            @task_current = nil
        end
    end


    def move(tick_count, tiles, world, audio)
        return if(@path_cur.empty?() || @path_end.nil?() || 
                  (tick_count - @path_start) % @speed != 0)
        puts "moving hehe"


        next_step = @path_cur.pop()

        dir = [
            next_step.tx - @tx,
            next_step.ty - @ty
        ]

        dir[0] = (dir[0] / dir[0].abs()) if(dir[0] != 0)
        dir[1] = (dir[1] / dir[1].abs()) if(dir[1] != 0)
        
#        return if(
#            fight_blocker(
#                tiles, 
#                tick_count, 
#                world,
#                next_step,
#                dir, 
#                audio
#            )
#        )
#        return if(move_around(tiles, next_step, tick_count, dir))
#        return if(init_repath(tiles, next_step, dir, tick_count))
#        return if(can_not_move(tiles, next_step, tick_count, dir))
       
        @idle_ticks = 0
        tiles[tile()][@type] = nil
        set_tx(next_step.tx)
        set_ty(next_step.ty)
        tiles[tile()][@type] = self 


#        check_for_repathing(tiles)

        return false if(@path_cur.empty?())
        return true
    end


    def assess(tiles, next_pos, original_tile, dir = [0, 0])
        if(dir[0] != 0 && dir[1] != 0)
            return (
                tiles.has_key?(next_pos.uid) && 
                (
                    tiles[next_pos.uid][:ground].nil?() || 
                    tiles[next_pos.uid][:ground].passable
                ) &&
                tiles[next_pos.uid][:pawn].nil?() &&
                tiles.has_key?([next_pos.tx, original_tile.ty]) && 
                (
                    tiles[[next_pos.tx, original_tile.ty]][:ground].nil?() || 
                    tiles[[next_pos.tx, original_tile.ty]][:ground].passable
                ) && 
                tiles[[next_pos.tx, original_tile.ty]][:pawn].nil?() && 
                tiles.has_key?([original_tile.tx, next_pos.ty]) && 
                (
                    tiles[[original_tile.tx, next_pos.ty]][:ground].nil?() ||
                    tiles[[original_tile.tx, next_pos.ty]][:ground].passable 
                ) &&
                tiles[[original_tile.tx, next_pos.ty]][:pawn].nil?()
            )
        end
        
        return (
            tiles.has_key?(next_pos.uid) && 
            (
                !tiles[next_pos.uid][:ground] || 
                tiles[next_pos.uid][:ground].passable
            ) &&
            tiles[next_pos.uid][:pawn].nil?()
        )
    end


    def combat_assess(tiles, next_pos, og, dir = [0, 0])
        if(dir.x != 0 && dir.y != 0)
            return (
                tiles.has_key?(next_pos.uid) && 
                tiles[next_pos.uid][:ground].nil?() &&
                tiles[next_pos.uid][:pawn].nil?() &&
                tiles.has_key?([next_pos.x, og.y]) && 
                tiles[[next_pos.x, og.y]][:ground].nil?() && 
                tiles[[next_pos.x, og.y]][:pawn].nil?() && 
                tiles.has_key?([og.x, next_pos.y]) && 
                tiles[[og.x, next_pos.y]][:ground].nil?() &&
                tiles[[og.x, next_pos.y]][:pawn].nil?()
            )
        end

        return (
            (
                tiles[next_pos.uid] &&
                tiles[next_pos.uid][:ground] &&
                @enemies.has_key?(tiles[next_pos.uid][:ground].
                                                       faction.
                                                       to_s.
                                                       to_sym) 
            ) || (
                tiles[next_pos.uid] &&
                tiles[next_pos.uid][:pawn] &&
                @enemies.has_key?(tiles[next_pos.uid][:pawn].
                                                       faction.
                                                       to_s.
                                                       to_sym)
            )
        )
    end


    def get_task(tasks)
        return if(@target || @task)
        
        clear_path()
        @task = tasks.pop()
    end


    def assess_task(world, tiles)
        return if(!@task || !@target)

        if(@target.check_end_state(@task))
            @task = nil
            @target = nil
            clear_path()
            return
        end

        @task.requirments.entries.each() do |req, need|
            if(req == :has)
                @target = @task.target if(@inventory[need.type])
                @target = world.find(need) if(!@inventory[need.type])
            end
        end
    end


    def check_end_state(state)
        state.entries.each() do |entry, value|
            return false if(entry == :supply && value != @supply)
        end

        return true 
    end


    def target=(value)
        clear_path()
        @target = value
    end


    def in_range(cur, pos)
        range = (cur.tx - pos.tx) * (cur.tx - pos.tx) +
                (cur.ty - pos.ty) * (cur.ty - pos.ty)

        return range
    end
end
