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
  payload.fav = 0
  (e,k) <~ ds.save { key: ds.key(\pic, null), data: payload }, _
  if e => r500 res, "failed to add pic"
  # need guessing file type
  (e,img) <- lwip.open req.files.image.path, \jpg, _
  if e => 
    console.log "[ERROR] #e"
    return r500 res, "failed to read img file"
  [w,h] = [img.width!, img.height!]
  [w1,h1] = [1000, h * 1000 / w]
  [w2,h2] = [500, h * 500 / w]
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
    (e,t,n) <- ds.runQuery (ds.createQuery <[pic]>), _
    if e => return r500 res, e
    if !t or !t.length => return r404 res
    res.json t.map(->it.data)

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
    (e,t,n) <- ds.runQuery (ds.createQuery <[pic]> .filter "event =", req.params.id), _
    if e => return r500 res, e
    if !t or !t.length => return r404 res
    res.json t.map(-> it.data)

  ..post \/set/:id, (req, res) -> 
    req.body.set = req.params.id
    upload req, res

backend.app
  ..get \/context, (req, res) -> res.render \backend.ls, {user: req.user}

backend.app
  ..get \/, (req, res) -> res.render \index.jade

backend.start ({db, server, cols})->
  ds := backend.dataset
