console.log \ok
share = ($scope, $http) ->
  $scope <<< do
    like: false
    author: \anonymous
    license: \unknown
    desc: "( 載入中 ... )"
    loaded: false
  $scope.toggleLike = -> $scope.like = !$scope.like
  $scope.$watch 'pid' -> if it =>
    $http.get "https://www.googleapis.com/storage/v1/b/thumb.g0v.photos/o/#{$scope.pid}" .success (d, s, h, c) ->
      $scope <<< d.metadata{author,desc,license}
      $scope.desc = decodeURIComponent $scope.desc
      $scope.loaded = true
