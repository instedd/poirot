class ActivitiesController < ApplicationController
  def show
    respond_to do |format|
      format.html
      format.json {
        activity = Activity.find(params[:id])

        if activity
          main = map_activity(activity)
          data = [main]
          
          q = [main]
          while not q.empty?
            ids = q.map do |hash| hash[:id] end
            l = Activity.find_by_parents(ids)
            q = l.map do |activity| map_activity(activity) end
            data = data + q
          end
        else
          data = []
        end
        render json: data
      }
    end
  end

  private

  def map_activity(activity)
    {
      id: activity.id,
      start: activity.start,
      stop: activity.stop,
      parent_id: activity.parent_id,
      source: activity.source,
      pid: activity.pid,
      entries: activity.entries
    }
  end
end
