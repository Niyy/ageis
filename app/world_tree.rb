class World_Tree
    attr_reader :branches


    def initialize(branches: {})
        @branches = []
        @named_lookup = {}

        branches.values().each() do |branch|
            push(branch)
        end
    end


    def [](key)
        return @branches[@named_lookup[key]] 
    end


    def []=(key, value)
        if(@named_lookup.has_key?(key))
            @branches[@named_lookup[key]] = value
            balance(@named_lookup[key])
        else
            push(value)
        end
    end


    def <<(branch)
        if(@named_lookup.has_key?(branch.uid))
            @branches[@named_lookup[branch.uid]] = branch 
            balance(@named_lookup[branch.uid])
        else
            push(branch)
        end
    end


    def push(branch)
        @branches << branch
        @named_lookup[branch.uid] = @branches.length() - 1

        balance(@branches.length() - 1)
    end


    def delete(branch)
        parent = @named_lookup[branch.uid]
        @named_lookup.delete(branch.uid)
        
        trade = @branches.length() - 1
        hold = @branches[trade]
        @branches[trade] = @branches[parent]
        @branches[parent] = hold

        pop_val = @branches.pop()

        balance(@branches.length() - 1)

        return pop_val
    end


    def balance(current_pos)
        return if(current_pos == 0)

        parent = ((current_pos + 1) / 2).floor() - 1
        right_child = (parent + 1) * 2 
        left_child = right_child - 1
        right_child_val = @branches[right_child]
        left_child_val = @branches[left_child]

        puts "parent: #{parent}"
        puts "left_child: #{left_child}"
        puts "right_child: #{right_child}"
        puts "length: #{@branches.length}"

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

            puts "#{parent} <-> #{transfer_pos}"
        end

        balance(parent)
    end
end
