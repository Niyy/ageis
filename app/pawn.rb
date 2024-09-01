class Pawn < DRObject
    def initialize(**argv)
        super

        # Pathing
        clear_path()
    end


    def update(tick_count, tasks, tiles, world, globals, audio, player)
        super
        
        create_path() if()
        
    end


    def clear_path()
        @path_min_range = 1
        @target = nil
        @path_end = nil
        @path_parents = {}
        @path_queue = []
        @path_cur = []
    end


    def path_queue_add(tiles, cur, dif, trail_end = {x: -1, y: -1}, queue = [], 
        parents = {}
    )
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



    def create_path()
        @path_queue << {x: @x, y: @y, z: 0, uid: [@x, @y]} 
        @path_parents[[@x, @y]] = {x: @x, y: @y, z: 0, uid: [@x, @y]}
        
        15.times() do |i|
            if(!@path_queue.empty?() && @path_found.nil?())
                cur = @path_queue.pop()

                if(in_range(cur, [target.tile]) <= @path_min_range * @path_cur_max_range)
                    puts "in range found #{in_range(cur, @path_end)}"
                    puts "found #{cur}"
                    @path_end = cur 
                    break
                end
                
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

        if(!@path_found.nil?())
            @path_cur.clear()
            @path_end = @path_found
            child = @path_found 

            while(@path_parents[child.uid].uid != child.uid)
                @path_cur << child 
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


    def move(tick_count, tiles, world, tasks, audio)
        next_step = @trail.pop()

        dir = [
            next_step.x - @x,
            next_step.y - @y
        ]

        dir.x = (dir.x / dir.x.abs()) if(dir.x != 0)
        dir.y = (dir.y / dir.y.abs()) if(dir.y != 0)
        
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
        @x = next_step.x
        @y = next_step.y

        check_for_repathing(tiles)

        return false if(@trail.empty?())
        return true
    end


    def assess(tiles, next_pos, original_tile, direction = [0, 0])
        if(dir.x != 0 && dir.y != 0)
            return (
                tiles.has_key?(next_pos.uid) && 
                (
                    tiles[next_pos.uid][:ground].nil?() || 
                    tiles[next_pos.uid][:ground].passable
                ) &&
                tiles[next_pos.uid][:pawn].nil?() &&
                tiles.has_key?([next_pos.x, og.y]) && 
                (
                    tiles[[next_pos.x, og.y]][:ground].nil?() || 
                    tiles[[next_pos.x, og.y]][:ground].passable
                ) && 
                tiles[[next_pos.x, og.y]][:pawn].nil?() && 
                tiles.has_key?([og.x, next_pos.y]) && 
                (
                    tiles[[og.x, next_pos.y]][:ground].nil?() ||
                    tiles[[og.x, next_pos.y]][:ground].passable 
                ) &&
                tiles[[og.x, next_pos.y]][:pawn].nil?()
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


    def tile()
        return [@x, @y]
    end
end
