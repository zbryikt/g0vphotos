// Generated by LiveScript 1.2.0
var x$;
x$ = angular.module('main', []);
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
          return scope.isotope.appended(des[0]);
        });
      } else {
        return scope.isotope.appended(e[0].parentNode.parentNode.parentNode);
      }
    }
  };
});
x$.controller('main', ['$scope', '$timeout'].concat(function($scope, $timeout){
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
    user: null,
    userdata: {},
    customauthor: false,
    bkno: ['bk1', 'bk5'][parseInt(Math.random() * 2)],
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
    isotope: new Isotope($('#layout')[0], {
      itemSelector: '.thumbnail',
      layoutMode: 'masonry',
      getSortData: {
        weight: '[data-order]'
      },
      sortBy: 'weight'
    }),
    img: {
      chosen: false,
      raw: null,
      thumbnail: null,
      canvas: null
    }
  });
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
    return $.ajax({
      url: 'https://www.googleapis.com/storage/v1/b/thumb.g0v.photos/o'
    }).done(function(data){
      data.items.map(function(it){
        return ['author', 'desc', 'tag'].map(function(k){
          return it.metadata[k] = dcd(it.metadata[k]);
        });
      });
      return $scope.$apply(function(){
        $scope.list = data.items;
        $scope.list.reverse();
        return $scope.list.map(function(d, i){
          return d.order = i + 1;
        });
      });
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
    var hash, sep, head, tail, payloads, url, arg, finish, upload;
    hash = {
      "name": "pic" + new Date().getTime() + "_" + parseInt(Math.random() * 1000000000, 16),
      metadata: {
        "author": ecd($scope.author),
        "desc": ecd($scope.desc),
        "tag": ecd($scope.tag),
        "license": license($scope.cc, $scope.author)
      }
    };
    sep = "DULLSEPARATOR";
    head = ("--" + sep + "\nContent-Type: application/json; chartset=UTF-8\n\n" + JSON.stringify(hash) + "\n\n") + ("--" + sep + "\nContent-Type: image/jpg\n\n");
    tail = "\n\n--" + sep + "--";
    payloads = [[$scope.img.raw, 'raw.g0v.photos'], [$scope.img.thumbnail, 'thumb.g0v.photos']];
    url = 'https://www.googleapis.com/upload/storage/v1/b';
    arg = 'o?uploadType=multipart&predefinedAcl=publicRead';
    finish = function(refresh){
      $scope.$apply(function(){
        return $scope.uploading = false;
      });
      updateWatcher(false);
      if (refresh) {
        return $timeout(function(){
          return $scope.refresh();
        }, 500);
      }
    };
    upload = function(payloads){
      var payload, data, size, ua, i$, to$, i;
      finish(true);
      return;
      payload = payloads.splice(0, 1)[0];
      data = payload[0];
      size = head.length + tail.length + data.length;
      ua = new Uint8Array(size);
      for (i$ = 0, to$ = head.length; i$ < to$; ++i$) {
        i = i$;
        ua[i] = head.charCodeAt(i) & 0xff;
      }
      for (i$ = 0, to$ = data.length; i$ < to$; ++i$) {
        i = i$;
        ua[i + head.length] = data[i];
      }
      for (i$ = 0, to$ = tail.length; i$ < to$; ++i$) {
        i = i$;
        ua[i + head.length + data.length] = tail.charCodeAt(i) & 0xff;
      }
      console.log(url + "/" + payload[1] + "/" + arg);
      return $.ajax({
        type: 'POST',
        url: url + "/" + payload[1] + "/" + arg,
        contentType: "multipart/related; boundary=\"" + sep + "\"",
        data: ua.buffer,
        processData: false
      }).done(function(e){
        if (payloads.length === 0) {
          return finish(true);
        }
        return setTimeout(function(){
          return upload(payloads);
        }, 0);
      }).error(function(e){
        return finish(false);
      });
    };
    return upload(payloads);
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
  $scope.heart = function(e, pid){
    var ref$, ref1$;
    if (((ref$ = $scope.userdata).heart || (ref$.heart = {}))[pid]) {
      return ref1$ = (ref$ = $scope.userdata.heart)[pid], delete ref$[pid], ref1$;
    } else {
      return $scope.userdata.heart[pid] = true;
    }
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
  $scope.fbready = function(){
    console.log("facebook is ready.");
    return FB.getLoginStatus(function(r){
      if (r.status === 'connected') {
        return FB.api('/me', function(r){
          return $scope.$apply(function(){
            return $scope.user = r;
          });
        });
      }
    });
  };
  $scope.login = function(){
    return FB.login(function(r){
      if (r.status === 'connected') {
        return FB.api('/me', function(r){
          return $scope.$apply(function(){
            return $scope.user = r;
          });
        });
      }
    });
  };
  $scope.logout = function(){
    return FB.logout(function(r){
      return $scope.$apply(function(){
        return $scope.user = null;
      });
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