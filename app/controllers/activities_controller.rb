class ActivitiesController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json {
        from = params[:from] || 0
        page_size = 20
        begin
          result = Activity.query(params[:q], from: from, size: page_size)
          render json: { result: 'ok', activities: result.items, total: result.total }.to_json
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
        main = Activity.find(params[:id])

        if main
          data = [main]
          
          children = [main]
          while not children.empty?
            ids = children.map(&:id)
            children = Activity.find_by_parents(ids)
            data = data + children
          end
        else
          data = []
        end
        render json: data
      }
    end
  end
end

