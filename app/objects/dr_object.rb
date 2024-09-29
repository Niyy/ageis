class DRObject
    attr_sprite
    attr_accessor :z, :w, :h, :r, :g, :b, :a, :primitive_marker, :type,
        :faction, :supply, :enemies, :name
    attr_reader :uid, :x, :y


    def initialize(x: 0, y: 0, z: 0, w: 1, h: 1, r: 0, g: 0, b: 0, 
    consumption: 1, production: 0, max_supply: 1, tick: 0, faction: -1,
    primitive_marker: :solid, type: nil)
        @z = z
        @w = w
        @h = h
        set_x(x)
        set_y(y)
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
        @type = type
        @faction = faction
    end

    
    def reduce_supply(by = 1)
        if(@supply > 0)
            @supply -= by
            return by
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
        {uid: @uid, x: @x, y: @y, tx: @tx, ty: @ty, w: @w, h: @h, r: @r, g: @g, 
        b: @b, a: @a, primitive_marker: @primitive_marker}
    end


    def inspect()
        serialize().to_s()
    end


    def to_s()
        serialize().to_s()
    end


    def copy()
        return DRObject.new(
            x: @tx,
            y: @ty,
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


    def x=(val)
        set_x(val)
    end


    def y=(val)
        set_y(val)
    end


    def set_x(val)
        puts "value x: #{val}"
        @tx = val
        @x = val * @w 
    end


    def set_y(val)
        puts "value y: #{val}"
        @ty = val
        @y = val * @h 
    end
end
