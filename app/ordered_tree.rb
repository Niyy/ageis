class Ordered_Tree 
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
        @branches[@named_lookup[key]] = value
    end


    def <<(branch)
        if(@named_lookup.has_key?(branch.uid))
            delete(branch)
        end

        insert(branch)
    end


    def insert(branch)
        where = @branches.bsearch_index do |element| 
            branch.z >= element.z 
        end
       
        if(!where)
            @branches << branch 
        else
            @branches.insert(where, branch)
            @named_lookup[branch.uid] = where
        end
    end


    def delete(branch)
        return nil if(!@named_lookup.has_key?(branch.uid))

        if(
            @named_lookup[branch.uid] >= @branches.length
        )
            return @named_lookup.delete(branch.uid)
        end

        where = @named_lookup[branch.uid]

        pop_val = @branches.delete_at(where)
        deleted_val = @named_lookup.delete(pop_val.uid)

        return pop_val
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
