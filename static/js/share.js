var share;
console.log('ok');
share = function($scope, $http){
  import$($scope, {
    like: false,
    author: 'anonymous',
    license: 'unknown',
    desc: "( 載入中 ... )",
    loaded: false
  });
  $scope.toggleLike = function(){
    return $scope.like = !$scope.like;
  };
  return $scope.$watch('pid', function(it){
    if (it) {
      return $http.get("https://www.googleapis.com/storage/v1/b/thumb.g0v.photos/o/" + $scope.pid).success(function(d, s, h, c){
        var ref$;
        $scope.author = (ref$ = d.metadata).author;
        $scope.desc = ref$.desc;
        $scope.license = ref$.license;
        $scope.desc = decodeURIComponent($scope.desc);
        return $scope.loaded = true;
      });
    }
  });
};
function import$(obj, src){
  var own = {}.hasOwnProperty;
  for (var key in src) if (own.call(src, key)) obj[key] = src[key];
  return obj;
}
