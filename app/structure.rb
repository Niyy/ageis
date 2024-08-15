class Structure < DRObject
    attr_accessor :passable


    def initialize(name: 'what am i', passable: false, resource: :stone, **argv)
        super

        @passable = passable
        @resource = resource
    end
end
