angular.module('main').controller('dev', ['$scope', '$http'].concat(function($scope, $http){
  $scope.logout = function(){
    return $http({
      url: '/u/logout',
      method: 'GET'
    }).success(function(d){
      return console.log(d);
    }).error(function(d){
      return console.log(d);
    });
  };
  $scope.login = function(){
    var ref$;
    return $http({
      url: '/u/login',
      method: 'POST',
      data: JSON.stringify((ref$ = {}, ref$.email = $scope.email, ref$.passwd = $scope.passwd, ref$))
    }).success(function(d){
      return console.log(d);
    }).error(function(d){
      return console.error(d);
    });
  };
  $scope.upload = function(){
    return $http({
      url: '/s/pic/',
      method: 'POST',
      data: JSON.stringify($scope.uppic)
    }).success(function(d){
      return console.log(d);
    }).error(function(d){
      return console.error(d);
    });
  };
  $scope.uploadset = function(){
    return $http({
      url: '/s/set/1234',
      method: 'POST',
      data: JSON.stringify($scope.uppic)
    }).success(function(d){
      return console.log(d);
    }).error(function(d){
      return console.error(d);
    });
  };
  return $scope.fav = function(id, value){
    return $http({
      url: "/s/pic/" + id + "/fav",
      method: value ? 'PUT' : 'DELETE'
    }).success(function(d){
      return console.log(d);
    }).error(function(d){
      return console.error(d);
    });
  };
}));
