@app.controller 'ActivityController', ['$scope', ($scope) ->
  $scope.entries = []
  activity = null

  addCssClasses = (data) ->
    addCssEntry(entry) for entry in data

  addCssEntry = (entry) ->
    entry.cssClass = "level-#{entry.level}"
    entry

  flow = new Flow('flow-viewer')

  currentSelection = -1
  flow.clickHandler = (index) ->
    if currentSelection >= 0
      $scope.entries[currentSelection].extraCss = ''
    currentSelection = index
    if currentSelection >= 0
      $scope.entries[currentSelection].extraCss = 'selected'
    $scope.$apply()

  updateSize = ->
    flow.setHeight($('#flow-viewer').height())

  $(window).on 'resize', updateSize

  updateSize()

  updateFlow = (entries) ->
    lanes = {}
    activities = [{id: 1, color: '#0099cc'}]
    nextLane = 1
    events = for entry, i in entries
      do (entry) ->
        primary = (lanes[entry.source] = lanes[entry.source] or {})
        secondary = (primary[entry.pid] = primary[entry.pid] or nextLane++)
        {
          activity: 1
          time: new Date(entry.timestamp).getTime()
          id: i
          lane: secondary
          type: 'event'
        }

    lanes = for source, pids of lanes
      do (source, pids) ->
        for pid, lane of pids
          do (pid, lane) ->
            lane

    data =
      lanes: lanes,
      activities: activities,
      events: events
    flow.setData(data)

  $.getJSON location.href, (data) ->
    activity = data
    data.entries = data.entries.sort (a,b) ->
      if a.timestamp > b.timestamp then 1 else -1

    $scope.entries = addCssClasses(data.entries)
    $scope.$apply()
    updateFlow(data.entries)
]

