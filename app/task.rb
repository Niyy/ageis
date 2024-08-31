class Task
    attr_accessor :uid, :target, :max_range, :next_tasks, :spot, :parameters,
        :code


    def initialize(uid: -1, target: nil, max_range: 0, next_tasks: {"-1": nil},
        code: :nil, parameters: {}
    )
        @uid = uid
        @target = target
        @max_range = max_range
        @next_tasks = next_tasks
        @spot = :nil
        @parameters = parameters
    end


    def next_tasks(heuristic: "-1")
        retun @next_tasks[heuristic]
    end


    def range()
        return @max_range
    end
end
