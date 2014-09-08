require! <[fs express mongodb body-parser crypto lwip]>
require! <[passport passport-local passport-facebook express-session]>
require! <[nodemailer nodemailer-smtp-transport]>
require! <[./backend ./storage ./secret]> 

r500 = (res, error) -> 
  console.log "[ERROR] #error"
  res.status(500).json({detail:error})
r404 = (res) -> res.status(404)send!
r403 = (res) -> res.status(403)send!
r400 = (res) -> res.status(400)send!
r200 = (res) -> res.send!
OID = mongodb.ObjectID
dbc = {}
ds = {}

<[media media/raw media/thumb src src/ls src/sass static static/css static/js]>.map ->
  if !fs.exists-sync it => fs.mkdir-sync it

config = debug: true, name: \g0vphotos
config <<< secret.config{clientID, clientSecret}

backend.init config

pic = backend.express.Router!
backend.app.use \/s, pic

# handler for add / delete of user's favorite. value: fav(true) / unfav(false)
fav = (value) -> (req, res) ->
  pid = req.params.id
  if !req.user => return r403 res
  if !!req.user.{}fav[pid] == value => return res.send!
  (e,t,n) <- ds.runQuery (ds.createQuery <[pic]> .filter "id =", pid), _
  if e => return r500 res, "looking for pic id = #pid: #e"
  if !t.length => return r400 res
  pic = t.0{key,data}
  if value => req.user.fav[pid] = value
  else delete req.user.fav[pid]

  cb = (e,k) ->
    if e => return r500 res, "update user fav: #e"
    pic.data.fav = ( pic.data.fav or 0 ) + ( if value => 1 else -1 ) >? 0
    (e,k) <- ds.save {key: pic.key, data: pic.data}, _
    if e => return r500 res, "update pic fav: #e"
    backend.update-user req
    r200 res

  if value => ds.save {key: ds.key(\fav, "#{req.user.email}/#pid"), data: {value}}, cb
  else => ds.delete ds.key(\fav, "#{req.user.email}/#pid"), cb

upload = (req, res) ->
  #TODO validation, preventing SQL injection
  if !req.files.image or !req.body.license => return res.status 400 .send!
  id = req.body.id = storage.id req.body
  # TODO event field, maybe extract from subdomain
  payload = backend.clean req.body{id,author,desc,tag,license,event}
  if req.{}event.name and !payload.event => payload.event = req.event.name
  payload.fav = 0
  payload.create_date = new Date!
  (e,k) <~ ds.save { key: ds.key(\pic, null), data: payload }, _
  if e => r500 res, "failed to add pic"
  # need guessing file type
  (e,img) <- lwip.open req.files.image.path, \jpg, _
  if e => 
    console.log "[ERROR] #e"
    return r500 res, "failed to read img file"
  [w,h] = [img.width!, img.height!]
  [w1,h1] = if w > h => [960, h * 960 / w] else [w * 718 / h, 718]
  [w2,h2] = [480, h * 480 / w]
  (e,b) <- img.toBuffer \jpg, _
  if e => return r500 res, "failed to get img buffer"
  (e1) <- storage.write \raw, id, b, _
  img1 = img.batch!resize(w1,h1)
  (e,b) <- img1.toBuffer \jpg, _
  if e => return r500 res, "failed to get img buffer"
  (e2) <- storage.write \medium, id, b, _
  img2 = img.batch!resize(w2,h2)
  (e,b) <- img2.toBuffer \jpg, _
  if e => return r500 res, "failed to get img buffer"
  (e3) <- storage.write \thumb, id, b, _
  if e1 or e2 or e3 => return r500 res, "failed to write img to storage: \n  raw: #e1\n  medium: #e2\n  thumb: #e3"
  res.send!
  backend.multi.clean req, res

backend.router.user
  ..get \/fav, (req, res) -> res.json(req.user.fav) # TODO need pagination
  ..put \/fav/:id, fav true
  ..delete \/fav/:id, fav false

pic
  ..get \/pic, (req, res) -> # get all site pic list
    # TODO need pagination
    query = ds.createQuery <[pic]> 
    #if req.{}event.name => query = query.filter "event =", req.event.name
    query = query.order \-create_date .limit 100
    offset = if !isNaN(req.query.next) => parseInt(req.query.next) else 0
    if offset => query = query.offset offset
    (e,t,n) <- ds.runQuery query, _
    if e => return r500 res, e
    if !t or !t.length => return r404 res
    if !n => return res.json { data: t.map(->it.data)}
    next = if t.length < 100 => -1 else (t.length + offset) 
    if req.{}event.name => t = t.filter -> it.data.event == req.event.name
    res.json {next, data: t.map(->it.data)}

  ..post \/pic, backend.multi.parser, upload # upload new pic

  ..get \/pic/:id, (req, res) -> # get single pic info
    (e,t,n) <- ds.runQuery (ds.createQuery <[pic]> .filter "id =", req.params.id), _
    if e => return r500 res, e
    if !t or !t.length => return r404 res
    # not always correct?
    if req.get("accept").indexOf(\application/json) == 0 => return res.json t.0.data
    res.render 'share.jade', {pic: t.0.data}

  ..get \/set/:id, (req, res) ->
    # need pagination
    query = if req.params.id => ds.createQuery <[pic]> .filter "event =", req.params.id
    else ds.createQuery <[pic]>
    #(e,t,n) <- ds.runQuery (ds.createQuery <[pic]> .filter "event =", req.params.id), _
    (e,t,n) <- ds.runQuery query, _
    if e => return r500 res, e
    if !t or !t.length => return r404 res
    res.json t.map(-> it.data)

  ..post \/set/new/, backend.multi.parser, (req, res) ->
    if !req.files.image or !/^[a-zA-Z0-9]{3,11}/.exec(req.body.event) => return r500 res, "incorrect data"
    if !req.body.name or !req.body.desc => return r500 res, "incorrect data"
    (e,t,n) <- ds.runQuery (ds.createQuery <[event]> .filter "event =", req.body.event), _
    if e => return r500 res, "failed to query event"
    if t and t.length => return r400 res
    (e,img) <- lwip.open req.files.image.path, \jpg, _
    if e => 
      console.log "[ERROR] #e"
      return r500 res, "failed to read img file"
    (e,b) <- img.toBuffer \jpg, _
    if e => return r500 res, "failed to get img buffer"
    (e) <- storage.write \img, "event/#{req.body.event}", b, _
    if e => return r500 res, "failed to write img to storage: #e"
    (e,k) <- ds.save {key: ds.key(\event,null), data: req.body}, _
    if e => return r500 res, "failed to insert event information"
    res.send!
    backend.multi.clean req, res

  ..post \/set/:id, (req, res) -> 
    req.body.event = req.params.id
    upload req, res


backend.app
  ..get \/context, (req, res) -> res.render \backend.ls, {user: req.user, event: req.{}event.data}

backend.app
  ..get \/, (req, res) -> 
    (err, event) <- backend.getEvent req, _
    if err => return r404 res
    res.render \index.jade
  ..get \/set/new/, (req, res) -> res.render \newset.jade

backend.start ({db, server, cols})->
  ds := backend.dataset
  # TODO dirty workaround: find a better way to update credential 
  setTimeout ->
    ds := backend.dataset
  , 60000
