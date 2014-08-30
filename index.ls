angular.module \main <[]>
  ..directive \isotope, -> do
    restrict: \A
    link: (scope, e, attrs, ctrl) ->
      des = $(e.0.parentNode.parentNode.parentNode)
      des.addClass \iso
      if e.prop(\tagName) == \IMG => e.load ->
        des.addClass \iso-show
        scope.isotope.appended des.0
      else scope.isotope.appended e.0.parentNode.parentNode.parentNode
  ..controller \main, <[$scope $timeout]> ++ ($scope, $timeout) ->

    ecd = -> if it => encodeURIComponent it else it
    dcd = -> if it => decodeURIComponent it else it

    $scope <<< do
      user: null
      userdata: {}
      customauthor: false
      bkno: <[bk7]>[parseInt(Math.random! * 1)]
      #bkno: <[bk1 bk5]>[parseInt(Math.random! * 2)]
      cc: sa: false, by: true, nd: false, nc: false
      license: "Public Domain"
      desc: ""
      rate: 0.5
      hlActive: true
      uploading: false
      initlayout: false
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
    $scope.init-isotope!
    $scope.img.rawReader = new FileReader!
    $scope.img.rawReader.onload = -> $scope.$apply ~> $scope.img.raw = new Uint8Array @result

    license = (v, author) ->
      if !author or !(v.sa or v.by or v.nd or v.nc) => return "Public Domain"
      return "CC " + <[sa by nd nc]>filter(-> v[it])map(->it.toUpperCase!)join("-") + " 3.0"
    $scope.$watch 'cc', (-> $scope.license = license $scope.cc, $scope.author) , true
    $scope.$watch 'author', (-> $scope.license = license $scope.cc, $scope.author) , true
    $scope.refresh = ->
      $timeout ->
        $.ajax do
          url: \https://www.googleapis.com/storage/v1/b/thumb.g0v.photos/o
        .done (data) ->
          data.items.map (it) -> <[author desc tag]>map (k) -> it.metadata[k] = dcd it.metadata[k]
          $scope.init-isotope!
          $scope.$apply ->
            $scope.list = data.items
            $scope.list.reverse!
            $scope.list.map (d,i) -> d.order = i + 1
          $timeout (->
            $scope.isotope.layout!
            $scope.uploading = false
          ), 100
      , 500
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
      hash = {
        "name": "pic#{new Date!getTime!}_#{parseInt(Math.random!*1000000000,16)}"
        metadata: {
          "author": ecd $scope.author
          "desc": ecd $scope.desc 
          "tag": ecd $scope.tag
          "license": license($scope.cc, $scope.author)
        }
      }
      sep = "DULLSEPARATOR"
      head = "--#sep\nContent-Type: application/json; chartset=UTF-8\n\n#{JSON.stringify(hash)}\n\n" +
             "--#sep\nContent-Type: image/jpg\n\n"
      tail = "\n\n--#{sep}--"
      payloads = [[$scope.img.raw, \raw.g0v.photos],[$scope.img.thumbnail, \thumb.g0v.photos]]
      url = \https://www.googleapis.com/upload/storage/v1/b
      arg = \o?uploadType=multipart&predefinedAcl=publicRead
      finish = (refresh) ->
        #$scope.$apply -> $scope.uploading = false
        update-watcher false
        if refresh => $timeout (-> $scope.refresh!), 500
      upload = (payloads) ->
        payload = payloads.splice(0,1)0
        data = payload.0
        size = head.length + tail.length + data.length
        ua = new Uint8Array size
        for i from 0 til head.length => ua[i] = head.charCodeAt(i) .&. 0xff
        for i from 0 til data.length => ua[i + head.length] = data[i]
        for i from 0 til tail.length => ua[i + head.length + data.length] = tail.charCodeAt(i) .&. 0xff
        console.log "#{url}/#{payload.1}/#{arg}"
        $.ajax do
          type: \POST
          url: "#{url}/#{payload.1}/#{arg}"
          contentType: "multipart/related; boundary=\"#sep\""
          data: ua.buffer
          processData: false
        .done (e) -> 
          if payloads.length == 0 => return finish true
          setTimeout (-> upload payloads), 0
        .error (e) -> finish false
      upload payloads

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

    $scope.heart = (e, pid)->
      if $scope.userdata.{}heart[pid] => delete $scope.userdata.heart[pid]
      else $scope.userdata.heart[pid] = true

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
    $scope.fbready = ->
      console.log "facebook is ready."
      (r) <- FB.getLoginStatus
      if r.status == \connected => FB.api \/me, (r) -> 
        $scope.$apply -> $scope.user = r
    $scope.login = -> FB.login (r) -> if r.status == \connected =>
      FB.api \/me (r) -> $scope.$apply -> $scope.user = r
    $scope.logout = -> FB.logout (r) -> $scope.$apply -> $scope.user = null

    $scope.gotop = ->
      $(document.body)animate scrollTop: 0
        
    $(\#attributions)popover!
    setTimeout (-> $(\#menu)sticky topSpacing: 0), 0
    $scope.refresh!
