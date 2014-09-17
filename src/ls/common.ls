angular.module \common, <[]>
  ..directive \ldstate, <[$timeout]> ++ ($timeout) -> do
    require: \ngModel
    restrict: \E
    scope: state: \=ngModel
    template: '<div class="state-indicator"><img ng-show="state==1" src="/img/reload.gif"/>' +
      '<i ng-show="state==2" ng-class="{\'fadeout\':state==2}" class="fa fa-check ajax-done"></i>'+
      '<i mg-show="state==3" ng-class="{\'fadeout\':state==3}" class="fa fa-exclamation-circle ajax-fail"></i></div>'
    link: (s,e,a,c) ->

  ..factory \stateIndicator, -> do
    init: -> do
      value: 0
      reset: -> @value = 0
      loading: -> @value = 1
      done: -> @value = 2
      fail: -> @value = 3
