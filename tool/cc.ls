require! <[fs gcloud lwip mongodb crypto ../storage]>
#storage = gcloud.storage
datastore = gcloud.datastore


clean = (obj) ->
  for k,v of obj =>
    if !v => delete obj[k]
    if typeof(v)=='object' => @clean v
  obj

genid = (data) ->
  md5 = parseInt(crypto.createHash(\md5).update(JSON.stringify(data)).digest(\hex),16)
  now = new Date!getTime!
  rnd = parseInt(Math.random! * 1000000)
  [now,rnd,md5]map(-> it.toString 36)join ""

ds = new datastore.Dataset do
  projectId: \keen-optics-617
  #keyFilename: \/Users/tkirby/.ssh/google/g0vphotos/key.json

items = JSON.parse( fs.read-file-sync \current.json )
next = -> setTimeout parse, 0

parse = ->
  if !items.length => return
  console.log items.length
  item = items.splice 0,1 .0
  fn = item.filename
  payload = clean item{author, license, tag, event, desc, create_date, creator, ip}
  payload.create_date = new Date payload.create_date
  payload.id = fn.replace /media\/(.+)\.jpg/, "$1"
  <[tag desc author]>map -> if payload[it] => payload[it] = decodeURIComponent payload[it]
  cdate = new Date payload.create_date
  b4h10n = new Date 2014, 7, 20
  payload.event = if (cdate > b4h10n) => "h10n" else "h9n"
  
  (e,k) <- ds.save {key: ds.key(\pic, null), data: payload}, _
  if e => 
    console.log "[ERROR] fail to save ds: #e"
    return next!
  next!

  #(e,img) <- lwip.open fn, \jpg, _
  #[w,h] = [img.width!, img.height!]
  #[w1,h1] = if w > h => [960, h * 960 / w] else [w * 718 / h, 718]
  #img1 = img.batch!resize(w1,h1)
  #img1.writeFile "/Users/tkirby/workspace/zbryikt/g0vphotos/other/medium/#{payload.id}", "jpg", {}, -> 
  #  console.log it
  #  return next!
  #(e,b) <- img1.toBuffer \jpg, _
  #if e =>
  #  console.log "[ERROR] failed to convert to buffer (#e)"
  #  return next!
  #console.log "upload #{fn} to cloud..."
  #(e) <- storage.write \medium, payload.id, b, _
  #if e => 
  #  console.log "[ERROR] failed to write to storage (#e)"
  #  return next!
  #next!

parse!
