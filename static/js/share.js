var x$;
x$ = angular.module('main', ['backend']);
x$.controller('share', ['$scope', '$http', 'context'].concat(function($scope, $http, context){
  import$($scope, {
    like: false,
    author: 'anonymous',
    license: 'unknown',
    desc: "( 載入中 ... )",
    loaded: false
  });
  return $scope.toggleLike = function(){
    return $scope.like = !$scope.like;
  };
}));
function import$(obj, src){
  var own = {}.hasOwnProperty;
  for (var key in src) if (own.call(src, key)) obj[key] = src[key];
  return obj;
}
