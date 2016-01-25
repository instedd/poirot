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
          start_date = Time.now.utc - params[:since].to_i.hours
          options[:since] = start_date
          filter = {range: {"@timestamp" => {gte: start_date.iso8601}}}
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
        main = Hercule::LogEntry.find(params[:id])
        render json: main.as_json
      }
    end
  end

end

