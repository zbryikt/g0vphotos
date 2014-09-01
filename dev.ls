angular.module \main
  .controller \dev, <[$scope $http]> ++ ($scope, $http) ->
    $scope.logout = ->
      $http do
        url: \/u/logout
        method: \GET
      .success (d) -> console.log d
      .error (d) -> console.log d
    $scope.login = ->
      $http do
        url: \/u/login
        method: \POST
        data: JSON.stringify({} <<< $scope{email,passwd})
      .success (d) -> console.log d
      .error (d) -> console.error d

    $scope.upload = ->
      $http do
        url: \/s/pic/
        method: \POST
        data: JSON.stringify($scope.uppic)
      .success (d) -> console.log d
      .error (d) -> console.error d

    $scope.uploadset = ->
      $http do
        url: \/s/set/1234
        method: \POST
        data: JSON.stringify($scope.uppic)
      .success (d) -> console.log d
      .error (d) -> console.error d

    $scope.fav = (id, value) ->
      $http do
        url: "/s/pic/#{id}/fav"
        method: if value => \PUT else \DELETE
      .success (d) -> console.log d
      .error (d) -> console.error d
