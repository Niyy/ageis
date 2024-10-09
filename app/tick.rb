$uid_file ||= 0
$paused ||= false
$debug ||= true 


def get_uid()
    out_uid = $uid_file
    $uid_file += 1

    return out_uid.to_s
end


def sqr(x)
    return x * x
end


def create_view(args, views, current_view)
    views[current_view] = Game.new(args) if(current_view == :game)
    views[current_view] = Debuggery.new(args) if(current_view == :debuggery)
end


def tick(args)
    args.outputs.background_color = [0, 0, 0]

    $views ||= {
        game: nil, 
#        title: Title.new(args), 
        current: :game, 
        last: nil,
        debuggery: nil
    }

    if($views.current != $views.last)
        puts "--view change--> #{$views.current}"
        create_view(args, $views, $views.current)
        puts $views
        $view = $views[$views.current]
        $views.last = $views.current
    end
    
    if($view)
        $view.args = args
        change = $view.tick()
    end

    if(!change.nil?())
        $views[$views.current] = nil
        $views.current = change
        $views.game = Game.new(args) if(change == :game)
        $views.title = Title.new(args) if(change == :title)
        $view = $views[$views.current]
    end
end
