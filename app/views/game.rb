class Game < View
    attr_accessor :world


    def initialize(args)
        self.args = args
        puts 'hello my good sir.'
        @world = World.new(args, w: 10, h: 10, dim: 64)
        @cursor_pos = [0, 0]

        pawn = Pawn.new(
            w: @world.dim, 
            h: @world.dim, 
            path: 'sprite/circle/yellow.rb',
            static: false
        )
        pawn.target = [2, 2]
        
        @world.add(pawn)

        puts 'world loaded'
    end


    def tick()
        input()
        output() 
        update()

        return nil
    end


    def input()
        @cursor_pos = @world.screen_to_map(inputs.mouse)

        if(inputs.mouse.button_left && @world.valid_add(@cursor_pos))
            @world.add(DR_Object.new(
                x: @cursor_pos.x, 
                y: @cursor_pos.y, 
                w: @world.dim, 
                h: @world.dim, 
                path: 'sprites/square/black.png'
            ))            
        end
    end


    def output()
        outputs[:view].transient!
#        outputs[:view].sprites << @world.objs.branches
#        outputs.sprites << {x: 0, y: 0, w: 1280, h: 720, path: :view}
        outputs.sprites << @world.render(args)
        outputs.labels << {x: 0, y: 700, text: @cursor_pos, r: 0}
    end


    def update()
        @world.nonstatic.values.each() do |obj|
            obj.update(state.tick_count, @world)
        end
    end
end
