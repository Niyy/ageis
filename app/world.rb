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

        puts 'here man'

        (@h).floor().times() do |y|
            (@w).floor().times() do |x|
                @tiles[[x, y]] = Tile.new()
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


    def add(tile, position, obj)
        return if(!@tiles[tile] || @tiles[tile][position])
        
        @tiles[tile][position] = obj
        @pawns[obj.uid] = obj if(obj.type == :pawn)
        @objs[obj.uid] = obj
    end


    def [](obj)
        return @objs[obj.uid] = obj
    end

    
    def delete_on(tile, position)
        _delete = @tiles[tile][position]

        return if(!_delete)

        @pawns.delete(_delete.uid)
        @objs.delete(_delete)
        @tiles[tile][position] = nil
    end


    def delete_obj(obj, position)
         _delete = @tiles[obj.tile()][position]

        @pawns.delete(_delete.uid)
        @objs.delete(_delete)
        @tiles[obj.tile()][position] = nil       
    end
end
