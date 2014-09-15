angular.module \main
  ..controller \stream, <[$scope $interval $timeout $http context]> ++ ($scope, $interval, $timeout, $http, context) ->
    $scope <<< do
      user: context.user or null
      event: context.event or null
      events: context.events or null
      customauthor: false
      bkno: <[bk1 bk5 bk7]>[parseInt(Math.random! * 3)]
      cc: sa: false, by: true, nd: false, nc: false
      license: "Public Domain"
      desc: ""
      rate: 0.5
      hlActive: true
      uploading: false
      initlayout: false
      downloading: false
      list: []
      page: do
        next: 0
      img: do
        chosen: false
        raw: null
        thumbnail: null
        canvas: null
    $scope.init-isotope = ->
      if $scope.isotope => $scope.isotope.destroy!
      $scope.isotope = new Isotope $(\#layout)0, do
        itemSelector: \.thumbnail
        layoutMode: \masonry
        getSortData: weight: '[data-order]'
        sortBy: 'weight'
        sortAscending: false
    $scope.init-isotope!
    $scope.img.rawReader = new FileReader!
    $scope.img.rawReader.onload = -> $scope.$apply ~> $scope.img.raw = new Uint8Array @result

    license = (v, author) ->
      if !author or !(v.sa or v.by or v.nd or v.nc) => return "Public Domain"
      return "CC " + <[sa by nd nc]>filter(-> v[it])map(->it.toUpperCase!)join("-") + " 3.0"
    $scope.$watch 'cc', (-> $scope.license = license $scope.cc, $scope.author) , true
    $scope.$watch 'author', (-> $scope.license = license $scope.cc, $scope.author) , true
    $scope.refresh = ->
      $scope.downloading = true
      if $scope.page.next == -1 => return
      $http do
        url: "/s/pic?#{if $scope.page.next => 'next='+$scope.page.next else ''}"
        method: \GET
      .success (data) -> 
        if !$scope.list => $scope.list = []
        d = data.data
        console.log data
        $scope.page.next = data.next
        blah = $interval ->
          if d.length == 0 => 
            $scope.uploading = false
            $scope.downloading = false
            return $interval.cancel blah
          $scope.list.push(d.splice 0,1 .0)
        , 100
      .error (e) -> console.error e

    dup = (canvas) ->
      ret = document.createElement(\canvas) <<< {width: canvas.width, height: canvas.height}
      ctx = ret.getContext \2d
      ctx.drawImage canvas, 0, 0
      return ret

    resize = (img) ->
      r = 400 / img.width
      if r < parseFloat($scope.rate) => r = parseFloat($scope.rate)
      canvas = document.createElement \canvas
      canvas <<< {width: img.width * r, height: img.height * r}
      ctx = canvas.getContext \2d
      ctx.drawImage img, 0, 0, img.width, img.height, 0, 0, canvas.width, canvas.height
      if canvas.width > 400 => return resize canvas
      return canvas

    update-watcher = (show)-> if !show or ($scope.img.raw and $scope.img.thumbnail and $scope.img.canvas) =>
      setTimeout ->
        $(\#upload-canvas)html if show => $($scope.img.canvas) else ""
        $('#output .preview')html if show => $(dup $scope.img.canvas) else ""
        if show => $(\#output)show! else $(\#output)hide!
      , 0

    $scope.$watch 'img.raw', -> update-watcher true
    $scope.$watch 'img.thumbnail', -> update-watcher true
      
    $(\#file)change ->
      file = document.getElementById("file")
      if file.files.length == 0 => return
      if !(/image\//.exec file.files.0.type) => return
      $scope.img <<< {raw: null, thumbnail: null}
      $scope.img.rawReader.readAsArrayBuffer file.files.0
      img = new Image!
      img.onload = ->
        result = resize img
        du = result.toDataURL \image/jpeg, 0.85
        bs = atob(du.split \, .1)
        ua = new Uint8Array(new ArrayBuffer(bs.length))
        for i from 0 til bs.length => ua[i] = bs.charCodeAt i
        $scope.$apply -> $scope.img <<< {thumbnail: ua, canvas: result}
      img.src = URL.createObjectURL file.files.0

    $scope.cancel = ->
      $scope.img <<< {raw: null, thumbnail: null, canvas: null}
      update-watcher false

    $scope.submit = ->
      if $scope.uploading => return
      $scope.uploading = true
      $timeout (->$scope._submit!), 0 # let uploading work
    $scope._submit = ->
      finish = (refresh) ->
        update-watcher false
        if refresh => $timeout (-> $scope.refresh!), 500

      fd = new FormData!
      <[author desc tag]>map -> if $scope[it] => fd.append it, $scope[it]
      fd.append \license, license($scope.cc, $scope.author)
      fd.append \image, new Blob([$scope.img.raw],{type:"application/octet-stream"})
      $http do
        url: \/s/pic/
        method: \POST
        data: fd
        transformRequest: angular.identity
        headers: "Content-Type": undefined
      .success (d) -> 
        console.log d
        finish true
      .error (e) -> 
        console.log e
        finish false

    $scope.$watch 'customauthor' -> if !$scope.user or it => $scope.author = ""
      else $scope.author = $scope.user.name
    $scope.$watch 'user' -> if !it or $scope.customauthor => $scope.author = ""
      else $scope.author = $scope.user.name
    , true

    $(window).resize -> $(\#share-popover)removeClass \show

    $scope.showfav = false
    $scope.filterfav = (v) ->
      $scope.showfav = v
      $scope.isotope.arrange {filter: if v => ".fav" else "*"}

    $scope.fav = (e, pid)->
       if $scope.user.fav[pid] => delete $scope.user.fav[pid]
       else $scope.user.fav[pid] = true
       $http do
         url: "/u/fav/#pid"
         method: if $scope.user.fav[pid] => \PUT else \DELETE
       .success (d) -> console.log d
       .error (e) -> console.error e

    $scope.lastshare = null
    $scope.sharePopover = (e, pid) ->
      tgt = $(e.currentTarget)
      offset = tgt.offset!
      setTimeout (->
        spo = $(\#share-popover)
        spo.css do
          left: "#{offset.left - spo.width!/2 >?5 <?($(window)width! - spo.width!/2)}px"
          top: "#{offset.top - spo.height! - 30}px"
        if $scope.lastshare == pid => 
          $(\#share-popover)removeClass \show
          $scope.$apply -> $scope.lastshare = false
        else 
          $(\#share-popover)addClass \show
          $scope.$apply -> $scope.lastshare = pid

      ), 0

    $scope.gotop = -> $(document.body)animate scrollTop: 0
    $(window).scroll ->
      s = $(document.body).scrollTop!
      h = $(\#layout).height!
      if s > h and !$scope.downloading => $scope.refresh!
    $(\#attributions)popover!
    setTimeout (-> $(\#menu)sticky topSpacing: 0), 0
    $scope.refresh!