class Attribute

  @attributes_cache = {}

  class << self

    def all_for(type)
      now = Time.now.utc
      yesterday = now - 1.day
      since = now - save_indices_for

      indices = Hercule::Backend.indices_span(since, yesterday)
      today_index = Hercule::Backend.index_by_date(now)

      @attributes_cache[type] = {} unless @attributes_cache.has_key?(type)
      cached_indices = @attributes_cache[type].keys

      indices_to_delete = cached_indices - indices
      needs_cache = indices - cached_indices

      indices_to_delete.each{|i| @attributes_cache[type].delete(i)}

      indices_to_query = (needs_cache + [today_index]).join(',')

      mappings = Hercule::Backend.client.indices.get_mapping(
        index: indices_to_query,
        type: type, ignore_unavailable: true, allow_no_indices: true
      )

      needs_cache.each do |index|
        @attributes_cache[type][index] = {}

        index_mapping = mappings[index]

        if index_mapping.present?
          attributes_from_mapping(type, index_mapping) do |full_name, name, prop_type|
            @attributes_cache[type][index][full_name] = {name: full_name, displayName: name, type: prop_type}
          end
        end
      end

      # Build attributes list
      attributes = defaults(type)

      if mappings[today_index].present?
        attributes_from_mapping(type, mappings[today_index]) do |full_name, name, prop_type|
          attributes[full_name] = {name: full_name, displayName: name, type: prop_type}
        end
      end

      @attributes_cache[type].keys.sort.reverse.each do |index|
        attributes.reverse_merge @attributes_cache[type][index]
      end

      attributes
    end

    private

    def defaults(type)
      attributes = {"@source" => {name: "@source", filterAttr: "@source", displayName: "Source"}}

      if type == 'logentry'
        attributes["@level"] = {
          name: "@level",
          filterAttr: "@level",
          displayName: "Level"
        }
      end

      attributes
    end

    def attributes_from_mapping(type, mapping, &block)
      begin
        properties = mapping["mappings"][type]["properties"]["@fields"]["properties"]
        iterate_properties("@fields", "", properties) do |name, full_name, prop|
          next if name.include?("/") # HACK: nested properties will be enabled later
          full_name = full_name + ".raw" if prop["type"] == "string"

          yield full_name, name, prop["type"]
        end
      rescue => e
        raise e
      end
    end

    def iterate_properties(prefix, display_prefix, mapping, &block)
      mapping.each do |name, prop|
        prop_name = "#{prefix}.#{name}"
        if %w(string long double).include?(prop["type"])
          yield "#{display_prefix}#{name}", prop_name, prop
        elsif subproperties = prop["properties"]
          iterate_properties(prop_name, "#{display_prefix}#{name}/", subproperties, &block)
        end
      end
    end

    def save_indices_for
      Settings.save_indices_for.days
    end

  end

end
