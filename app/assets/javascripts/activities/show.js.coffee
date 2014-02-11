@app.controller 'ActivityController', ['$scope', ($scope) ->
  ACTIVITY_COLORS = ['#0099cc', '#ff6600', '#9933cc', '#669900']

  $scope.entries = []
  $scope.tooltip = message: '', visible: false, style: {}
  $scope.mainActivity = {}
  currentSelection = -1
  flowSVG = $('#flow-viewer')

  $scope.openActivity = (id) ->
    location.href = "/activities/#{id}"

  selectByIndex = (index) ->
    if typeof(index) == 'string' && index.length == 36
      $scope.openActivity index

    if currentSelection >= 0
      $scope.entries[currentSelection].selected = false
      flow.selectById(currentSelection)
      flow.setTargetAt(undefined)

    if index < $scope.entries.length
      rowHeight = $('.grid-viewport tbody tr:first-child').height()
      currentSelection = index
      flow.selectById(index)
      flow.setTargetAt(rowHeight * index + rowHeight/2)
    else
      currentSelection = -1

    if currentSelection >= 0
      $scope.entries[currentSelection].selected = true

  $scope.selectEntry = (index) ->
    selectByIndex index

  $scope.showTooltip = (entry, event) ->
    cell = $(event.target)
    if event.target.scrollWidth > cell.outerWidth()
      position = cell.position()
      left = position.left
      top = position.top + viewport.scrollTop()
      $scope.tooltip.message = entry.message
      $scope.tooltip.cssClass = entry.cssClass
      $scope.tooltip.style = left: left, top: top, width: cell.outerWidth()
      $scope.tooltip.visible = true

  $scope.hideTooltip = () ->
    $scope.tooltip.visible = false

  updateSize = ->
    height = $('.explorer').height()
    flowSVG.attr('height', "#{height}px")
    flow.setHeight(height)
    updateScroll()

  updateScroll = ->
    flow.setScroll viewport.scrollTop(), viewportContent.height(), viewport.height()

  updateFlow = (entries, full_data) ->
    lanes = {}
    acts = {}
    activities = []
    nextLane = 1
    nextActivity = 1

    # build events vector for flow component while calculating necessary lanes
    events = for entry, i in entries
      do (entry) ->
        psel = entry.source
        ssel = entry.pid + entry.activity
        primary = (lanes[psel] = lanes[psel] or {})
        secondary = (primary[ssel] = primary[ssel] or nextLane++)
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

    # finds the lane in which the given activity has the last event before given time
    findBestLane = (aid, time) ->
      best = 0
      for event in events
        do (event) ->
          if event.activity == aid
            if event.time <= time
              best = event.lane
            else if best == 0
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
            id: activity.id
            lane: bestLane
            type: 'branch'
            child: acts[activity.id]

    # build lanes vector for flow component
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

    # adjust events grid left position for flow component width
    setTimeout(() ->
      width = $('#flow-viewer').width()
      $('.details').css(left: "#{width}px")
    , 50)

  addCssClasses = (data) ->
    for entry in data
      do (entry) ->
        entry.cssClass = "level-#{entry.level}"
        entry

  loadData = (data) ->
    nextColor = 0
    colorDict = {}
    entries = []
    # consolidate event entries from all activities in data
    for activity in data
      do (activity) ->
        activityEntries = for entry in activity.entries
          do (entry) ->
            color = colorDict[activity.id] or \
              (colorDict[activity.id] = ACTIVITY_COLORS[nextColor++ % ACTIVITY_COLORS.length])
            entry.activity = activity.id
            entry.activityColor = color
            entry
        entries = entries.concat(activityEntries)

    # sort by timestamp
    entries = entries.sort (a,b) ->
      if a.timestamp > b.timestamp then 1 else -1

    $scope.entries = addCssClasses(entries)
    $scope.mainActivity = data[0]
    $scope.$apply()
    updateFlow(entries, data)


  # define and configure flow component
  flow = new Flow('flow-viewer')
  flow.addEventListener Event.SELECT, (evt) ->
    index = evt.info.id
    selectByIndex index
    $scope.$apply()

  viewport = $('.grid-viewport')
  viewportContent = $('.log-entries')

  viewport.on 'scroll', updateScroll
  $(window).on 'resize', updateSize

  updateSize()

  # load initial set of data
  $.ajax
    dataType: 'json',
    url: location.href,
    cache: false,
    success: loadData
]

