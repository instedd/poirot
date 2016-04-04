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

  $rootScope.serializeTimeModel = () ->
    model = $rootScope.timeModel
    serialized = {selectionKind: model.selectionKind}
    if model.selectionKind == 'span'
      serialized.span = model.span
      serialized.endingAt = model.endingAt?.toISOString()
    else
      serialized.startDate = model.range.startDate?.toISOString()
      serialized.endDate = model.range.endDate?.toISOString()
    serialized

  $rootScope.loadTimeModel = (serialized) ->
    model = $rootScope.timeModel
    if serialized.selectionKind == 'span'
      model.selectionKind = 'span'
      model.span = serialized.span
      model.endingAt = moment(serialized.endingAt) if serialized.endingAt?
    else if serialized.selectionKind == 'custom'
      model.selectionKind = 'custom'
      model.range.startDate = moment(serialized.startDate) if serialized.startDate?
      model.range.endDate = moment(serialized.endDate) if serialized.endDate?
]
