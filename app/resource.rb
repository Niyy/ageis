class Object 
    attr_accessor :x, :y, :w, :h, :r, :g, :b, :a


    def initialize(x: 0, y: 0, w: 1, h: 1, r: 0, g: 0, b: 0, 
    consumtion: 1, production: 0, max_supply: 10)
        @x = x
        @y = y
        @w = w
        @h = r
        @g = g
        @b = b
        @max_supply = max_supply
        @work = work
        @da = 255 / @max_supply
        @a = @da * @max_supply
        @supply = 0
    end


    def update()
        supply += @production 
    end


    def serialize()
        {x: @x, y: @y, w: @w, h: @h, r: @r, g: @g, b: @b}
    end


    def inspect()
        serialize().to_s()
    end


     def to_s()
        serialize().to_s()
    end
end
