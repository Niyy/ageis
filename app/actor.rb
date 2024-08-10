class Actor < DRObject
    def initialize(**argv)
        super

        @carrying = nil
        @task = nil

        @trail = []
    end


    def update()
        do_task()
    end


    def do_task()
        return if(@task.nil?())

        if(!@carrying.nil?() && @carrying.type in @task.in.type)
            create_trail(@task.out.pos)
        elsif(!in_range(@task.in.pos)
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


    def move2(pawn)
         return if(
            pawn.trail.empty?() || 
            (state.tick_count - pawn.trail_start_time) % 30 != 0
        )       

        next_step = pawn.trail.pop()

        pawn.x = next_step.x
        pawn.y = next_step.y

        @update = true

        return false if(pawn.trail.empty?())
        return true
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


    def create_trail(trail_end)
        found = nil 
        queue = World_Tree.new()
        parents = {}

        queue << {x: @x, y: @y, z: 0, uid: [@x, @y]} 
        parents[[@x, @y]] = {x: @x, y: @y, z: 0, uid: [@x, @y]}

        while(!queue.empty?())
            cur = queue.pop()

            if(cur.x == trail_end.x && cur.y == trail_end.y)
                found = cur
                break
            end
            
            trail_add(cur, [0, 1], trail_end, queue, parents)
            trail_add(cur, [0, -1], trail_end, queue, parents)
            trail_add(cur, [1, 0], trail_end, queue, parents)
            trail_add(cur, [-1, 0], trail_end, queue, parents)
            trail_add(cur, [1, 1], trail_end, queue, parents)
            trail_add(cur, [1, -1], trail_end, queue, parents)
            trail_add(cur, [-1, 1], trail_end, queue, parents)
            trail_add(cur, [-1, -1], trail_end, queue, parents)
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
end
