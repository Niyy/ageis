class Game < View
    def initialize(args)
        self.args = args
        puts 'hello my good sir.'
    end


    def tick()
        input()
    end


    def input()
        puts 'ping' if(inputs.keyboard.key_down.space)
    end
end
