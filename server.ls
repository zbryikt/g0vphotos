require! <[fs express mongodb body-parser crypto lwip]>
require! <[passport passport-local passport-facebook express-session]>
require! <[nodemailer nodemailer-smtp-transport]>
require! {'./backend/main'.backend, './backend/main'.aux}
require! driver: './backend/gcs'
#require! driver: './backend/mongodb'
require! <[./storage ./secret]> 
require! <[./org]>

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

config = do
  debug: true
  name: \g0vphotos
config <<< secret

org-store = do
  data: {}
  latest: (req, cb) ->
    (e,t,n) <~ ds.runQuery (ds.createQuery <[org]>), _
    if e or !t => return
    for it in t => @data[it.data.oid] = it.data
  get: (req, cb) ->
    part = req.headers.host.split \.
    org = if part.length > 2 => part.0 else ""
    if !org or org=="www" => return cb null, "", {}
    if @data[org] => return cb null, org, @data[org]
    (e,t,n) <~ ds.runQuery (ds.createQuery <[org]> .filter "oid =", org), _
    if e or !t or t.length==0 => return cb true, null, {}
    @data[org] = obj = t.0.data
    cb null, org, obj

event-store = do
  data: {}
  latest: (req, cb) ->
    (e,t,n) <~ ds.runQuery (ds.createQuery <[event]>), _
    if e or !t => return
    for it in t => 
      @data.{}[it.data.org][it.data.oid || it.data.event] = it.data
  # 舉辦活動時，利用這個來設定預設的事件名
  default: (org) -> if org=="www" => "summit" else null # null
  get: (req, cb) ->
    org = if req.org => that.oid else "www"
    ret = /^\/e\/([^/]+)\/?/.exec(req.url)
    event = if ret => ret.1 else @default org
    if !event => return cb null, "", {}
    if @data[event] => return cb null, event, @data[event]
    q = ds.createQuery <[event]> .filter("oid =", event)filter("org =", org)
    (e,t,n) <~ ds.runQuery q, _
    if e or !t or t.length==0 => return cb true, null, {}
    @data.{}[org][event] = obj = t.0.data
    cb null, event, obj

local-init = (app) ->
  app.use (req, res, next) ~> # retrieve subdomain
    (error, org, org-obj) <- org-store.get req, _
    if error => return next!
    if org => req.org = org-obj
    (error, event, obj) <- event-store.get req, _
    if error => return next!
    if event => req.event = obj #{name: event, data: obj}
    next!

backend.init config, driver, local-init

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
  if value => ds.save {key: ds.key([\fav, "#{req.user.username}/#pid"]), data: {username: req.user.username, pic: pid}}, cb
  else => ds.delete ds.key([\fav, "#{req.user.username}/#pid"]), cb

