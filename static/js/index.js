var x$;
x$ = angular.module('main', ['backend']);
x$.directive('isotope', function(){
  return {
    restrict: 'A',
    link: function(scope, e, attrs, ctrl){
      var des;
      des = $(e[0].parentNode.parentNode.parentNode);
      des.addClass('iso');
      if (e.prop('tagName') === 'IMG') {
        return e.load(function(){
          des.addClass('iso-show');
          scope.isotope.appended(des[0]);
          return scope.$on('$destroy', function(){
            console.log('bye');
            scope.isotope.remove(des[0]);
            return scope.isotope.layout();
          });
        });
      } else {
        scope.isotope.appended(e[0].parentNode.parentNode.parentNode);
        return scope.$on('$destroy', function(){
          console.log('bye');
          scope.isotope.remove(e[0].parentNode.parentNode.parentNode);
          return scope.isotope.layout();
        });
      }
    }
  };
});
x$.controller('main', ['$scope', '$interval', '$timeout', '$http', 'context'].concat(function($scope, $interval, $timeout, $http, context){
  var ecd, dcd, license, dup, resize, updateWatcher;
  ecd = function(it){
    if (it) {
      return encodeURIComponent(it);
    } else {
      return it;
    }
  };
  dcd = function(it){
    if (it) {
      return decodeURIComponent(it);
    } else {
      return it;
    }
  };
  import$($scope, {
    user: context.user || null,
    userdata: {},
    customauthor: false,
    bkno: ['bk1', 'bk5', 'bk7'][parseInt(Math.random() * 3)],
    cc: {
      sa: false,
      by: true,
      nd: false,
      nc: false
    },
    license: "Public Domain",
    desc: "",
    rate: 0.5,
    hlActive: true,
    uploading: false,
    initlayout: false,
    img: {
      chosen: false,
      raw: null,
      thumbnail: null,
      canvas: null
    }
  });
  $scope.initIsotope = function(){
    if ($scope.isotope) {
      $scope.isotope.destroy();
    }
    return $scope.isotope = new Isotope($('#layout')[0], {
      itemSelector: '.thumbnail',
      layoutMode: 'masonry',
      getSortData: {
        weight: '[data-order]'
      },
      sortBy: 'weight'
    });
  };
  $scope.initIsotope();
  $scope.img.rawReader = new FileReader();
  $scope.img.rawReader.onload = function(){
    var this$ = this;
    return $scope.$apply(function(){
      return $scope.img.raw = new Uint8Array(this$.result);
    });
  };
  license = function(v, author){
    if (!author || !(v.sa || v.by || v.nd || v.nc)) {
      return "Public Domain";
    }
    return "CC " + ['sa', 'by', 'nd', 'nc'].filter(function(it){
      return v[it];
    }).map(function(it){
      return it.toUpperCase();
    }).join("-") + " 3.0";
  };
  $scope.$watch('cc', function(){
    return $scope.license = license($scope.cc, $scope.author);
  }, true);
  $scope.$watch('author', function(){
    return $scope.license = license($scope.cc, $scope.author);
  }, true);
  $scope.refresh = function(){
    return $http({
      url: '/s/pic/',
      method: 'GET'
    }).success(function(d){
      var blah;
      $scope.list = [];
      return blah = $interval(function(){
        if (d.length === 0) {
          $scope.uploading = false;
          return $interval.cancel(blah);
        }
        return $scope.list.push(d.splice(0, 1)[0]);
      }, 100);
    }).error(function(e){
      return console.error(e);
    });
  };
  dup = function(canvas){
    var ret, ref$, ctx;
    ret = (ref$ = document.createElement('canvas'), ref$.width = canvas.width, ref$.height = canvas.height, ref$);
    ctx = ret.getContext('2d');
    ctx.drawImage(canvas, 0, 0);
    return ret;
  };
  resize = function(img){
    var r, canvas, ctx;
    r = 400 / img.width;
    if (r < parseFloat($scope.rate)) {
      r = parseFloat($scope.rate);
    }
    canvas = document.createElement('canvas');
    canvas.width = img.width * r;
    canvas.height = img.height * r;
    ctx = canvas.getContext('2d');
    ctx.drawImage(img, 0, 0, img.width, img.height, 0, 0, canvas.width, canvas.height);
    if (canvas.width > 400) {
      return resize(canvas);
    }
    return canvas;
  };
  updateWatcher = function(show){
    if (!show || ($scope.img.raw && $scope.img.thumbnail && $scope.img.canvas)) {
      return setTimeout(function(){
        $('#upload-canvas').html(show ? $($scope.img.canvas) : "");
        $('#output .preview').html(show ? $(dup($scope.img.canvas)) : "");
        if (show) {
          return $('#output').show();
        } else {
          return $('#output').hide();
        }
      }, 0);
    }
  };
  $scope.$watch('img.raw', function(){
    return updateWatcher(true);
  });
  $scope.$watch('img.thumbnail', function(){
    return updateWatcher(true);
  });
  $('#file').change(function(){
    var file, ref$, img;
    file = document.getElementById("file");
    if (file.files.length === 0) {
      return;
    }
    if (!/image\//.exec(file.files[0].type)) {
      return;
    }
    ref$ = $scope.img;
    ref$.raw = null;
    ref$.thumbnail = null;
    $scope.img.rawReader.readAsArrayBuffer(file.files[0]);
    img = new Image();
    img.onload = function(){
      var result, du, bs, ua, i$, to$, i;
      result = resize(img);
      du = result.toDataURL('image/jpeg', 0.85);
      bs = atob(du.split(',')[1]);
      ua = new Uint8Array(new ArrayBuffer(bs.length));
      for (i$ = 0, to$ = bs.length; i$ < to$; ++i$) {
        i = i$;
        ua[i] = bs.charCodeAt(i);
      }
      return $scope.$apply(function(){
        var ref$;
        return ref$ = $scope.img, ref$.thumbnail = ua, ref$.canvas = result, ref$;
      });
    };
    return img.src = URL.createObjectURL(file.files[0]);
  });
  $scope.cancel = function(){
    var ref$;
    ref$ = $scope.img;
    ref$.raw = null;
    ref$.thumbnail = null;
    ref$.canvas = null;
    return updateWatcher(false);
  };
  $scope.submit = function(){
    if ($scope.uploading) {
      return;
    }
    $scope.uploading = true;
    return $timeout(function(){
      return $scope._submit();
    }, 0);
  };
  $scope._submit = function(){
    var finish, fd;
    finish = function(refresh){
      updateWatcher(false);
      if (refresh) {
        return $timeout(function(){
          return $scope.refresh();
        }, 500);
      }
    };
    fd = new FormData();
    ['author', 'desc', 'tag'].map(function(it){
      if ($scope[it]) {
        return fd.append(it, $scope[it]);
      }
    });
    fd.append('license', license($scope.cc, $scope.author));
    fd.append('image', new Blob([$scope.img.raw], {
      type: "application/octet-stream"
    }));
    return $http({
      url: '/s/pic/',
      method: 'POST',
      data: fd,
      transformRequest: angular.identity,
      headers: {
        "Content-Type": undefined
      }
    }).success(function(d){
      return finish(true);
    }).error(function(e){
      return finish(false);
    });
  };
  $scope.$watch('customauthor', function(it){
    if (!$scope.user || it) {
      return $scope.author = "";
    } else {
      return $scope.author = $scope.user.name;
    }
  });
  $scope.$watch('user', function(it){
    if (!it || $scope.customauthor) {
      return $scope.author = "";
    } else {
      return $scope.author = $scope.user.name;
    }
  }, true);
  $(window).resize(function(){
    return $('#share-popover').removeClass('show');
  });
  $scope.showfav = false;
  $scope.filterfav = function(v){
    $scope.showfav = v;
    return $scope.isotope.arrange({
      filter: v ? ".fav" : "*"
    });
  };
  $scope.fav = function(e, pid){
    if ($scope.user.fav[pid]) {
      delete $scope.user.fav[pid];
    } else {
      $scope.user.fav[pid] = true;
    }
    return $http({
      url: "/u/fav/" + pid,
      method: $scope.user.fav[pid] ? 'PUT' : 'DELETE'
    }).success(function(d){
      return console.log(d);
    }).error(function(e){
      return console.error(e);
    });
  };
  $scope.lastshare = null;
  $scope.sharePopover = function(e, pid){
    var tgt, offset;
    tgt = $(e.currentTarget);
    offset = tgt.offset();
    return setTimeout(function(){
      var spo, ref$, ref1$, ref2$;
      spo = $('#share-popover');
      spo.css({
        left: ((ref$ = (ref2$ = offset.left - spo.width() / 2) > 5 ? ref2$ : 5) < (ref1$ = $(window).width() - spo.width() / 2) ? ref$ : ref1$) + "px",
        top: (offset.top - spo.height() - 30) + "px"
      });
      if ($scope.lastshare === pid) {
        $('#share-popover').removeClass('show');
        return $scope.$apply(function(){
          return $scope.lastshare = false;
        });
      } else {
        $('#share-popover').addClass('show');
        return $scope.$apply(function(){
          return $scope.lastshare = pid;
        });
      }
    }, 0);
  };
  $scope.login = function(){
    return window.location.href = '/u/auth/facebook/';
  };
  $scope.logout = function(){
    return $http({
      url: '/u/logout',
      method: 'GET'
    }).success(function(){
      return window.location.reload();
    });
  };
  $scope.gotop = function(){
    return $(document.body).animate({
      scrollTop: 0
    });
  };
  $('#attributions').popover();
  setTimeout(function(){
    return $('#menu').sticky({
      topSpacing: 0
    });
  }, 0);
  return $scope.refresh();
}));
function import$(obj, src){
  var own = {}.hasOwnProperty;
  for (var key in src) if (own.call(src, key)) obj[key] = src[key];
  return obj;
}
