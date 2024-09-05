class Pawn < DRObject
    attr_accessor :path_start, :path_max_range, :task
    attr_reader :target, :path_cur, :path_end, :path_start


    def initialize(**argv)
        super

        @task = nil
        @speed = 20

        # Pathing
        clear_path()
    end


    def update(tick_count, tiles, player, factions = nil, world = nil, 
               globals = nil, audio = nil)
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

        @path_queue << {x: @x, y: @y, z: 0, uid: [@x, @y]} 
        @path_parents[[@x, @y]] = {x: @x, y: @y, z: 0, uid: [@x, @y]}
        
        15.times() do |i|
            if(!@path_queue.empty?() && @path_found.nil?())
                cur = @path_queue.pop()

                if(in_range(cur, @target) <= @path_max_range * @path_max_range)
                    puts "found #{cur}"
                    _path_found = cur 
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

        if(!_path_found.nil?())
            @path_cur.clear()
            @path_end = _path_found
            child = _path_found 

            while(@path_parents[child.uid].uid != child.uid)
                puts "adding #{child}"
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


    def move(tick_count, tiles, world, audio)
        return if(@path_cur.empty?() || @path_end.nil?() || 
                  (tick_count - @path_start) % @speed != 0)
        puts "moving hehe"


        next_step = @path_cur.pop()

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
        tiles[tile()][@type] = nil
        @x = next_step.x
        @y = next_step.y
        tiles[tile()][@type] = self 


#        check_for_repathing(tiles)

        return false if(@path_cur.empty?())
        return true
    end


    def assess(tiles, next_pos, original_tile, dir = [0, 0])
        if(dir.x != 0 && dir.y != 0)
            return (
                tiles.has_key?(next_pos.uid) && 
                (
                    tiles[next_pos.uid][:ground].nil?() || 
                    tiles[next_pos.uid][:ground].passable
                ) &&
                tiles[next_pos.uid][:pawn].nil?() &&
                tiles.has_key?([next_pos.x, original_tile.y]) && 
                (
                    tiles[[next_pos.x, original_tile.y]][:ground].nil?() || 
                    tiles[[next_pos.x, original_tile.y]][:ground].passable
                ) && 
                tiles[[next_pos.x, original_tile.y]][:pawn].nil?() && 
                tiles.has_key?([original_tile.x, next_pos.y]) && 
                (
                    tiles[[original_tile.x, next_pos.y]][:ground].nil?() ||
                    tiles[[original_tile.x, next_pos.y]][:ground].passable 
                ) &&
                tiles[[original_tile.x, next_pos.y]][:pawn].nil?()
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


    def target=(value)
        clear_path()
        @target = value
    end


    def in_range(cur, pos)
        range = (cur.x - pos.x) * (cur.x - pos.x) +
                (cur.y - pos.y) * (cur.y - pos.y)

        return range
    end
end
