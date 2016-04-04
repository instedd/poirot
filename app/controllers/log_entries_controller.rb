class LogEntriesController < ApplicationController
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

          filter = {range: {"@timestamp" => range}}
        elsif params[:start_date].present? || params[:end_date].present?
          start_date = params[:start_date].present? ? Time.parse(params[:start_date]) : nil
          end_date = params[:end_date].present? ? Time.parse(params[:end_date]) : nil

          options[:since] = start_date if start_date.present?

          range = {}
          range[:gte] = start_date.iso8601 if start_date.present?
          range[:lte] = end_date.iso8601 if end_date.present?

          filter = {range: {"@timestamp" => range}}
        end

        if params[:ranges].present?
          all_filters = params[:ranges].values.map do |range_filter|
            filter = {range: {range_filter['name'] => {gte: range_filter['range']['from'], lt: range_filter['range']['to']}}}
          end
          all_filters << filter if filter.present?
          filter = {and: all_filters}
        end

        begin
          result = Hercule::LogEntry.query(params[:q], {from: from, size: page_size, filter: filter}, options)
          render json: { result: 'ok', entries: result.items, total: result.total }.to_json
        rescue => e
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
        main = Hercule::LogEntry.find(params[:date], params[:id])
        render json: main.as_json
      }
    end
  end

end

