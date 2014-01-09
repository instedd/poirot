class ActivitiesController < ApplicationController
  def show
    respond_to do |format|
      format.html
      format.json {
        activity = Activity.find(params[:id])

        data = {
          id: params[:id],
          entries: activity.entries
        }
        render json: data
      }
    end
  end
end
