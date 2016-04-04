@app = angular.module('poirot', ['daterangepicker'])

@app.run ['$rootScope', ($rootScope) ->
  $rootScope.timeModel =
    selectionKind: 'span'
    range: {startDate: null, endDate: null}
    endingAt: null
    span: 3

  setTimeFilter = () ->
    if $rootScope.timeModel.selectionKind == 'span'
      $rootScope.timeFilter = {since: $rootScope.timeModel.span, ending_at: $rootScope.timeModel.endingAt?.toISOString()}
    else
      range = $rootScope.timeModel.range
      $rootScope.timeFilter = {start_date: range.startDate?.toISOString(), end_date: range.endDate?.toISOString()}

  $rootScope.$watch 'timeModel', setTimeFilter, true

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

  $rootScope.logEntryUrl = (logentry) ->
    date = new Date(logentry.timestamp)
    "/log_entries/#{date.toJSON().substring(0, 10)}/#{logentry.id}"
]
