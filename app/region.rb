class Region
    attr_gtk


    def initialize(factions: {})
        @total_contents = World_Tree.new()
        @nonstatic_entities = {}
        @tiles = {pawn: nil, ground: nil}
        @tasks = {}
        @factions = factions
        @regionals = {
            wave: {},
            factions: {},
            faction_pawn_count: {},
            area_owner: {faction: '-1'.to_sym},
            area_flag: nil,
            area_dim: 64
        }
    end


    def add_tile(loc, tile)
        @tiles[loc] = tile 
    end

    
    def add_faction(faction)
        @factions[faction.to_sym] = {
            owned_entities: {}
        }
    end


    def [](key)
        return @total_contents[key]
    end


    def []=(key, entity)
        @total_contents[key] = entity 
        @nonstatic_entities[key] = entity if(entity.type == :actor)

        if(@factions.has_key?(entity.faction))
            @factions[entity.faction].owned_entities[entity.uid] = entity 
        end
    end


    def delete(entity)
        @factions[value.faction].owned_entities.delete(entity.uid)
        @nonstatic_entities.delete(entity.uid)
        @total_contents.delete(entity.uid)
    end


    def update()
        interacted_entities = []
        puts @nonstatic_entities 

        @nonstatic_entities.delete_if do |key, entity|
            if(entity.supply <= 0)
                puts "pawn killed #{entity.uid}"

                true
            else
                old_pos = {x: entity.x, y: entity.y}
                interacted = entity.update(
                    args.state.tick_count, 
                    @factions[entity.faction], 
                    @tiles, 
                    @total_contents, 
                    @regionals, 
                    audio,
                    nil
                )

                interacted_entities << interacted

                update_tile(entity, old_pos, entity.type)

                false
            end
        end

        interacted_entities.each() do |event|
            entity = event[0]

            if(event[1] == :fight && entity.supply <= 0)
                delete(entity)
            end
        end
    end


    def destory_entity(entity)
        @tiles[[entity.x, entity.y]][entity.type] = nil
        @factions[pawn.faction].owned_entities.delete(pawn.uid)
    end


    def update_tile(obj, old_pos, spot)
        return if(old_pos.x == obj.x && old_pos.y == obj.y)

        @tiles[[old_pos.x, old_pos.y]][spot] = nil
        @tiles[[obj.x, obj.y]][spot] = obj
    end


    def output()
        return @total_contents.branches
    end
end
