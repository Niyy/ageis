class Actor < DRObject
    attr_accessor :trail, :trail_end, :trail_start_time


    def initialize(**argv)
        super

        @carrying = nil
        @task = nil
        
        @trail_end = nil
        @trail_start_time = 0
        @trail = []

        setup_trail()
    end


    def update(tick_count, tasks, tiles)
        if(@task == nil && !tasks.empty?())
            @task = tasks.shift()
        end

        do_task(tick_count, tiles)
        create_trail(tiles) if(@found.nil?() && !@trail_end.nil?())
        move(tick_count, tiles)
    end


    def do_task(tick_count, tiles)
        return if(@task.nil?())

        puts "carrying: #{@carrying}"
        puts "trail: #{@trail}"

        if(!@carrying.nil?() && @carrying == @task.in.type && 
        @trail.empty?())
                if(!in_range(@task.out, 1))
                    @trail_end = {x: @task.out.x, y: @task.out.y}
                    @trail_start_time = tick_count

                   setup_trail() 
                else
                    puts 'placing'
                    tiles[[@task.out.x, @task.out.y]] = @task.out.struct       
                    @carrying = nil
                    @task = nil
                    @trail.clear()
                end
        elsif(!in_range(@task.in, 1) && @trail.empty?())
            @trail_end = {x: @task.in.x, y: @task.in.y}
            @trail_start_time = tick_count

            setup_trail()
        elsif(in_range(@task.in, 1))
            tiles[[@task.in.x, @task.in.y]].ground.reduce_supply()
            @carrying = @task.in.type 
            @trail = []
        end
    end


    def in_range(pos, range)
        return (
            (@x - pos.x).abs <= range &&
            (@y - pos.y).abs <= range
        )
    end


    def move(tick_count, tiles)
        return if(
            @trail.empty?() || 
            (tick_count - @trail_start_time) % 10 != 0
        )       

        next_step = @trail.pop()

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

        return true if(next_step.x == trail_end.x && next_step.y == trail_end.y)
        
        if(!@parents.has_key?(next_step.uid) && 
            (assess(tiles, next_step, cur, dif) || (trail_end.x == cur.x &&
            trail_end.y == cur.y))
        )
            @queue << next_step.merge({z: step_dist}) 
            @parents[next_step.uid] = cur 
        end

        return false
    end


    def setup_trail()
        @queue = World_Tree.new()
        @parents = {}
        @found = nil
    end


    def create_trail(tiles)
        found = nil 
        parents = {}

        @queue << {x: @x, y: @y, z: 0, uid: [@x, @y]} 
        parents[[@x, @y]] = {x: @x, y: @y, z: 0, uid: [@x, @y]}

        if(!@queue.empty?() && @found.nil?())
            cur = @queue.pop()

            if(cur.x == @trail_end.x && cur.y == @trail_end.y)
                @found = cur
                break
            end
            
            fin = trail_add(tiles, cur, [0, 1], @trail_end, @queue, @parents)
            found = cur if(fin)
            fin = trail_add(tiles, cur, [0, -1], @trail_end, @queue, @parents)
            found = cur if(fin)
            fin = trail_add(tiles, cur, [1, 0], @trail_end, @queue, @parents)
            found = cur if(fin)
            fin = trail_add(tiles, cur, [-1, 0], @trail_end, @queue, @parents)
            found = cur if(fin)
            fin = trail_add(tiles, cur, [1, 1], @trail_end, @queue, @parents)
            found = cur if(fin)
            fin = trail_add(tiles, cur, [1, -1], @trail_end, @queue, @parents)
            found = cur if(fin)
            fin = trail_add(tiles, cur, [-1, 1], @trail_end, @queue, @parents)
            found = cur if(fin)
            fin = trail_add(tiles, cur, [-1, -1], @trail_end, @queue, @parents)
            found = cur if(fin)
        end
   
        @trail.clear()

        if(!found.nil?())
            @trail_end = found
            child = found 

            while(parents[child.uid].uid != child.uid)
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
