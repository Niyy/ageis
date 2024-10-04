class Game < View
    attr_accessor :world


    def initialize(args)
        self.args = args
        puts 'hello my good sir.'
        @world = World.new(w: 10, h: 10, dim: 32)

        puts 'world loaded'
    end


    def tick()
        input()
        output() 

        return nil
    end


    def input()
    end


    def output()
        outputs[:view].transient!
        outputs[:view].sprites << @world.objs.values
#        outputs.sprites << {x: 0, y: 0, w: 1280, h: 720, path: :view}
        outputs.sprites << @world.objs.values
    end
end