upload = (req, res) ->
  #TODO validation, preventing SQL injection
  if !req.files.image or !req.body.license => return res.status 400 .send!
  id = req.body.id = storage.id req.body
  payload = aux.clean req.body{id,author,desc,tag,license,event,org}
  if req.{}event.oid and !payload.event => payload.event = req.event.oid
  if !payload.org => payload.org = if req.{}org.oid => that else "www"
  payload.fav = 0
  payload.create_date = new Date!
  (e,k) <~ ds.save { key: ds.key([\pic, null]), data: payload }, _
  if e => r500 res, "failed to add pic"
  # need guessing file type
  (e,img) <- lwip.open req.files.image.path, \jpg, _
  if e => return r500 res, "failed to read img file"
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
  ..get \/pic/, (req, res) -> # get all site pic list
    query = ds.createQuery <[pic]> .order \-create_date .limit 100
    offset = if !isNaN(req.query.next) => parseInt(req.query.next) else 0
    if offset => query = query.offset offset
    (e,t,n) <- ds.runQuery query, _
    if e => return r500 res, e
    if !t or !t.length => return r404 res
    next = if t.length < 100 => -1 else (t.length + offset) 
    res.json {next, data: t.map(->it.data)}

  ..post \/pic, backend.multi.parser, upload # upload new pic

  ..get \/pic/:id, (req, res) -> # get single pic info
    (e,t,n) <- ds.runQuery (ds.createQuery <[pic]> .filter "id =", req.params.id), _
    if e => return r500 res, e
    if !t or !t.length => return r404 res
    # not always correct?
    if req.get("accept").indexOf(\application/json) == 0 => return res.json t.0.data
    res.render 'share.jade', {pic: t.0.data}

  ..get \/event/:id, (req, res) ->
    # need pagination
    query = if req.params.id => ds.createQuery <[pic]> .filter "event =", req.params.id
    else ds.createQuery <[pic]>
    #(e,t,n) <- ds.runQuery (ds.createQuery <[pic]> .filter "event =", req.params.id), _
    (e,t,n) <- ds.runQuery query, _
    if e => return r500 res, e
    if !t or !t.length => return r404 res
    res.json t.map(-> it.data)

  ..post \/event/new/, backend.multi.parser, (req, res) ->
    if !req.user => return r400 res, "login required"
    if !req.files.image or !/^[a-zA-Z0-9]{3,11}/.exec(req.body.event) => return r500 res, "incorrect data"
    if !req.body.name or !req.body.desc => return r500 res, "incorrect data"
    org = if req.org and req.org.oid => req.org.oid else "www"
    (e,t,n) <- ds.runQuery (ds.createQuery <[event]> .filter("oid =", req.body.oid).filter("org =", org)), _
    if e => return r500 res, "failed to query event"
    if t and t.length => return r400 res
    # TODO need guessing file type
    (e,img) <- lwip.open req.files.image.path, \jpg, _
    if e => return r500 res, "failed to read img file"
    (e,b) <- img.toBuffer \jpg, _
    if e => return r500 res, "failed to get img buffer"
    (e) <- storage.write \img, "event/#{req.body.oid}", b, _
    if e => return r500 res, "failed to write img to storage: #e"
    req.body.create_date = new Date!
    req.body.owner = req.user.username
    # TODO check if org exists
    if !req.body.org => req.body.org = org
    (e,k) <- ds.save {key: ds.key([\event,null]), data: req.body}, _
    if e => return r500 res, "failed to insert event information"
    res.send!
    backend.multi.clean req, res

  ..post \/event/:id, backend.multi.parser, (req, res) -> 
    req.body.event = req.params.id
    upload req, res

  ..delete \/event/:id, (req, res) ->
    # TODO delete
    res.send!
    backend.multi.clean req, res

  ..put \/event/:id, backend.multi.parser, (req, res) -> 
    if !req.user => return r400 res, "login required"
    org = if req.org => that.oid else null
    (e,t,n) <- ds.runQuery (ds.createQuery <[event]> .filter("oid =", req.params.id).filter("org =", org)), _
    if e or !t or !t.length => return r404 res
    t = t.0
    if t.data.owner != req.user.username => return r403 res, "only owner can edit event"
    # TODO data validation
    for key in <[name desc]> => if req.body[key] => t.data[key] = req.body[key]
    if req.files.image =>
      (e,img) <- lwip.open req.files.image.path, \jpg, _
      if e => 
        console.log "[ERROR] #e"
        return r500 res, "failed to read img file"
      (e,b) <- img.toBuffer \jpg, _
      if e => return r500 res, "failed to get img buffer"
      (e) <- storage.write \img, "org/#org/event/#{req.body.event}", b, _
      if e => return r500 res, "failed to write img to storage: #e"
    (e,k) <- ds.save {key: t.key, data: t.data}, _
    if e => return r500 res, "failed to update event information"
    event-store.data.{}[org][req.params.id] = t.data
    res.send!
    backend.multi.clean req, res

  ..get \/event/, (req, res) ->
    org = if req.org => that.name else null
    ret = [v for k,v of event-store.data.{}[org]]
    ret.sort (a,b) -> if a.create_date > b.create_date => 1 else if a.create_date < b.create_date => -1 else 0
    if ret.length > 6 => ret = ret.splice(0,6)
    res.json ret


backend.app
  ..get \/global, aux.type.json, (req, res) ->
    org = if req.org => that.oid else "www"
    ret = [v for k,v of event-store.data[org]]
    ret.sort (a,b) -> if a.create_date > b.create_date => 1 else if a.create_date < b.create_date => -1 else 0
    if ret.length > 6 => ret = ret.splice(0,6)
    # NOTE event might not work since the url is /global ?
    res.render \global.ls, {user: req.user, org: req.org, orgs: org-store.data, events: ret}

backend.app
  ..get \/, (req, res) -> 
    (err, event) <- event-store.get req, _
    if err => return r404 res
    res.render \index.jade, {context: {event: req.event, org: req.org}}
  ..get \/org/, backend.needlogin (req, res) -> res.render \org/list.jade
  ..get \/org/create/, backend.needlogin (req, res) -> res.render \org/create.jade, {context: {org: {}}}
  ..get \/org/detail/, (req, res) -> res.render \org/detail.jade
  ..get \/org/edit/, backend.needlogin (req, res) -> res.render \org/create.jade
  ..get \/event/create/, backend.needlogin (req, res) -> res.render \event/create.jade
  ..get \/e/:event/edit/, backend.needlogin (req, res) ->
    res.render \event/create.jade, {context: {event: req.{}event}}
  ..get \/e/:event/, (req, res) ->
    res.render \index.jade, {context: {event: req.event}}

  ..get \/e/:event/pic, (req, res) -> # get event-specific pic list
    query = ds.createQuery <[pic]>
    event = req.params.event
    if event => query = query.filter "event =", event
    # TODO patch h9n and h10n
    if !(event == "h9n" or event == "h10n") =>
      query = query.filter "org =", (req.{}org.oid or "www")
    # TODO dunno why order not work. check it in newer gcloud-node
    #query = query.order \-create_date .limit 100
    offset = if !isNaN(req.query.next) => parseInt(req.query.next) else 0
    if offset => query = query.offset offset
    (e,t,n) <- ds.runQuery query, _
    #console.log e, t, (req.{}.oid or "www"), event
    if e => return r500 res, e
    if !t or !t.length => return r404 res
    if t.length > 100 => t = t.splice 0,100
    next = if t.length < 100 => -1 else (t.length + offset) 
    res.json {next, data: t.map(->it.data)}

org.init backend

backend.start ({db, server, cols})->
  ds := backend.ds
  org.setds ds
  org-store.latest!
  event-store.latest!
