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

  parseTimestamp = (ts) ->
    time = new Date(ts).getTime() * 1000
    if ((useconds_match = ts.match(/\.\d{3}(\d*)/)) && useconds_match[1].length > 0)
      time + parseInt(useconds_match[1]) * Math.pow(10, 3 - useconds_match[1].length)
    else
      time

  loadData = (data) ->
    nextColor = 0
    entries = []
    activities = {}

    # consolidate event entries from all activities in data
    for activity in data
      activities[activity.id] = {id: activity.id}

      entries.push
        activity: activity.id
        lane: 0
        cssClass: "level-info"
        id: "#{activity.id}-start"
        time: parseTimestamp(activity.start)
        timestamp: activity.start
        source: activity.source
        type: "start"
        message: "Start activity: '#{activity.description}'"
        entity: activity
        fromActivity: activity.parent_id
        sync: true
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
        toActivity: activity.parent_id
      for entry in activity.entries
        entries.push
          lane: 0
          cssClass: "level-#{entry.level}"
          activity: activity.id
          id: entry.id
          time: parseTimestamp(entry.timestamp)
          type: "event"
          message: entry.message
          timestamp: entry.timestamp
          source: entry.source
          entity: entry

    # sort by time
    entries = entries.sort (a, b) -> a.time - b.time

    lanes = {}
    laneCount = 0
    activityLanes = {}

    for entry in entries
      switch entry.type
        when "start"
          loop
            color = ACTIVITY_COLORS[nextColor++ % ACTIVITY_COLORS.length]
            break if entry.entity.parent_id == null || color != activities[entry.entity.parent_id].color
          activities[entry.entity.id].color = color
          sourceLanes = lanes[entry.source] ||= []
          activityLane = null
          for lane in sourceLanes
            if !lane.inUse
              activityLane = lane
              break
          unless activityLane
            activityLane = (id: laneCount++)
            sourceLanes.push activityLane
          activityLane.inUse = true
          activityLanes[entry.activity] = activityLane
          entry.lane = activityLane.id

        when "end"
          activityLane = activityLanes[entry.activity]
          entry.lane = activityLane.id
          activityLane.inUse = false
        else
          activityLane = activityLanes[entry.activity]
          entry.lane = activityLane.id
      entry.activityColor = activities[entry.activity].color


    console.log(entries)
    $scope.entries = entries
    $scope.mainActivity = data[0]
    $scope.$apply()

    flowData =
      lanes: [[0, 1, 2, 3]]
      activities: (a for _, a of activities)
      events: entries
    console.log(flowData)
    flow.slotHeight(36);
    flow.data(flowData)

    # adjust events grid left position for flow component width
    setTimeout(() ->
      width = $('#flow-viewer').width()
      $('.details').css(left: "#{width}px")
    , 50)


  # define and configure flow component
  flow = new Flow('flow-viewer')
  flow.addEventListener Event.SELECT, (evt) ->
    flow.selectActivity(evt.info.activity)
    index = evt.info.id
    selectByIndex index
    $scope.$apply()

  viewport = $('.grid-viewport')
  viewportContent = $('.log-entries tbody')

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

