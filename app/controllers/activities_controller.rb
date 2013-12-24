class ActivitiesController < ApplicationController
  def index
    activities = Activity.all
    lanes = Activity.assign_lanes(activities)

    first_time = activities.map(&:start).reject(&:nil?).min
    last_time = activities.map(&:stop).reject(&:nil?).max

    rlanes = lanes.each_with_index.map do |lane, i|
      { id: i, label: "Lane #{i}" }
    end
    ritems = lanes.each_with_index.inject([]) do |partial, lane_with_index|
      lane = lane_with_index[0]
      i = lane_with_index[1]
      lane_items = lane.map do |activity|
        {
          class: "past",
          description: "Some activity",
          id: activity.id,
          start: (activity.start || first_time).strftime("%Q"),
          end: (activity.stop || last_time).strftime("%Q"),
          lane: i
        }
      end
      partial.concat lane_items
    end

    render json: { items: ritems, lanes: rlanes }
  end

  def show
    respond_to do |format|
      format.html
      format.json {
        activity = Activity.find(params[:id])
        activity.find_events

        data = {
          id: params[:id],
          start: activity.start,
          stop: activity.stop,
          events: activity.events,
          entries: activity.entries.reject { |e| e['module'] == 'activity' }
        }
        render json: data
      }
    end
  end
end
