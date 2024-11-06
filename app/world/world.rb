class World
    attr_reader :objs, :tiles, :dim, :bounds, :nonstatic, :width, :height


    def initialize(args, screen_offset, w: 32, h: 32, dim: 16)
        @dim = dim
        @width = dim
        @height = dim / 2
        @width_half = dim / 2
        @height_half = @height / 2
        @bounds = [w, h]
        @objs = Ordered_Tree.new()
        @tiles = {}
        @nonstatic = {}
        @static = :static
        @internal_offset = [0, 0]
        @internal_offset = [iso_x(10, 0), 0]
        @world_size = [2560, 2560]

        puts @internal_offset

        args.outputs[@static].w = @world_size.x 
        args.outputs[@static].h = @world_size.y 

        w.times() do |x|
            h.times() do |y|
                @tiles[[x, y]] = {}
                args.outputs[@static].primitives << {
                    x: iso_x(x, y), 
                    y: iso_y(x, y), 
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
        @objs << obj
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
   

    def render(args, screen_offset)
        _out = []

        _out << {
            x: 0, 
            y: 0, 
            w: 1280, 
            h: 740, 
            source_x: screen_offset.x,
            source_y: screen_offset.y,
            source_w: 1280,
            source_h: 740,
            path: @static
        }
        args.outputs[:update].transient!
        args.outputs[:update].w = @world_size.x 
        args.outputs[:update].h = @world_size.y

        args.outputs[:update].sprites << @objs.values.map() do |obj|
            {
                x: iso_x(obj.x, obj.y),
                y: iso_y(obj.x, obj.y),
                w: obj.w,
                h: obj.h,
                path: obj.path,
                primitive_marker: :sprite
            }
        end
        _out << {
            x: 0, 
            y: 0, 
            w: 1280, 
            h: 740, 
            source_x: screen_offset.x,
            source_y: screen_offset.y,
            source_w: 1280,
            source_h: 740,
            path: :update 
        }

        return _out
    end


    def iso_x(x, y)
        return ((x - y) * @width_half) + @internal_offset.x
    end


    def iso_y(x, y)
        return ((x + y) * @height_half) + @internal_offset.y
    end


    def screen_to_iso(pos)
        pos.x -= @internal_offset.x
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
