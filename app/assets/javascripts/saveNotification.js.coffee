@app.controller 'SaveNotificationController', ['$scope', ($scope) ->
  originalSaveMessage = "Save notification"

  $scope.saveMessage = originalSaveMessage

  $scope.save = ->
    query = $scope.lastQuery
    email = $scope.email
    subject = $scope.subject

    if $.trim(email).length == 0
      $scope.error = "Email is required"
      return

    if $.trim(subject).length == 0
      $scope.error = "Subject is required"
      return

    $scope.error = null
    $scope.saveMessage = "Saving..."

    post_data = {query: query, email: email, subject: subject}
    $.post "/notifications", post_data, (data) ->
      $scope.saveMessage = "Saved!"
      $scope.$apply()

      setTimeout (->
        $('#save-notification-modal').modal('hide')
        $scope.saveMessage = originalSaveMessage
        $scope.$apply()
        ), 500
]

