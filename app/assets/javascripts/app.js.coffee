@app = angular.module('poirot', [])

@app.run ['$rootScope', ($rootScope) ->
  $rootScope.selectedInterval = 1

  TIME_INTERVALS = [
    {name:"1 hour", hours: 1},
    {name:"3 hours", hours: 3},
    {name:"6 hours", hours: 6},
    {name:"12 hours", hours: 12},
    {name:"1 day", hours: 24},
    {name:"3 days", hours: 72},
    {name:"1 week", hours: 168},
    {name:"3 weeks", hours: 504},
    {name:"ever", hours: null}
  ]

  $rootScope.intervals = ->
    TIME_INTERVALS

  $rootScope.selectedIntervalName = ->
    TIME_INTERVALS[$rootScope.selectedInterval].name

  $rootScope.selectedIntervalValue = ->
    TIME_INTERVALS[$rootScope.selectedInterval].hours

  $rootScope.selectInterval = (i) ->
    $rootScope.selectedInterval = i

  $rootScope.formatTimestamp = (ts) ->
    date = new Date(ts)
    h = date.getUTCHours()
    m = date.getUTCMinutes()
    s = date.getUTCSeconds()
    ms = date.getUTCMilliseconds()

    pad = (num, size) ->
      str = num + ""
      while str.length < size
        str = "0" + str
      str

    "#{date.toDateString()}, #{h}:#{pad m, 2}:#{pad s, 2}.#{pad ms, 3} UTC"

  buildActivityUrl = (date, id) ->
    start = new Date(date)
    "/activities/#{start.toJSON().substring(0, 10)}/#{id}"

  $rootScope.activityUrl = (activity) ->
    buildActivityUrl(activity.start, activity.id)

  $rootScope.parentActivityUrl = (activity) ->
    buildActivityUrl(activity.start, activity.parent_id)

  $rootScope.logEntryActivityUrl = (logentry, activityId) ->
    buildActivityUrl(logentry.timestamp, logentry.activity)
]
