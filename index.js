// Generated by LiveScript 1.2.0
var main;
main = function($scope, $timeout){
  var x$, dup, resize, updateWatcher;
  import$($scope, {
    desc: "",
    rate: 0.5,
    hlActive: true,
    img: {
      chosen: false,
      raw: null,
      thumbnail: null,
      canvas: null
    }
  });
  x$ = $scope.img.rawReader = new FileReader();
  x$.onload = function(){
    return $scope.$apply(function(){
      return $scope.img.raw = new Uint8Array(this.result);
    });
  };
  $.ajax({
    url: 'https://www.googleapis.com/storage/v1/b/thumb.g0v.photos/o'
  }).done(function(data){
    console.log(data);
    $scope.$apply(function(){
      return $scope.list = data.items;
    });
    return $timeout(function(){
      return $('#layout').isotope({
        itemSelector: '.thumbnail',
        layoutMode: 'fitRows'
      });
    });
  });
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
    console.log(parseFloat($scope.rate));
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
    var hash, sep, head, tail, payloads, url, arg, i$, len$, payload, data, size, ua, j$, to$, i, results$ = [];
    hash = {
      "name": "pic" + new Date().getTime() + "_" + parseInt(Math.random() * 1000000000, 16),
      metadata: {
        "author": $scope.author || "anonymous",
        "desc": $scope.desc,
        "tag": $scope.tag
      }
    };
    sep = "DULLSEPARATOR";
    head = ("--" + sep + "\nContent-Type: application/json; chartset=UTF-8\n\n" + JSON.stringify(hash) + "\n\n") + ("--" + sep + "\nContent-Type: image/jpg\n\n");
    tail = "\n\n--" + sep + "--";
    payloads = [[$scope.img.raw, 'raw.g0v.photos'], [$scope.img.thumbnail, 'thumb.g0v.photos']];
    url = 'https://www.googleapis.com/upload/storage/v1/b';
    arg = 'o?uploadType=multipart&predefinedAcl=publicRead';
    for (i$ = 0, len$ = payloads.length; i$ < len$; ++i$) {
      payload = payloads[i$];
      data = payload[0];
      size = head.length + tail.length + data.length;
      ua = new Uint8Array(size);
      for (j$ = 0, to$ = head.length; j$ < to$; ++j$) {
        i = j$;
        ua[i] = head.charCodeAt(i) & 0xff;
      }
      for (j$ = 0, to$ = data.length; j$ < to$; ++j$) {
        i = j$;
        ua[i + head.length] = data[i];
      }
      for (j$ = 0, to$ = tail.length; j$ < to$; ++j$) {
        i = j$;
        ua[i + head.length + data.length] = tail.charCodeAt(i) & 0xff;
      }
      console.log(url + "/" + payload[1] + "/" + arg);
      results$.push($.ajax({
        type: 'POST',
        url: url + "/" + payload[1] + "/" + arg,
        contentType: "multipart/related; boundary=\"" + sep + "\"",
        data: ua.buffer,
        processData: false
      }));
    }
    return results$;
  };
  return $('#attributions').popover();
};
function import$(obj, src){
  var own = {}.hasOwnProperty;
  for (var key in src) if (own.call(src, key)) obj[key] = src[key];
  return obj;
}