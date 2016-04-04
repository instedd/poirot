@app.directive 'time', ['$http', ($http) ->
  restrict: 'E'
  templateUrl: 'time.html'
  scope:
    model: '='

  link: (scope) ->
    scope.spans = [
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

    scope.selectedSpanIndex = _.findIndex scope.spans, (span) ->
      span.hours == scope.model.span

    scope.selectSpan = (index) ->
      scope.selectedSpanIndex = index
      scope.model.span = scope.spans[index].hours

    scope.selectedSpanName = () ->
      scope.spans[scope.selectedSpanIndex].name

    scope.selectEndingAtNow = () ->
      scope.model.endingAt = null

    scope.selectEndingAtDate = () ->
      scope.model.endingAt = moment() unless scope.model.endingAt?

    scope.moveEndingAtBack = () ->
      scope.model.endingAt = moment(scope.model.endingAt.subtract(30, 'minutes'))

    scope.moveEndingAtForward = () ->
      now = moment()
      forward = moment(scope.model.endingAt.add(30, 'minutes'))
      scope.model.endingAt = if forward.isAfter(now) then now else forward
]
