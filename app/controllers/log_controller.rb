class LogController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json {
        from = params[:from] || 0
        page_size = 20
        begin
          result = LogEntry.query(params[:q], from: from, size: page_size)
          render json: { result: 'ok', entries: result.items, total: result.total }.to_json
        rescue => e
          response = JSON.parse(e.message[6..-1])
          render json: { result: 'error', body: response['error'] }.to_json
        end
      }
    end
  end
end

