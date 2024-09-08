class Tile
    attr_reader :contents 


    def initialize()
        @contents = {pawn: nil, ground: nil, flora: nil}
        @z = 0 
    end


    def [](key)
        return @contents[key]
    end


    def []=(key, value)
        @contents[key] = value
    end


    def has_key?(key)
        return @contents.has_key?(key)
    end
end
