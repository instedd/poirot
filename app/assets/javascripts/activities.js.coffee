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
    currentSelection = if index < $scope.entries.length then index else -1
    if currentSelection >= 0
      $scope.entries[currentSelection].extraCss = 'selected'
    $scope.$apply()

  updateSize = ->
    flow.setHeight($('#flow-viewer').height())

  $(window).on 'resize', updateSize

  updateSize()

  activityColors = ['#0099cc', '#ff6600']

  updateFlow = (entries, full_data) ->
    lanes = {}
    acts = {}
    activities = []
    nextLane = 1
    nextActivity = 1
    events = for entry, i in entries
      do (entry) ->
        primary = (lanes[entry.source] = lanes[entry.source] or {})
        secondary = (primary[entry.pid] = primary[entry.pid] or nextLane++)
        aid = if acts[entry.activity]
          acts[entry.activity]
        else
          id = nextActivity++
          acts[entry.activity] = id
          color = entry.activityColor
          activities.push({id: id, color: color})
          id
        {
          activity: aid
          time: new Date(entry.timestamp).getTime()
          id: i
          lane: secondary
          type: 'event'
        }

    findBestLane = (aid, time) ->
      best = 0
      for event in events
        do (event) ->
          if event.activity == aid and event.time <= time
            best = event.lane
      best

    # add events for forks
    nextId = entries.length
    for activity in full_data
      do (activity) ->
        paid = activity.parent_id
        if paid and acts[paid]
          time = new Date(activity.start).getTime()
          bestLane = findBestLane(acts[paid], time)

          events.unshift
            activity: acts[paid]
            time: time
            id: nextId++
            lane: bestLane
            type: 'branch'
            child: acts[activity.id]

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

    setTimeout(() ->
      width = $('#flow-viewer').width()
      $('.details').css(left: "#{width}px")
    , 50)

  $.getJSON location.href, (data) ->
    nextColor = 0
    colorDict = {}
    entries = []
    for activity in data
      do (activity) ->
        activity_entries = for entry in activity.entries
          do (entry) ->
            color = colorDict[activity.id] or (colorDict[activity.id] = activityColors[nextColor++ % activityColors.length])
            entry.activity = activity.id
            entry.short_activity = activity.id.substr(0,8)
            entry.activityColor = color
            entry
        entries = entries.concat(activity_entries)

    entries = entries.sort (a,b) ->
      if a.timestamp > b.timestamp then 1 else -1

    $scope.entries = addCssClasses(entries)
    $scope.$apply()
    updateFlow(entries, data)
]

