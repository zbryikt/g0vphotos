angular.module \main
  ..controller \event, <[$scope $http context global]> ++ ($scope, $http, context, global) ->
    $scope.set = {}
    if context.event =>
      $scope.oid = context.event.oid
      $scope.set <<< context.event
    console.log context
    $scope.need-fix = false
    $scope.fix = (name) -> 
      if $scope.need-fix and $scope.newsetform.{}[name].$invalid => "has-error" else ""
    $scope.uploading = false
    $scope.delete = ->
      $http do
        url: "/s/event/#{$scope.oid}"
        method: \DELETE
      .success (d) -> console.log d
      .error (e) -> console.log e
    $scope.submit = ->
      if !(/^[a-zA-Z0-9]{3,11}$/.exec($scope.set.oid)) =>
        $scope.newsetform.oid.$setValidity "illegal", false
      $scope.need-fix = $scope.newsetform.$invalid
      if $scope.need-fix => return
      $scope.uploading = true
      fd = new FormData!
      image = $(\#setimage).0
      <[name desc oid detail org]>.map -> if $scope.set[it] => fd.append it, $scope.set[it]
      fd.append \image, image.files.0
      $http do
        url: if $scope.oid => "/s/event/#{$scope.oid}" else \/s/event/new/
        method: if $scope.oid => \PUT else \POST
        data: fd
        transformRequest: angular.identity
        headers: "Content-Type": undefined
      .success (d) -> 
        window.location.href = "//#{if $scope.set.org => that+"." else ""}g0v.photos/e/#{$scope.set.oid}"
      .error (e) -> 
        $scope.uploading = false
        console.error e

    org-changed = (e) -> $scope.$apply -> 
    $(\#event-choose-org)select2 do
      query: (q) ->
        q.callback( results: [[k,v] for k,v of context.orgs].map(->id: it.0, text: it.1.name))
    if context.org =>
      $(\#event-choose-org)select2 \data, {id: context.org.oid, text: context.org.name}
      $scope.set.org = context.org.oid
    $(\#event-choose-org)on \change, (e) -> $scope.$apply -> $scope.set.org = e.val
