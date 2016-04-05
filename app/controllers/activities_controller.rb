class ActivitiesController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json {
        from = params[:from] || 0
        page_size = 20
        filter = {}
        options = {}

        if params[:since].present?
          ending_at = params[:ending_at].present? ? Time.parse(params[:ending_at]) : Time.now.utc
          start_date = ending_at - params[:since].to_i.hours

          options[:since] = start_date

          range = {gte: start_date.iso8601}
          range[:lte] = ending_at.iso8601 if params[:ending_at].present?

          filter = {range: {"@start" => range}}
        elsif params[:start_date].present? || params[:end_date].present?
          start_date = params[:start_date].present? ? Time.parse(params[:start_date]) : nil
          end_date = params[:end_date].present? ? Time.parse(params[:end_date]) : nil

          options[:since] = start_date if start_date.present?

          range = {}
          range[:gte] = start_date.iso8601 if start_date.present?
          range[:lte] = end_date.iso8601 if end_date.present?

          filter = {range: {"@start" => range}}
        end

        histogram_aggs = bars_aggregation_for_range(filter, start_date)
        page_query = {from: from, size: page_size, filter: filter}

        begin
          result = Hercule::Activity.query(params[:q], page_query, options).with_levels
          bars_result = Hercule::Activity.query(params[:q], histogram_aggs, options).with_levels
          buckets = bars_result.response['aggregations']['filtered_activities_by_period']['activities_by_period']['buckets']
          bars_result = buckets.map {|b| {timestamp: b['key'], count: b['doc_count']}}
          render json: { result: 'ok', activities: result.items, bars: bars_result, total: result.total}.to_json
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
          response = JSON.parse(e.message[6..-1])
          render json: { result: 'error', body: response['error'] }.to_json
        end
      }
    end
  end

  def bars_aggregation_for_range(filter, from, to = Time.now)
    from ||= Time.now - Settings.save_indices_for.days
    number_of_bars = 90
    interval = (to.tv_sec - from.tv_sec)/number_of_bars
    {
      aggregations: {
        filtered_activities_by_period: {
            filter: filter,
            aggs: {
              activities_by_period: {
                date_histogram: {
                     field: "@start",
                  interval: "#{interval}s"
                }
              }
            }
        }
      }
    }
  end

  def show
    respond_to do |format|
      format.html
      format.json {
        main = Hercule::Activity.find(params[:date], params[:id])

        if main
          data = [main]

          children = [main]
          while not children.empty?
            ids = children.map(&:id)
            children = Hercule::Activity.find_by_parents(params[:date], ids)
            data = data + children
          end
        else
          data = []
        end

        Hercule::Activity.bulk_load_entries(data)
        render json: data.as_json(with_entries: true)
      }
    end
  end
end

