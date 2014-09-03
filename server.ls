require! <[fs express mongodb body-parser crypto lwip]>
require! <[passport passport-local passport-facebook express-session]>
require! <[nodemailer nodemailer-smtp-transport]>
require! <[./backend]>

r500 = (res, error) -> res.status(500).json({detail:error})
r404 = (res) -> res.status(404)send!
r403 = (res) -> res.status(403)send!
r400 = (res) -> res.status(400)send!
r200 = (res) -> res.send!
OID = mongodb.ObjectID
dbc = {}

<[media media/raw media/thumb src src/ls src/sass static static/css static/js]>.map ->
  if !fs.exists-sync it => fs.mkdir-sync it

config = debug: true

backend.init config

pic = backend.express.Router!
backend.app.use \/s, pic

# handler for add / delete of user's favorite. value: fav(true) / unfav(false)
fav = (value) -> (req, res) ->
  if !req.user => return r403 res
  if !!req.user.{}fav[req.params.id] == value => return res.send!
  (e,p) <- dbc.pic.findOne {_id: OID(req.params.id)}
  if !p => return r400 res
  req.user.{}fav[req.params.id] = value
  (e,r) <- dbc.user.update {_id: OID(req.user._id)}, {$set: {"fav.#{req.params.id}": value}}, {w:1}
  if !r => return r500(res, "failed to update user fav list")
  p.fav = ( p.fav or 0 ) + ( if value => 1 else -1 ) >? 0
  (e,r) <- dbc.pic.update {_id: OID(req.params.id)}, {$set:{fav:p.fav}}, {w:1}
  if !r => return r500(res, "failed to update pic fav count")
  (e,r) <- dbc.user.findOne {_id: OID(req.user._id)}
  backend.update-user req
  r200 res

backend.router.user
  ..get \/fav, (req, res) -> res.json(req.user.fav) # TODO need pagination
  ..put \/fav/:id, fav true
  ..delete \/fav/:id, fav false

pic
  ..get \/pic, (req, res) -> # get all site pic list
    # TODO need pagination
    stream = dbc.pic.find {} .stream!
    backend.stream-writer res, stream

  ..post \/pic, backend.multi.parser, (req, res) -> # upload new pic
    #TODO validation, preventing SQL injection
    if !req.files.image or !req.body.license => return res.status 400 .send!
    (e,r) <- dbc.pic.insert req.body, {w:1}
    if !r or !r.length => r500 res, "failed to add pic"
    r = r.0
    # need guessing file type
    raw = "media/raw/#{r._id}.jpg"
    tmb = "media/thumb/#{r._id}.jpg"
    (e) <- fs.rename req.files.image.path, raw
    if e => 
      console.log "[ERROR] #e"
      return r500 res, "failed to move file"
    (e,img) <- lwip.open raw
    if e => 
      console.log "ERROR] #e"
      return r500 res, "failed to resize file"
    [w,h] = [img.width!, img.height!]
    [w,h] = [500, h * 500 / w]
    img.batch!resize(w,h)writeFile tmb, (->) 
    res.send!
    backend.multi.clean req, res

  ..get \/pic/:id, (req, res) -> # get single pic info
    # TODO both JSON or HTML
    (e,r) <- dbc.pic.findOne {_id: OID(req.params.id)}
    if !r => return r404 res
    #res.json r
    res.render 'share.jade', {pic: r}

  ..get \/set/:id, (req, res) ->
    # need pagination
    stream = dbc.pic.find {set: req.params.id} .stream!
    backend.stream-writer res, stream

  ..post \/set/:id, (req, res) -> 
    data = {} <<< req.body
      ..set = req.params.id
    (e,r) <- dbc.pic.insert data, {w:1}
    if !r => r500 res, "failed to add pic"

backend.app
  ..get \/context, (req, res) -> res.render \backend.ls, {user: req.user}

backend.app
  ..get \/, (req, res) -> res.render \index.jade

backend.start ({db, server, cols})->
  dbc := cols # shortcut for collections
  db.collection \pic, (e, c) -> cols.pic = c
