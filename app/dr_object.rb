class DRObject
    attr_sprite
    attr_accessor :x, :y, :z, :w, :h, :r, :g, :b, :a, :primitive_marker, :type
    attr_reader :uid


    def initialize(x: 0, y: 0, z: 0, w: 1, h: 1, r: 0, g: 0, b: 0, 
    consumption: 1, production: 0, max_supply: 1, tick: 0,
    primitive_marker: :solid, type: nil)
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
        @supply = @max_supply
        @tick = tick
        @primitive_marker = primitive_marker
        @uid = get_uid()
        @type = nil
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


    def assess(tiles, next_pos, og, dir = [0, 0])
        if(dir.x != 0 && dir.y != 0)
            return (
                tiles.has_key?(next_pos.uid) && 
                tiles[next_pos.uid].ground.nil?() &&
                tiles[next_pos.uid].pawn.nil?() &&
                tiles.has_key?([next_pos.x, og.y]) && 
                tiles[[next_pos.x, og.y]].ground.nil?() && 
                tiles[[next_pos.x, og.y]].pawn.nil?() && 
                tiles.has_key?([og.x, next_pos.y]) && 
                tiles[[og.x, next_pos.y]].ground.nil?() &&
                tiles[[og.x, next_pos.y]].pawn.nil?()
            )
        end
        
        return (
            tiles.has_key?(next_pos.uid) && 
            tiles[next_pos.uid].ground.nil?() &&
            tiles[next_pos.uid].pawn.nil?()
        )
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
            primitive_marker: @primitive_marker,
            type: @type
        )
    end


    def out()
        serialize()
    end
end
