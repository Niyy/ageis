class Structure < DR_Object
    attr_reader :passable


    def initialize(passable: false, **argv)
        super

        @static = true
        @type = :structure
        @passable = passable
    end
end