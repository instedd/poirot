@app.controller 'ActivityController', ['$scope', ($scope) ->
  $scope.entries = []
  activity = null

  addCssClasses = (data) ->
    addCssEntry(entry) for entry in data

  addCssEntry = (entry) ->
    entry.cssClass = "level-#{entry.level}"
    entry

  flow = new Flow('flow-viewer')

  data =
    lanes: [[3,0],[2,1]]
    activities: [{id:1, color:"#0099cc"},{id:2, color:"#ff6600"}]
    events: [{activity:1,time:0,id:1,lane:0},{activity:1,time:3,id:2,lane:0},{activity:1,time:4,id:3,lane:0},{activity:1,time:5,id:4,lane:2},{activity:2,time:0,id:5,lane:0},{activity:2,time:1,id:6,lane:2},{activity:2,time:2,id:7,lane:1},{activity:2,time:3,id:8,lane:0}]

  flow.setData(data)

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
          time: i
          id: i
          lane: secondary
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

