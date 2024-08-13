class Actor < DRObject
    attr_accessor :trail, :trail_end, :trail_start_time, :idle_ticks


    def initialize(
        faction: -1, raiding: false, enemies: {'1': 1}, 
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

        # Combat
        @enemies = enemies
        @fight_range = 1
        
        setup_trail()
    end


    def update(tick_count, tasks, tiles, world)
        if(@task == nil && !tasks.unassigned.empty?())
            @task = tasks.unassigned.shift()[1]
            @task_current = @task.start

            tasks.assigned[@task.uid] = @task

#            puts "[#{@uid}] new task: #{@task}"
        end
        
        generate_personal_task(tick_count, world, tiles, tasks)
        do_task(tick_count, world, tiles)
        create_trail(tiles) if(@found.nil?() && !@trail_end.nil?())
        move(tick_count, tiles, world, tasks)
    end


    def do_task(tick_count, world, tiles)
        if(@task.nil?() || @task_current.nil?())
            @idle_ticks += 1
            return
        end
        
        fetch(tick_count, world, tiles) if(@task_current == :fetch)
        build(tick_count, world, tiles) if(@task_current == :build)
        hunt(tick_count, world, tiles) if(@task_current == :hunt)

        if(@task_current.nil?())
            setup_trail()
            @task = nil
        end
    end


    def generate_personal_task(tick_count, world, tiles, tasks)
        return if(@task)

        if(tasks.assigned[[@x, @y]] || tasks.unassigned[[@x, @y]])

            setup_trail()
            @trail_end = nil 
            @trail_start_time = tick_count 
            @trail_max_range = 0
            trail_add_single(self, world, tiles, tasks)
        end
#        if(@raiding && @idle_count > 10)
#            @task = {
#                start: :hunt,
#                action: :hunt,
#                hunting_ticks: 0,
#                uid: get_uid(),
#                trail_setup: false,
#                search_angle: 0,
#                hunt: {
#                    target: nil,
#                    nxt: :hunt,
#                    range: 10,
#                    applicable_targets: {actors: 0, flag: 0, structs: 0}
#                }
#            }
#        end
    end


    def fetch(tick_count, world, tiles)
        cur = @task[@task_current]
        
        if(!cur&.hit && in_range(self, cur.pos) > cur.range * cur.range)
            setup_trail()
            @trail_end = cur.pos 
            @trail_start_time = tick_count 
            @trail_max_range = cur.range
            cur.hit = true

#            puts "trail_end: #{@trail_end}"
        end

        if(in_range(self, cur.pos) <= cur.range * cur.range)
            @task_current = cur.nxt
            tiles[cur.pos].ground.reduce_supply()

#            puts "trail: #{@trail}"
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

            cur.struct.faction = @faction
            tiles[cur.pos][cur.spot] = cur.struct
            world[cur.struct.uid] = cur.struct
            
#            puts "placed tiles: #{tiles[cur.pos]}"
        end
    end


    def hunt(tick_count, world, tiles)
        cur = @task[@task_current]
        if(@task.target.nil?())
            target = search_in_range(tiles, cur, self) 

            if(target)
                @task = generate_fight(target)
            end
        end
    end


    def close_in(tick_count, world, tiles)
        cur = @task[@task_current]
        
        if(in_range(self, cur.pos) > cur.range * cur.range)
            setup_trail()
            @trail_end = cur.pos 
            @trail_start_time = tick_count 
            @trail_max_range = cur.range
            cur.hit = true
        end

        if(in_range(self, cur.pos) <= cur.range * cur.range)
            @task_current = cur.nxt

            cur.struct.faction = @faction
            tiles[cur.pos][cur.spot] = cur.struct
            world[cur.struct.uid] = cur.struct
            
#            puts "placed tiles: #{tiles[cur.pos]}"
        end
    end


    def generate_fight(target)
        return {
            start: :close_in,
            type: :fight,
            uid: target.uid,
            target: target,
            close_in: {
                nxt: :fight
            },
            fight: {
                nxt: nil
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

        search_range += 10

        return nil
    end


    def in_range(cur, pos)
        range = (cur.x - pos.x) * (cur.x - pos.x) +
                (cur.y - pos.y) * (cur.y - pos.y)

        return 1 if(range == 2)

        return range
    end


    def move(tick_count, tiles, world, tasks)
        return if(
            @trail.empty?() || 
            (tick_count - @trail_start_time) % 5 != 0
        )

        next_step = @trail.pop()

        dir = [
            next_step.x - @x,
            next_step.y - @y
        ]

        dir.x = (dir.x / dir.x.abs()) if(dir.x != 0)
        dir.y = (dir.y / dir.y.abs()) if(dir.y != 0)

        if(
            !assess(tiles, next_step, self, dir) && @idle_ticks >= 2
        )
            @trail = []
            @trail_end = @task[@task_current].pos
            @found = nil
            @queue = World_Tree.new()
            @parents = {}
            return
        elsif(!assess(tiles, next_step, self, dir))
            @trail.push(next_step)

            if(
                tiles[next_step.uid].pawn == nil 
            )
                @idle_ticks += 1             
            else
                trail_add_single(self, world, tiles, tasks)
            end

            return
        end
        
        @idle_ticks = 0
        @x = next_step.x
        @y = next_step.y

        return false if(@trail.empty?())
        return true
    end


    def trail_add(tiles, cur, dif, trail_end = {x: -1, y: -1}, queue = [], 
                  parents = {})
        next_step = {
            x: cur.x + dif.x, 
            y: cur.y + dif.y, 
            uid: [cur.x + dif.x, cur.y + dif.y]
        }
        step_dist = sqr(trail_end.x - next_step.x) + 
            sqr(trail_end.y - next_step.y) 
        
        if(!parents.has_key?(next_step.uid) && ( 
                assess(tiles, next_step, cur, dif) || (
                    trail_end.x == cur.x &&
                    trail_end.y == cur.y
                )
            )
        )
            queue << next_step.merge({z: step_dist}) 
            parents[next_step.uid] = cur 
        end
    end


    def trail_add_single(cur, world, tiles, tasks)
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
            
            if((
                    tasks.unassigned[next_step.uid] == nil &&
                    tasks.assigned[next_step.uid] == nil && 
                    assess(tiles, next_step, cur, delta)
                )
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


    def create_trail(tiles)
        @queue << {x: @x, y: @y, z: 0, uid: [@x, @y]} 
        @parents[[@x, @y]] = {x: @x, y: @y, z: 0, uid: [@x, @y]}
        
        15.times() do |i|
            if(!@queue.empty?() && @found.nil?())
                cur = @queue.pop()

#                puts "#{$gtk.args.state.tick_count} - #{[cur.x, cur.y]} -> #{@trail_end}: #{in_range(cur, @trail_end, @trail_max_range)}"

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
            @task = nil
            @task_current = nil
        end
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
            trail: @trail, 
            trail_end: @trail_end, 
            task: @task,
            task_current: @task_current
        })
    end
end
