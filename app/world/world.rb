class World
    attr_reader :objs, :tiles, :dim, :bounds, :nonstatic, :width, :height

    def initialize(args, screen_offset, w: 32, h: 32, dim: 16)
        @dim = dim
        @width = dim
        @height = dim / 2
        @width_half = dim / 2
        @height_half = @height / 2
        @bounds = [w, h]
        @objs = {}
        @tiles = {}
        @nonstatic = {}
        @static = :static

        args.outputs[@static].w = @dim * @bounds[0]
        args.outputs[@static].h = @dim * @bounds[1]

        w.times() do |x|
            h.times() do |y|
                @tiles[[x, y]] = {}
                args.outputs[@static].primitives << {
                    x: iso_x(x, y, screen_offset), 
                    y: iso_y(x, y, screen_offset), 
                    w: @width, 
                    h: @height, 
                    path: 'sprites/isometric/blue.png'
                }.sprite!
            end
        end
    end


    def valid_add(obj)
        x = obj.x
        y = obj.y

        return @tiles[[x, y]]
    end


    def add(obj)
        x = obj.x
        y = obj.y

        puts "tile key #{[x,y]}"
        puts "tile #{@tiles[[x,y]]}"

        @tiles[[x, y]][obj.type] = {} if(!@tiles[[x, y]][obj.type])
        @tiles[[x, y]][obj.type][obj.uid] = obj
        @nonstatic[obj.uid] = obj if(!obj.static)
        @objs[obj.uid] = obj
    end


    def delete(obj)
        x = obj.x 
        y = obj.y 

        @tiles[[x, y]][obj.type].delete(obj.uid)
        @nonstatic.delete(obj.uid)
        @objs.delete(obj.uid)
    end


    def get_by_uid(uid)
        return @objs[uid]
    end


    def update(obj, old_position)
        x = obj.x        
        y = obj.y 

        return if(x == old_position.x && y == old_position.y)

        @tiles[old_position][obj.type].delete(obj.uid)

        @tiles[[x, y]][obj.type] = {} if(!@tiles[[x, y]][obj.type])
        @tiles[[x, y]][obj.type][obj.uid] = obj
    end


    def screen_to_map(pos)
        return [
            (pos.x / @dim).floor(),
            (pos.y / @dim).floor()
        ]
    end
   

    def render(args, screen_offset)
        _out = []

        _out << {
            x: screen_offset, 
            y: 0, 
            w: @dim * @bounds[0], 
            h: @dim * @bounds[1], 
            path: @static
        }
        _out << @objs.values.map() do |obj|
            {
                x: iso_x(obj.x, obj.y, screen_offset),
                y: iso_y(obj.x, obj.y, screen_offset),
                w: obj.w,
                h: obj.h,
                path: obj.path,
                primitive_marker: :sprite
            }
        end

        return _out
    end


    def iso_x(x, y, screen_offset)
        return ((x - y) * @width_half) + screen_offset.x
    end


    def iso_y(x, y, screen_offset)
        return ((x + y) * @height_half) + screen_offset.y
    end


    def screen_to_iso(pos)
        root = [
            ((((pos.x - @width_half) / @width_half) + (pos.y / @height_half)) / 2).floor(), 
            (((pos.y / @height_half) - ((pos.x - @width_half) / @width_half)) / 2).floor()
        ]

        return root
    end


    def tile_filled?(position, type, passing_qty)
        return true if(!(@tiles[position] && @tiles[position][type]))

        return @tiles[position][type].values.length <= passing_qty
    end
end