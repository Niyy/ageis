class Tile
    attr_reader :contents, :north, :north_east, :east, :south_east, :south,
        :south_west, :west, :north_west


    def initialize(pos)
        @pos = pos
        @contents = {}
        @z = 0 

        @north = [pos, pos + 1]
        @north_eas = [pos + 1, pos + 1]
        @east = [pos + 1, pos]
        @south_east = [pos + 1, pos - 1]
        @south = [pos, pos - 1]
        @south_west = [pos - 1, pos - 1]
        @west = [pos - 1, pos]
        @north_west = [pos - 1, pos + 1]
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
