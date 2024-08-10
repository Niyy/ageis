class DRObject 
    attr_accessor :x, :y, :w, :h, :r, :g, :b, :a
    attr_reader :uid


    def initialize(x: 0, y: 0, w: 1, h: 1, r: 0, g: 0, b: 0, 
    consumption: 1, production: 0, max_supply: 10, tick: 0, 
    primitive_marker: :solid)
        @x = x
        @y = y
        @w = w
        @h = r
        @g = g
        @b = b
        @max_supply = max_supply
        @consumption = consumption
        @production = consumption
        @da = 255 / @max_supply
        @a = @da * @max_supply
        @supply = 0
        @tick = tick
        @primitive_marker = primitive_markera
        @uid = get_uid()
    end


    def reduce_supply()
        if(@supply > 0)
            @supply -= 1
            return 1
        end

        return 0
    end


    def update()
        supply += @production 
    end


    def serialize()
        {x: @x, y: @y, w: @w, h: @h, r: @r, g: @g, b: @b, 
         primitive_marker: @primitive_marker}
    end


    def inspect()
        serialize().to_s()
    end


    def to_s()
        serialize().to_s()
    end


    def copy()
        return DRObject.new(
            x: @x,
            y: @y,
            w: @w,
            h: @h,
            g: @g,
            b: @b,
            consumption: @consumption,
            max_supply: @max_supply,
            production: @production,
            supply: @supply,
            tick: @tick,
            primitive_marker: @primitive_marker
        )
    end
end
