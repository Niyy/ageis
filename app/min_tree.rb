class Min_Tree 
    attr_reader :branches, :resources, :named_lookup


    def initialize(branches: {})
        @branches = []
        @named_lookup = {}

        branches.values().each() do |branch|
            push(branch)
        end
    end


    def [](key)
        return nil if(!@named_lookup.has_key?(key))

        return @branches[@named_lookup[key]] 
    end


    def []=(key, value)
        if(@named_lookup.has_key?(key))
            delete(value)
        end

        push(value)
    end


    def <<(branch)
        if(@named_lookup.has_key?(branch.uid))
            delete(branch)
        end

        push(branch)
    end


    def pop()
        return nil if(@branches.empty?())
        
        parent = 0
        trade = @branches.length() - 1
        hold = @branches[trade]
        @branches[trade] = @branches[parent]
        @branches[parent] = hold
        @named_lookup[hold.uid] = parent

        pop_val = @branches.pop()
        @named_lookup.delete(pop_val.uid)
    
        balance(@branches.length() - 1) if(!@branches.empty?())

        return pop_val
    end


    def push(branch)
        @branches << branch
        @named_lookup[branch.uid] = @branches.length() - 1

        balance(@branches.length() - 1)
    end


    def delete(branch)
        return nil if(!@named_lookup.has_key?(branch.uid))

        if(
            @named_lookup[branch.uid] >= @branches.length
        )
            return @named_lookup.delete(branch.uid)
        end

        parent = @named_lookup[branch.uid]
        trade = @branches.length() - 1
        hold = @branches[trade]

        @branches[trade] = @branches[parent]
        @branches[parent] = hold
        @named_lookup[hold.uid] = parent

        pop_val = @branches.pop()
        deleted_val = @named_lookup.delete(pop_val.uid)

        balance(@branches.length() - 1) if(!@branches.empty?())

        return pop_val
    end


    def balance(current_pos)
        return if(current_pos == 0)

        parent = ((current_pos + 1) / 2).floor() - 1
        right_child = (parent + 1) * 2 
        left_child = right_child - 1
        right_child_val = @branches[right_child]
        left_child_val = @branches[left_child]

        return if(left_child >= @branches.length())

        if(right_child >= @branches.length())
            transfer_pos = left_child
        elsif(left_child_val.z < right_child_val.z)
            transfer_pos = left_child 
        elsif(left_child_val.z >= right_child_val.z)
            transfer_pos = right_child 
        end

        return if(!transfer_pos)

        if(@branches[transfer_pos].z < @branches[parent].z)
            hold = @branches[parent]
            
            @branches[parent] = @branches[transfer_pos]
            @branches[transfer_pos] = hold
            @named_lookup[@branches[parent].uid] = parent
            @named_lookup[@branches[transfer_pos].uid] = transfer_pos

#            puts "#{parent} <-> #{transfer_pos}"
        end

        balance(parent)
    end


    def printy()
        puts "------------\n"

        @branches.each do |branch|
            puts "->#{branch}\n"
        end
    end


    def values()
        return @branches 
    end


    def empty?()
        return @branches.empty?()
    end
end
