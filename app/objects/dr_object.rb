class DR_Object
    attr_accessor :z, :w, :h, :r, :g, :b, :a, :primitive_marker, :type,
        :faction, :name, :static
    attr_reader :uid, :x, :y, :z
    attr_sprite


    def initialize(x: 0, y: 0, z: 0, w: 1, h: 1, r: 0, g: 0, b: 0, path: 'sprites/circle/white.rb', 
        faction: -1, primitive_marker: :solid, type: :dr_object, static: true
    )
        @x = 0
        @y = 0
        @z = 0
        @w = w
        @h = h
        set_x(x)
        set_y(y)
        @r = r
        @g = g
        @b = b
        @a = 255
        @primitive_marker = primitive_marker
        @uid = get_uid()
        @type = type
        @faction = faction
        @path = path
        @static = static
    end


    def update(tick_count, world)
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
            x: @x,
            y: @y,
            z: @z,
            w: @w,
            h: @h,
            g: @g,
            b: @b,
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
        @x = val 
        @z = (@x * @x) + (@y * @y)
    end


    def set_y(val)
        @y = val
        @z = (@x * @x) + (@y * @y)
    end
end
