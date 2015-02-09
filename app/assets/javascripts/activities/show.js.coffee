@app.controller 'ActivityController', ['$scope', ($scope) ->
  # ACTIVITY_COLORS = ['#0099cc', '#ff6600', '#9933cc', '#669900']
  ACTIVITY_COLORS = ["#0099cc", "#9933cc", "#669900", "#ff8800", "#ff3300", "#ffcc00"]
  # ACTIVITY_COLORS = ['#aee256','#68e256','#56e289','#56e2cf','#56aee2','#5668e2','#8a56e2','#cf56e2','#e256ae','#e25668','#e28956','#e2cf56']

  $scope.entries = []
  $scope.tooltip = message: '', visible: false, style: {}
  $scope.mainActivity = {}
  currentSelection = -1
  flowSVG = $('#flow-viewer')

  $scope.openActivity = (id) ->
    location.href = "/activities/#{id}"

  $scope.openLogEntry = (id) ->
    location.href = "/log_entries/#{id}"

  $scope.typeof = (obj) ->
    typeof(obj)

  $scope.toggleMetadata = () ->
    $scope.metadataVisible = !$scope.metadataVisible

  selectByIndex = (index) ->
    if typeof(index) == 'string' && index.length == 36
      $scope.openActivity index

    if currentSelection >= 0
      $scope.entries[currentSelection].selected = false
      flow.selectEvent(currentSelection)
      flow.setTargetAt(undefined)

    if index < $scope.entries.length
      rowHeight = $('.log-entries tbody tr:first-child').height()
      currentSelection = index
      flow.selectEvent($scope.entries[index].id)
      flow.setTargetAt(rowHeight * index)
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
    height = $('.log-entries').height()
    flowSVG.attr('height', "#{height}px")
    flow.setHeight(height)
    # updateScroll()

  updateScroll = ->
    flow.setScroll viewport.scrollTop(), viewportContent.height(), viewport.height()

  parseTimestamp = (ts) ->
    time = new Date(ts).getTime() * 1000
    if ((useconds_match = ts.match(/\.\d{3}(\d*)/)) && useconds_match[1].length > 0)
      time + parseInt(useconds_match[1]) * Math.pow(10, 3 - useconds_match[1].length)
    else
      time

  cssClassForEntry = (entry) ->
    if entry.tags.indexOf("sql") >= 0
      "level-sql"
    else
      "level-#{entry.level}"

  loadData = (data) ->
    nextColor = 0
    entries = []
    activities = {}
    links = {}
    incomplete = false

    # consolidate event entries from all activities in data
    for activity in data
      activities[activity.id] = {id: activity.id, entity:activity}
      activityStartTime = parseTimestamp(activity.start)

      entries.push
        activity: activity.id
        lane: 0
        cssClass: "level-info"
        id: "#{activity.id}-start"
        time: activityStartTime
        timestamp: activity.start
        source: activity.source
        type: "start"
        message: "Start activity: '#{activity.description}'"
        entity: activity
        sync: !activity.async
      if activity.stop
        entries.push
          activity: activity.id
          lane: 0
          cssClass: "level-info"
          id: "#{activity.id}-end"
          time: parseTimestamp(activity.stop)
          timestamp: activity.stop
          source: activity.source
          type: "end"
          message: "End activity: '#{activity.description}'"
          entity: activity
      else
        incomplete = true

      for entry in activity.entries
        entryTime = parseTimestamp(entry.timestamp)
        if entryTime < activityStartTime
          entryTime = activityStartTime
        entries.push
          lane: 0
          cssClass: cssClassForEntry(entry)
          activity: activity.id
          id: entry.id
          time: entryTime
          type: "event"
          message: entry.message
          timestamp: entry.timestamp
          source: entry.source
          entity: entry
        if entry.fields && link_id = entry.fields["link_id"]
          links[link_id] = entry.id

    stableSort = (array, sortFun) ->
      array
        .map((e, i) -> [i, e])
        .sort((x, y) -> sortFun(x[1], y[1]) || (x[0] - y[0]))
        .map((e) -> e[1])

    # sort by time
    entries = stableSort(entries, (a, b) -> a.time - b.time)

    lanes = {}
    laneCount = 0
    activityLanes = {}

    for entry in entries
      switch entry.type
        when "start"
          parentActivity = activities[entry.entity.parent_id]
          loop
            color = ACTIVITY_COLORS[nextColor++ % ACTIVITY_COLORS.length]
            break if parentActivity == undefined || color != parentActivity.color
          activities[entry.entity.id].color = color
          sourceLanes = lanes[entry.source] ||= []
          activityLane = null
          for lane in sourceLanes
            if !lane.inUse && lane != activityLanes[parentActivity.id]
              activityLane = lane
              break
          unless activityLane
            activityLane = (id: laneCount++)
            sourceLanes.push activityLane
          activityLane.inUse = true
          activityLanes[entry.activity] = activityLane
          entry.lane = activityLane.id
          if parentActivity
            if entry.entity.fields && link_id = entry.entity.fields["link_id"]
              entry.fromNode = links[link_id]
            else
              entry.fromActivity = parentActivity.id

        when "end"
          activityLane = activityLanes[entry.activity]
          entry.lane = activityLane.id
          activityLane.inUse = false
          parentActivity = activities[entry.entity.parent_id]
          entry.toActivity = parentActivity.id if parentActivity && !entry.entity.async
        else
          activityLane = activityLanes[entry.activity]
          entry.lane = activityLane.id
      entry.activityColor = activities[entry.activity].color


    $scope.entries = entries
    $scope.activities = activities
    $scope.mainActivity = data[0]
    $scope.metadataActivity = data[0]
    $scope.metadataVisible = true
    $scope.incompleteActivities = incomplete
    $scope.$apply()

    flowData =
      lanes: [[0 .. laneCount - 1]]
      activities: (a for _, a of activities)
      events: entries
    flow.slotHeight(36);
    flow.data(flowData)

    # adjust events grid left position for flow component width
    setTimeout(() ->
      width = $('#flow-viewer').width()
      # $('.details').css(left: "#{width}px")
      $('.flow').css(width: "#{width}px")
      updateSize()
    , 50)


  # define and configure flow component
  flow = new Flow('flow-viewer')
  flow.addEventListener Event.SELECT, (evt) ->
    flow.selectActivity(evt.info.activity)
    index = evt.info.slot
    selectByIndex index
    $scope.metadataActivity = $scope.activities[evt.info.activity].entity
    $scope.$apply()

  viewport = $('.grid-viewport')
  viewportContent = $('.log-entries tbody')

  # viewport.on 'scroll', updateScroll
  $(window).on 'resize', updateSize

  updateSize()

  # load initial set of data
  $.ajax
    dataType: 'json',
    url: location.href,
    cache: false,
    success: loadData
]

