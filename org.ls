require! <[lwip ./storage]>
require! aux: './backend/aux'

read-img = (file, res, cb) ->
  (e,img) <- lwip.open file, \jpg, _
  if e => return aux.r500 res, "failed to read img file"
  (e,b) <- img.toBuffer \jpg, _
  if e => return aux.r500 res, "failed to get img buffer"
  cb b

ds = null

module.exports = do
  setds: -> ds := it
  init: (backend) ->
    api = backend.router.api

    backend.app.get \/org/:id/, (req, res) ->
      oid = req.params.id
      if !oid => return aux.r404 res
      (e,t,n) <- ds.runQuery (ds.createQuery <[org]> .filter "oid =", oid), _
      if e or !t => return aux.r505 res, "failed to get org"
      if !t.length => return aux.r404 res
      res.render \org/detail.jade, {context: {org: t.0}}

    api.get \/org/, (req, res) ->
      (e,t,n) <- ds.runQuery (ds.createQuery <[org]>), _
      if e or !t => return aux.r500 res, "failed to query org"
      # TODO pagination
      res.json t.map -> it.data

    api.post \/org/, backend.multi.parser, (req, res) ->
      if !req.user => return aux.r400 res, "login required"
      # TODO validation
      data = req.body
      oid = data.oid
      data.owner = req.user.username
      if !req.files.banner => return aux.r500 res, "need banner image"
      if !req.files.avatar => return aux.r500 res, "need avatar image"
      (e,t,n) <- ds.runQuery (ds.createQuery <[org]> .filter "oid =", oid), _
      if e or !t => return aux.r500 res, "failed to query org"
      if t.length => return aux.r400 res
      (e,k) <- ds.save {key: ds.key(\org, null), data}, _
      (b) <- read-img req.files.banner.path, res, _
      (e) <- storage.write \img, "org/b/#oid", b, _
      if e => return aux.r500 res, "failed to write img to storage: #e"
      (b) <- read-img req.files.avatar.path, res, _
      (e) <- storage.write \img, "org/a/#oid", b, _
      if e => return aux.r500 res, "failed to write img to storage: #e"
      res.send!
      backend.multi.clean req, res

    api.get \/org/:id/, (req, res) ->
      key = req.params.id
      if !key => return aux.r404 res
      (e,t,n) <- ds.runQuery (ds.createQuery <[org]> .filter "oid =", key), _
      if e or !t => return aux.r500 res, "failed to query org"
      if !t.length => return aux.r400 res
      res.json t.0.data

    api.put \/org/:id/, backend.multi.parser, (req, res) ->
      if !req.user => return aux.r400 res, "login required"
      oid = req.params.id
      data = req.body
      data.oid = oid
      if !oid => return aux.r404 res
      (e,t,n) <- ds.runQuery (ds.createQuery <[org]> .filter "oid =", oid), _
      if e or !t => return aux.r500 res, "failed to query org"
      if !t.length => return aux.r400 res
      olddata = t.0.data
      if req.user.username != olddata.owner => return aux.r403 res
      # TODO validation
      (e,k) <- ds.save {key: ds.key(\org, key), data}, _
      res.send!
      backend.multi.clean req, res

    api.delete \/org/:id/, (req, res) ->
      (e,t,n) <- ds.runQuery (ds.createQuery <[org]> .filter "oid =", oid), _
      if e or !t => return aux.r500 res, "failed to query org"
      if !t.length => return aux.r404 res
      (e,k) <- ds.delete t.0.key
      if e => return aux.r500 res, "failed to delete org"
      res.send!
