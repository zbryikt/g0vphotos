require! <[lwip ./storage]>
require! aux: './backend/aux'
console.log aux

read-img = (file, res, cb) ->
  console.log file
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
    api.get \/org/, (req, res) ->
      (e,t,n) <- ds.runQuery (ds.createQuery <[org]> .filter "oid =", oid), _
      if e or !t => return aux.r500 res, "failed to query org"
      # TODO pagination
      res.json t.map -> it.data

    api.post \/org/, backend.multi.parser, (req, res) ->
      # TODO validation
      data = req.body
      oid = data.oid
      (e,t,n) <- ds.runQuery (ds.createQuery <[org]> .filter "oid =", oid), _
      if e or !t => return aux.r500 res, "failed to query org"
      if t.length => return aux.r400 res
      (e,k) <- ds.save {key: ds.key(\org, null), data}, _
      console.log req.files.banner.path
      console.log req.files.avatar.path
      (b) <- read-img req.files.banner.path, res, _
      (e) <- storage.write \img, "org/b/#oid", b, _
      if e => return aux.r500 res, "failed to write img to storage: #e"
      (b) <- read-img req.files.avatar.path, res, _
      (e) <- storage.write \img, "org/a/#oid", b, _
      if e => return aux.r500 res, "failed to write img to storage: #e"
      res.send!
      backend.multi.clean req, res

    api.get \/org/#id/, (req, res) ->
      (e,t,n) <- ds.runQuery (ds.createQuery <[org]> .filter "oid =", oid), _
      if e or !t => return aux.r500 res, "failed to query org"
      if !t.length => return aux.r400 res
      res.json t.0.data

    api.put \/org/#id/, backend.multi.parser, (req, res) ->
      key = req.params.id
      if !key => return aux.r404 res
      # TODO validation
      data = req.body
      (e,k) <- ds.save ds.key(\org, key), {data}, _
      res.send!
      backend.multi.clean req, res

    api.delete \/org/#id/, (req, res) ->
      (e,t,n) <- ds.runQuery (ds.createQuery <[org]> .filter "oid =", oid), _
      if e or !t => return aux.r500 res, "failed to query org"
      if !t.length => return aux.r404 res
      (e,k) <- ds.delete t.0.key
      if e => return aux.r500 res, "failed to delete org"
      res.send!
