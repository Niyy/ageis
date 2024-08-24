class Tile
    attr_accessor :z
    attr_reader :uid, :x, :y


    def initialize(world, x: -1, y: -1)
        @@world = world # Reference to the world data for actual value getting
        @uid = [x, y]
        @x = x
        @y = y
        @contents = {}
        @z = Integer::MAX 
    end


    def <<(content)
        if(@contents.has_key?(key))
            @contents[content.type] = content.uid
        end
    end


    def []=(key, content)
        if(@contents.has_key?(key))
            @contents[content.type] = content.uid
        end
    end


    def [](key)
        if(@contents.has_key?(key))
            return @@world[@contents[key]]
        end

        return nil
    end
end
