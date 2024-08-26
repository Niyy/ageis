class Action
    attr_accessor :headers, :action


    def initialize(action: nil, headers: {})
        @action = action
        @headers = headers
    end


    def act(owner, **argv)
        @action.call(owner, @headers, **argv)
    end
end
