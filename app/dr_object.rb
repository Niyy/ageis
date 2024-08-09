class DRObject
    attr_sprite
    attr_accessor :x, :y, :z, :w, :h, :r, :g, :b, :a, :primitive_marker
    attr_reader :uid


    def initialize(x: 0, y: 0, z: 0, w: 1, h: 1, r: 0, g: 0, b: 0, 
    consumption: 1, production: 0, max_supply: 10, tick: 0, 
    primitive_marker: :solid)
        @x = x
        @y = y
        @z = z
        @w = w
        @h = h
        @r = r
        @g = g
        @b = b
        @max_supply = max_supply
        @consumption = consumption 
        @production = production
        @da = 255 / @max_supply
        @a = @da * @max_supply
        @supply = 0
        @tick = tick
        @primitive_marker = primitive_marker
        @uid = get_uid()
    end


    def update()
        supply += @production 
    end


    def serialize()
        {x: @x, y: @y, w: @w, h: @h, r: @r, g: @g, b: @b, a: @a, 
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
            z: @z,
            w: @w,
            h: @h,
            g: @g,
            b: @b,
            max_supply: @max_supply,
            consumption: @consumption,
            production: @production,
            tick: @tick,
            primitive_marker: @primitive_marker
        )
    end


    def out()
        serialize()
    end
end
