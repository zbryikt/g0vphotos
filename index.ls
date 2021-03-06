main = ($scope,$timeout) ->
  $scope <<< do
    desc: ""
    rate: 0.5
    hlActive: true
    img: do
      chosen: false
      raw: null
      thumbnail: null
      canvas: null
  $scope.img.rawReader = new FileReader!
    ..onload = -> $scope.$apply -> $scope.img.raw = new Uint8Array @result


  $.ajax do
    url: \https://www.googleapis.com/storage/v1/b/thumb.g0v.photos/o
  .done (data) ->
    console.log data
    $scope.$apply -> 
      $scope.list = data.items
    $timeout ->
      $ \#layout .isotope do
        itemSelector: \.thumbnail
        layoutMode: \fitRows

  dup = (canvas) ->
    ret = document.createElement(\canvas) <<< {width: canvas.width, height: canvas.height}
    ctx = ret.getContext \2d
    ctx.drawImage canvas, 0, 0
    return ret

  resize = (img) ->
    r = 400 / img.width
    console.log parseFloat($scope.rate)
    if r < parseFloat($scope.rate) => r = parseFloat($scope.rate)
    canvas = document.createElement \canvas
    canvas <<< {width: img.width * r, height: img.height * r}
    ctx = canvas.getContext \2d
    ctx.drawImage img, 0, 0, img.width, img.height, 0, 0, canvas.width, canvas.height
    if canvas.width > 400 => return resize canvas
    return canvas

  update-watcher = -> if $scope.img.raw and $scope.img.thumbnail and $scope.img.canvas =>
    $(\#upload-canvas)html $($scope.img.canvas)
    $('#output .preview')html $(dup $scope.img.canvas)
    $(\#output)show!

  $scope.$watch 'img.raw', update-watcher
  $scope.$watch 'img.thumbnail', update-watcher
    
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
    hash = {
      "name": "pic#{new Date!getTime!}_#{parseInt(Math.random!*1000000000,16)}"
      metadata: {
        "author": $scope.author or "anonymous"
        "desc": $scope.desc 
        "tag": $scope.tag
      }
    }
    sep = "DULLSEPARATOR"
    head = "--#sep\nContent-Type: application/json; chartset=UTF-8\n\n#{JSON.stringify(hash)}\n\n" +
           "--#sep\nContent-Type: image/jpg\n\n"
    tail = "\n\n--#{sep}--"
    payloads = [[$scope.img.raw, \raw.g0v.photos],[$scope.img.thumbnail, \thumb.g0v.photos]]
    url = \https://www.googleapis.com/upload/storage/v1/b
    arg = \o?uploadType=multipart&predefinedAcl=publicRead
    for payload in payloads
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
