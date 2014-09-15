angular.module \main
  ..controller \event, <[$scope $http context]> ++ ($scope, $http, context) ->
    $scope.set = {}
    if context.event =>
      $scope.event = context.event
      $scope.set <<< context.event
    $scope.need-fix = false
    $scope.fix = (name) -> 
      if $scope.need-fix and $scope.newsetform.{}[name].$invalid => "has-error" else ""
    $scope.uploading = false
    $scope.delete = ->
      $http do
        url: "/s/set/#{$scope.event.event}"
        method: \DELETE
      .success (d) -> console.log d
      .error (e) -> console.log e
    $scope.submit = ->
      if !(/^[a-zA-Z0-9]{3,11}$/.exec($scope.set.event)) =>
        $scope.newsetform.event.$setValidity "illegal", false
      $scope.need-fix = $scope.newsetform.$invalid
      if $scope.need-fix => return
      $scope.uploading = true
      fd = new FormData!
      image = $(\#setimage).0
      <[name desc event]>.map -> fd.append it, $scope.set[it]
      fd.append \image, image.files.0
      $http do
        url: if $scope.event => "/s/set/#{$scope.event.event}" else \/s/set/new/
        method: if $scope.event => \PUT else \POST
        data: fd
        transformRequest: angular.identity
        headers: "Content-Type": undefined
      .success (d) -> 
        window.location.href = "//#{$scope.set.event}.g0v.photos/"
      .error (e) -> 
        $scope.uploading = false
        console.error e

    $(\#event-choose-org)select2!
