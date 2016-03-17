class AttributesController < ApplicationController
  def index
    attributes = Attribute.all_for(params[:type])

    render json: attributes.values
  end

  def values
    start_date = Time.now.utc - params[:since].to_i.hours
    ts_property = params[:type] == 'activity' ? "@start" : "@timestamp"
    search = {
      size: 0,
      query: {
        range: { ts_property => { gte: start_date.iso8601 } }
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

    result = Hercule::Backend.search(search, type: params[:type], since: start_date)
    render json: result['aggregations']['attr_values']['buckets']
  end

  def histogram
    stats = Hercule::Backend.search({size: 0, aggs: {attr_stats: {stats: {field: params[:id]}}}}, type: params[:type])
    min = stats['aggregations']['attr_stats']['min']
    max = stats['aggregations']['attr_stats']['max']

    interval = [((max - min) / 100).floor, 1].max

    result = Hercule::Backend.search({size: 0, aggs: {histogram: {histogram: {field: params[:id], interval: interval}}}}, type: params[:type])
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
