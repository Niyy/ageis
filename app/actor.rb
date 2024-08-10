class Actor < DRObject
    attr_accessor :trail, :trail_end, :trail_start_time


    def initialize(**argv)
        super

        @carrying = nil
        @task = nil
        
        @trail_end = nil
        @trail_start_time = 0
        @trail = []
    end


    def update(tick_count, tasks)
        puts tasks
        if(@task == nil && !tasks.empty?())
            @task = tasks.shift()
        end

        do_task(tick_count)
        move(tick_count)
    end


    def do_task(tick_count)
        return if(@task.nil?())

        if(!@carrying.nil?() && @carrying.type == @task.in.type && 
        @trail.empty?())
            @trail_end = {x: @task.out.x, y: @task.out.y}
            @trail_start_time = tick_count

            create_trail(@task.out.pos)
        elsif(!in_range(@task.in.pos, 1) && @trail.empty?())
            @trail_end = {x: @task.in.x, y: @task.in.y}
            @trail_start_time = tick_count

            create_trail(@task.in.pos)
            @trail.shift()
        end
    end


    def in_range(pos, range)
        return (
            (@x - pos.x).abs <= range &&
            (@y - pos.x).abs <= range
        )
    end


    def move(tick_count)
        return if(
            @trail.empty?() || 
            (tick_count - @trail_start_time) % 30 != 0
        )       

        next_step = @trail.pop()

        @x = next_step.x
        @y = next_step.y

        @update = true

        return false if(@trail.empty?())
        return true
    end


    def trail_add(tiles, cur, dif, trail_end = {x: 0, y: 0}, queue = [], 
    parents = {})
        next_step = {
            x: cur.x + dif.x, 
            y: cur.y + dif.y, 
            uid: [cur.x + dif.x, cur.y + dif.y]
        }
        step_dist = sqr(trail_end.x - next_step.x) + 
            sqr(trail_end.y - next_step.y) 
        
        if(!parents.has_key?(next_step.uid) && 
            assess(tiles, next_step, cur, dif)
        )
            queue << next_step.merge({z: step_dist}) 
            parents[next_step.uid] = cur 
        end
    end


    def create_trail(tiles)
        found = nil 
        queue = World_Tree.new()
        parents = {}

        queue << {x: @x, y: @y, z: 0, uid: [@x, @y]} 
        parents[[@x, @y]] = {x: @x, y: @y, z: 0, uid: [@x, @y]}

        while(!queue.empty?())
            cur = queue.pop()

            puts "cur: #{cur}"
            puts "trail_end: #{@trail_end}"

            if(cur.x == @trail_end.x && cur.y == @trail_end.y)
                found = cur
                break
            end
            
            trail_add(tiles, cur, [0, 1], @trail_end, queue, parents)
            trail_add(tiles, cur, [0, -1], @trail_end, queue, parents)
            trail_add(tiles, cur, [1, 0], @trail_end, queue, parents)
            trail_add(tiles, cur, [-1, 0], @trail_end, queue, parents)
            trail_add(tiles, cur, [1, 1], @trail_end, queue, parents)
            trail_add(tiles, cur, [1, -1], @trail_end, queue, parents)
            trail_add(tiles, cur, [-1, 1], @trail_end, queue, parents)
            trail_add(tiles, cur, [-1, -1], @trail_end, queue, parents)
        end
   
        @trail.clear()

        puts 'parent'
        puts parents

        if(!found.nil?())
            child = found 
        
            puts 'found'
            puts found

            while(parents[child.uid].uid != child.uid)
                puts '---------------'
                puts child

                @trail << child 
                child = parents[child.uid]
            end
        end

        puts 'trail'
        puts @trail
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
