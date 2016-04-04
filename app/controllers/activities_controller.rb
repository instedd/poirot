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

        begin
          result = Hercule::Activity.query(params[:q], {from: from, size: page_size, filter: filter}, options).with_levels
          render json: { result: 'ok', activities: result.items, total: result.total }.to_json
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
          response = JSON.parse(e.message[6..-1])
          render json: { result: 'error', body: response['error'] }.to_json
        end
      }
    end
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

