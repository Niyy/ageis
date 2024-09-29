class World
    attr_accessor :pawns, :tiles, :dim, :w, :h


    def initialize(w: 64, h: 64, dim: 1, render_chunk_size: 32)
        @w = w
        @h = h
        @render_chunck_size = render_chunk_size
        @dim = dim
        @objs = Min_Tree.new()
        @tiles = {}
        @render_chuncks = []
        @pawns = {}
        @messages = []

        puts 'here man'

        (@h).floor().times() do |y|
            (@w).floor().times() do |x|
                @tiles[[x, y]] = Tile.new()

#                @render_chuncks = [] if(@render_chunks[[x, y]])
            end
        end
    end


    def render(x: 0, y: 0, w: 1280, h: 720, zoom: 1)
#        _out = []
#        _x_start = (x / @dim).floor()
#        _y_start = (y / @dim).floor()
#        _x_count = (w / @dim).floor()
#        _y_count = (h / @dim).floor()
#        _x_end = _x_start + _x_count 
#        _y_end = _y_start + _y_count
#
#        _y_count.times do |_y|
#            _x_count.times do |_x|
#                _y_tile = _y_end - _y
#                _x_tile = _x_end - _x
#
#                next if(!@tiles[[_x_tile, _y_tile]])
#                
#                _out << @tiles[[_x_tile, _y_tile]].render()
#            end
#        end
#
#        _out

        return @objs.branches
    end


    def add(tile, obj)
        if(!@tiles[tile] || @tiles[tile][obj.uid] || @tiles[tile].length > 0)
            @messages << 'Tile is occupied'
        end
        
        @tiles[tile][obj.uid] = obj
        @pawns[obj.uid] = obj if(obj.type == :pawn)
        @objs[obj.uid] = obj
    end


    def [](obj)
        return @objs[obj.uid] = obj
    end

    
    def delete_on(tile, uid)
        _delete = @tiles[tile][uid]

        return if(!_delete)

        @pawns.delete(_delete.uid)
        @objs.delete(_delete)
        @tiles[tile].delete(uid)
    end


    def delete_obj(obj)
        _delete = @tiles[obj.tile()][obj.uid]

        @pawns.delete(_delete.uid)
        @objs.delete(_delete)
        @tiles[obj.tile()][obj.uid]     
    end
end
