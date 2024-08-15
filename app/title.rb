class Title < View
    attr_accessor :ui, :current_element, :start


    def initialize(args)
        self.args = args

        @current_element = nil
        @start = false
        @ui = {
            x: 0,
            y: 0,
            w: 64,
            h: 64,
            uid: get_uid,
            path: 'sprites/ui/title.png',
            elements: {
                start: create_button(25, 16, 'Start') 
            }
        }.sprite!
    end
    

    def create_button(x, y, text)
        {
            x: x,
            y: y,
            w: (text.length * 4) + 1,
            h: 8,
            r: 255,
            g: 255,
            b: 255,
            entered: false,
            uid: get_uid,
            on_enter: ->(me) {
                me.entered = true
                me.elements.label.r = 94 
                me.elements.label.g = 159 
                me.elements.label.b = 191 
            },
            on_exit: ->(me) {
                me.entered = false
                chg = me.elements.label
                chg.r = chg.g = chg.b = 255
            },
            on_click: ->(me) {
                @start = true
            },
            elements: {
                label: {
                    x: x + 2,
                    y: 6 + y,
                    text: text,
                    size_px: 5,
                    font: 'fonts/NotJamPixel5.ttf',
                    r: 255,
                    g: 255,
                    b: 255,
                    skip: true
                }.label!
            }
        }.border!
        
    end


    def input()
        last = nil
        queue = [@ui]
        mouse = {
            x: ((inputs.mouse.x - 288) / 11).floor(),
            y: ((inputs.mouse.y - 8) / 11).floor(),
            w: 1,
            h: 1
        }
        
        while(!queue.empty?())
            elm = queue.pop()

            next if(elm.has_key?(:skip))

            collision = mouse.intersect_rect?(elm)

            if(collision)
                last = elm
                queue.push(*elm.elements.values) if(elm.has_key?(:elements))
            end
        end

        if(!last.nil?() && last.has_key?(:on_enter) && !last.entered)
        # On Enter
            @current_element = last
            last.on_enter.call(last)
        end

        if(
           !@current_element.nil?() && 
           (last.nil?() || last.uid != @current_element.uid)
          )
        # On Exit
            @current_element.on_exit.call(@current_element)
            @current_element = nil 
        end

        if(!last.nil?() && last.has_key?(:on_click) && inputs.mouse.click)
        # On Click
            last.on_click.call(last)
        end
    end


    def ui_out()
        out = []
        queue = [@ui]

        while(!queue.empty?())
            cur = queue.pop()

            out << cur

            queue.push(*cur.elements.values) if(cur.has_key?(:elements))
        end

        out
    end


    def tick()
        input()

        outputs[:view_title].transient!
        outputs[:view_title].w = 64
        outputs[:view_title].h = 64
        outputs[:view_title].background_color = [0, 0, 0]
        outputs[:view_title].primitives << ui_out() 

        outputs.primitives << {
            x: 288, 
            y: 8, 
            w: 704, 
            h: 704, 
            path: :view_title
        }.sprite!
        
        return :game if(@start)
        return nil if(@start)
    end
end
