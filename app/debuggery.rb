class Debuggery < View
    attr_accessor :wt


    def initialize(args)
        self.args = args
        gtk.write_file('file.log', '')
        puts 'hellow'
        $my_region ||= Region.new()

        $my_region.add_faction('1')

        (64).times() do |y|
            (64).times() do |x|
                $my_region.add_tile([x,y], Tile.new())
            end
        end
        
        actor = Actor.new(w: 64, h: 64, r: 255, g: 0, b: 0)
        $my_region[actor.uid] = actor
    end


    def tick()
#        test_world_tree()
        test_region()

        return nil
    end


    def test_region()
        outputs.primitives << $my_region.output()
        $my_region.args = args
        $my_region.update()
    end


    def test_world_tree()
        @wt ||= World_Tree.new()
        @dl ||= false
        @p ||= false

        @p = !@p if(inputs.keyboard.key_down.space)

        return nil if(@p || (state.tick_count % 15) != 0)
        
        if(@wt.branches.length < 18)
            entry = {z: (rand() * 10).floor, uid: get_uid().to_s}
            gtk.append_file('file.log', "in: #{entry}\n")
            @wt << entry

            gtk.append_file('file.log', "new count: #{@wt.branches.length}\n")
        end

        @dl = true if(@wt.branches.length >= 16)
        @dl = false if(@wt.branches.length <= (rand() * 2) + 5)

        if(@dl)
            (rand() * 4).floor().times do |i|
                out = @wt.branches.sample()
                gtk.append_file('file.log', "deleting #{out}\n")
                gtk.append_file('file.log', "deleted #{@wt.delete(out)}\n")
            end
        end

        return nil
    end
end
