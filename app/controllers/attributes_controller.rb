class AttributesController < ApplicationController
  def index
    attributes = Attribute.all_for(params[:type])

    render json: attributes.values
  end

  def values
    ts_property = params[:type] == 'activity' ? "@start" : "@timestamp"
    options = {type: params[:type]}
    query = {match_all: {}}

    if params[:since].present?
      ending_at = params[:ending_at].present? ? Time.parse(params[:ending_at]) : Time.now.utc
      start_date = ending_at - params[:since].to_i.hours

      options[:since] = start_date

      range = {gte: start_date.iso8601}
      range[:lte] = ending_at.iso8601 if params[:ending_at].present?

      query = {range: {ts_property => range}}
    elsif params[:start_date].present? || params[:end_date].present?
      start_date = params[:start_date].present? ? Time.parse(params[:start_date]) : nil
      end_date = params[:end_date].present? ? Time.parse(params[:end_date]) : nil

      options[:since] = start_date if start_date.present?

      range = {}
      range[:gte] = start_date.iso8601 if start_date.present?
      range[:lte] = end_date.iso8601 if end_date.present?

      query = {range: {ts_property => range}}
    end

    start_date = Time.now.utc - params[:since].to_i.hours

    search = {
      size: 0,
      query: query,
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

    result = Hercule::Backend.search(search, options)
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
