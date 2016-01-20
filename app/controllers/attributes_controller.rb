class AttributesController < ApplicationController
  def index
    mappings = Hercule::Backend.client.indices.get_mapping(
      index: Hercule::Backend.indices_since(Time.now - 1.month),
      type: 'activity', ignore_unavailable: true, allow_no_indices: true)
    attributes = {"@source" => {name: "@source", filterAttr: "@source", displayName: "Source"}}

    mappings.reverse_each do |index, mapping|
      begin
        properties = mapping["mappings"]["activity"]["properties"]["@fields"]["properties"]
        iterate_properties("@fields", "", properties) do |name, full_name, prop|
          next if name.include?("/") # HACK: nested properties will be enabled later
          full_name = full_name + ".raw" if prop["type"] == "string"
          next if attributes.has_key?(full_name)

          attributes[full_name] = {name: full_name, displayName: name, type: prop["type"]}
        end
      rescue
      end
    end

    render json: attributes.values
  end

  def values
    start_date = Time.now.utc - params[:since].to_i.hours
    search = {
      size: 0,
      query: {
        range: { "@start" => { gte: start_date.iso8601 } }
      },
      aggs: {
        attr_values: {
          terms: {
            field: params[:id]
          }
        }
      }
    }

    if params[:q].present?
      search[:query] = Hercule::Activity.build_query(params[:q])
    end

    result = Hercule::Backend.search(search, type: 'activity', since: start_date)
    render json: result['aggregations']['attr_values']['buckets']
  end

  def histogram
    stats = Hercule::Backend.search({size: 0, aggs: {attr_stats: {stats: {field: params[:id]}}}}, type: 'activity')
    min = stats['aggregations']['attr_stats']['min']
    max = stats['aggregations']['attr_stats']['max']

    interval = [((max - min) / 100).floor, 1].max

    result = Hercule::Backend.search({size: 0, aggs: {histogram: {histogram: {field: params[:id], interval: interval}}}}, type: 'activity')
    render json: {min: min, max: max, interval: interval, histogram: result['aggregations']['histogram']['buckets']}
  end

  private

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
end
