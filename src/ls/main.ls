angular.module \main <[backend common]>
  ..directive \isotope, -> do
    restrict: \A
    link: (scope, e, attrs, ctrl) ->
      des = $(e.0.parentNode.parentNode.parentNode)
      des.addClass \iso
      if e.prop(\tagName) == \IMG => e.load ->
        des.addClass \iso-show
        scope.isotope.appended des.0
        scope.$on \$destroy ->
          scope.isotope.remove des.0
          scope.isotope.layout!
      else
        scope.isotope.appended e.0.parentNode.parentNode.parentNode
        scope.$on \$destroy ->
          scope.isotope.remove e.0.parentNode.parentNode.parentNode
          scope.isotope.layout!
  ..controller \main, <[$scope $timeout $http context global]> ++  ($scope, $timeout, $http, context, global) ->
    $scope <<< context{user, event, events}
    $scope <<< do
      login: -> window.location.href = \/u/auth/facebook/ 
      logout: -> $http {url: \/u/logout, method: \GET} .success -> window.location.reload!

