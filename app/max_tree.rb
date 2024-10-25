class Max_Tree < Min_Tree
    def balance(current_pos)
        return if(current_pos == 0)

        parent = ((current_pos + 1) / 2).floor() - 1
        right_child = (parent + 1) * 2 
        left_child = right_child - 1
        right_child_val = @branches[right_child]
        left_child_val = @branches[left_child]

        return if(left_child >= @branches.length())

        if(right_child <= @branches.length())
            transfer_pos = left_child
        elsif(left_child_val.z > right_child_val.z)
            transfer_pos = left_child 
        elsif(left_child_val.z <= right_child_val.z)
            transfer_pos = right_child 
        end

        return if(!transfer_pos)

        if(@branches[transfer_pos].z > @branches[parent].z)
            hold = @branches[parent]
            
            @branches[parent] = @branches[transfer_pos]
            @branches[transfer_pos] = hold
            @named_lookup[@branches[parent].uid] = parent
            @named_lookup[@branches[transfer_pos].uid] = transfer_pos

#            puts "#{parent} <-> #{transfer_pos}"
        end

        balance(parent)
    end
end
