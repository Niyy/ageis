class Game < View
    attr_accessor :world


    def initialize(args)
        self.args = args
        puts 'hello my good sir.'
        @screen_offset = [300, 0]
        @world = World.new(args, @screen_offset, w: 10, h: 10, dim: 64)
        @cursor_pos = [0, 0]

        pawn = Pawn.new(
            w: @world.width, 
            h: @world.height, 
            path: 'sprites/isometric/yellow.png',
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
        mouse_pos = [inputs.mouse.x, inputs.mouse.y]
        mouse_pos.x -= @screen_offset.x
        mouse_pos.y -= @screen_offset.y
        @cursor_pos = @world.screen_to_iso(mouse_pos)

        if(inputs.mouse.click)
            puts "screen #{[inputs.mouse.x, inputs.mouse.y]}, pos #{@cursor_pos}"
        end


        if(inputs.mouse.button_left && @world.valid_add(@cursor_pos) && @world.tile_filled?(@cursor_pos, :structure, 0))
            @world.add(Structure.new(
                x: @cursor_pos.x, 
                y: @cursor_pos.y, 
                w: @world.width, 
                h: @world.height, 
                path: 'sprites/isometric/black.png',
                primitive_marker: :sprite
            ))            
        end
    end


    def output()
        outputs[:view].transient!
#        outputs[:view].sprites << @world.objs.branches
#        outputs.sprites << {x: 0, y: 0, w: 1280, h: 720, path: :view}
        outputs.sprites << @world.render(args, @screen_offset)
        outputs.labels << {x: 0, y: 700, text: @cursor_pos, r: 0}
    end


    def update()
        @world.nonstatic.values.each() do |obj|
            obj.update(state.tick_count, @world)
        end
    end
end
