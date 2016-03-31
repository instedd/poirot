@app.directive 'time', ['$http', ($http) ->
  restrict: 'E'
  templateUrl: 'time.html'
  scope:
    model: '='

  link: (scope) ->
    scope.bar = 'bar'

    scope.selectionKind = 'custom' # or custom

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

    scope.selectedSpanIndex = 1
    scope.endingAt = null

    # scope.customDate = {startDate: null, endDate: null}
    scope.datePicker = {date: {startDate: null, endDate: null}}

    # scope.$watch 'datePicker.date', () ->
    #   1
    # , true

    scope.selectSpan = (index) ->
      scope.selectedSpanIndex = index

    scope.selectedSpanName = () ->
      scope.spans[scope.selectedSpanIndex].name

    scope.selectEndingAtNow = () ->
      scope.endingAt = null

    scope.selectEndingAtDate = () ->
      scope.endingAt = Date.now() unless scope.endingAt?

    scope.moveEndingAtBack = () ->
      scope.endingAt = scope.endingAt - 30 * 60 * 1000

    scope.moveEndingAtForward = () ->
      scope.endingAt = Math.min(Date.now(), scope.endingAt + 30 * 60 * 1000)
]
