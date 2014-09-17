angular.module \main
  ..controller \org, <[$scope $http context stateIndicator]> ++ ($scope, $http, context, stateIndicator) ->
    console.log \ok
    $scope.org = {}
    if context.org => $scope.org <<< context.org

    $scope.need-fix = false
    $scope.fix = (name) -> 
      if $scope.need-fix and $scope.neworgform.{}[name].$invalid => "has-error" else ""
    $scope.uploading = stateIndicator.init!
    $scope.delete = ->
      $http do
        url: "/d/org/#{$scope.org.oid}"
        method: \DELETE
      .success (d) -> console.log d
      .error (e) -> console.log e
    $scope.submit = ->
      $scope.uploading.loading!
      if !(/^[a-zA-Z0-9]{3,11}$/.exec($scope.org.oid)) =>
        $scope.neworgform.oid.$setValidity "illegal", false
      $scope.need-fix = $scope.neworgform.$invalid
      if $scope.need-fix =>
        $scope.uploading.fail!
        return
      fd = new FormData!
      banner = $(\#orgBanner).0
      avatar = $(\#orgAvatar).0
      <[name desc oid]>.map -> fd.append it, $scope.org[it]
      fd.append \banner, banner.files.0
      fd.append \avatar, avatar.files.0
      $http do
        url: if context.org => "/d/org/#{$scope.org.oid}" else \/d/org/
        method: if context.org => \PUT else \POST
        data: fd
        transformRequest: angular.identity
        headers: "Content-Type": undefined
      .success (d) -> 
        $scope.uploading.done!
        window.location.href = "//#{$scope.org.oid}.g0v.photos/"
      .error (e) -> 
        $scope.uploading.fail!
        console.error e
