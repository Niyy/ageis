class Build_Interface
    def build(selected, mouse_x, mouse_y, pos, world, tiles)
        if(selected == :wall)
            return build_wall_task(mouse_x, mouse_y, pos, tiles, world)
        elsif(selected == :gate)
            return build_gate_task(mouse_x, mouse_y, pos, tiles, world)
        end
    end


    def build_wall_task(mouse_x, mouse_y, pos, tiles, world)
        return nil if(pos.nil?())

        return {
            start: :fetch,
            action: :build,
            building: :wall,
            uid: [mouse_x, mouse_y],
            fetch: {
                pos: [pos.x, pos.y],
                range: 1,
                type: :stone,
                hit: false,
                nxt: :build
            },
            build: {
                pos: [mouse_x, mouse_y],
                hit: false,
                nxt: nil,
                range: 1,
                spot: :ground,
                struct: {
                    x: mouse_x,
                    y: mouse_y,
                    w: 1,
                    h: 1,
                    z: 0,
                    type: :struct,
                    faction: -1,
                    max_supply: 10,
                    r: 23,
                    g: 200,
                    b: 150,
                    name: 'wall'
                }
            }
        }
    end


    def build_gate_task(mouse_x, mouse_y, pos, tiles, world)
        return nil if(pos.nil?())

        @current_selection = {
            start: :fetch,
            action: :build,
            building: :gate,
            uid: [mouse_x, mouse_y],
            fetch: {
                pos: [pos.x, pos.y],
                range: 1,
                type: :stone,
                hit: false,
                nxt: :build
            },
            build: {
                pos: [mouse_x, mouse_y],
                hit: false,
                nxt: nil,
                range: 1,
                spot: :ground,
                struct: {
                    x: mouse_x,
                    y: mouse_y,
                    w: 1,
                    h: 1,
                    z: 0,
                    type: :struct,
                    max_supply: 10,
                    r: 23,
                    g: 100,
                    b: 150,
                    passable: true,
                    name: 'gate'
                }
            }
        }
    end
end
