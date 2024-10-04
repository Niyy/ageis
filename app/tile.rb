class Tile
    attr_reader :contents, :north, :north_east, :east, :south_east, :south,
        :south_west, :west, :north_west


    def initialize(pos)
        @pos = pos
        @contents = {}
        @z = 0 

        @north = [pos.x, pos.y + 1]
        @north_eas = [pos.x + 1, pos.y + 1]
        @east = [pos.x + 1, pos.y]
        @south_east = [pos.x + 1, pos.y - 1]
        @south = [pos.x, pos.y - 1]
        @south_west = [pos.x - 1, pos.y - 1]
        @west = [pos.x - 1, pos.y]
        @north_west = [pos.x - 1, pos.y + 1]
    end


    def [](key)
        return @contents[key]
    end


    def add(obj)
        @contents[obj.uid] = obj

        return obj
    end


    def []=(key, value)
        @contents[key] = value
    end


    def <<(obj)
        return add(obj) 
    end


    def delete(obj)
        @contents.delete(obj.uid) 
    end


    def >>(obj)
        return delete(obj)
    end


    def has_key?(obj)
        return @contents.has_key?(obj.uid)
    end


    def length()
        @contents.keys.length()
    end
end
