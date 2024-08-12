class Actor < DRObject
    attr_accessor :trail, :trail_end, :trail_start_time


    def initialize(faction: -1, raiding: false, **argv)
        super
    
        @faction = faction
        @raiding = raiding
        @carrying = nil
        @task = nil
        @task_current = nil
        
        setup_trail()
    end


    def update(tick_count, tasks, tiles, world)
        if(@task == nil && !tasks.unassigned.empty?())
            @task = tasks.unassigned.shift()[1]
            @task_current = @task.start

            tasks.assigned[@task.uid] = @task

#            puts "[#{@uid}] new task: #{@task}"
        end

        do_task(tick_count, world, tiles)
        create_trail(tiles) if(@found.nil?() && !@trail_end.nil?())
        move(tick_count, tiles)
    end


    def do_task(tick_count, world, tiles)
        return if(@task.nil?() || @task_current.nil?())
        
        fetch(tick_count, world, tiles) if(@task_current == :fetch)
        build(tick_count, world, tiles) if(@task_current == :build)

        if(@task_current.nil?())
            setup_trail()
            @task = nil
        end
    end


    def fetch(tick_count, world, tiles)
        cur = @task[@task_current]
        
        if(!cur&.hit && !in_range(self, cur.pos, cur.range))
            setup_trail()
            @trail_end = cur.pos 
            @trail_start_time = tick_count 
            @trail_max_range = cur.range
            cur.hit = true

#            puts "trail_end: #{@trail_end}"
        end


        if(in_range(self, cur.pos, cur.range))
            @task_current = cur.nxt
            tiles[cur.pos].ground.reduce_supply()

#            puts "trail: #{@trail}"
        end
    end


    def build(tick_count, world, tiles)
        cur = @task[@task_current]
        
        if(!cur&.hit && !in_range(self, cur.pos, cur.range))
            setup_trail()
            @trail_end = cur.pos 
            @trail_start_time = tick_count 
            @trail_max_range = cur.range
            cur.hit = true
        end

        if(in_range(self, cur.pos, cur.range))
            @task_current = cur.nxt

            cur.struct.faction = @faction
            tiles[cur.pos][cur.spot] = cur.struct
            world[cur.struct.uid] = cur.struct
            
#            puts "placed tiles: #{tiles[cur.pos]}"
        end
    end


    def in_range(cur, pos, range)
        return (
            (cur.x - pos.x).abs <= range &&
            (cur.y - pos.y).abs <= range
        )
    end


    def move(tick_count, tiles)
        return if(
            @trail.empty?() || 
            (tick_count - @trail_start_time) % 5 != 0
        )

        next_step = @trail.pop()

        dir = [
            next_step.x - @x,
            next_step.y - @y
        ]

        dir.x = (dir.x / dir.x.abs())
        dir.y = (dir.y / dir.y.abs())

        if(!assess(tiles, next_step, self, dir) && !in_range(self, next_step, 1))
#            puts 'clearing trail.'
            @trail.clear()
            @found = nil
            @queue = World_Tree.new()
            @parents = {}
        end

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

                if(in_range(cur, @trail_end, @trail_max_range))
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

#            puts 'trail'
#            puts @trail
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
end
