class Structure < DR_Object
    attr_reader :passable


    def initialize(passable: false, **argv)
        super

        @static = true
        @type = :structure
        @passable = passable
    end


    def copy()
        return Structure.new(
            x: @tx,
            y: @ty,
            z: @z,
            w: @w,
            h: @h,
            g: @g,
            b: @b,
            tick: @tick,
            primitive_marker: @primitive_marker,
            type: @type,
            passable: @passable
        )
    end
end