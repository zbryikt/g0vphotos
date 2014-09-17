
key: \key
kind: \org
exists: (req, res, cb) ->
  key = req.params.id
  if !key => return aux.r404 res
  (e,t,n) <- ds.runQuery ds.createQuery([@kind] .filter "#{@key} =", key, _
  if e or !t => return cb e, false, null
  if !t.length => return cb null, false, {}
  return cb null, true, t
create: ->
  # TODO validation
  data = req.body
  key = data[@key]
  (e,t,n) <- ds.runQuery ds.createQuery([@kind] .filter "#{@key} =", key, _
  if e or !t => return aux.r500 res, "failed to query #{@kind}"
  if !t.length => return aux.r400 res
  (e,k) <- ds.save ds.key(@kind, null), {data}, _
  res.send!
retrieve: ->
  key = req.params.id
  if !key => return aux.r404 res
  (e,t,n) <- ds.runQuery ds.createQuery([@kind] .filter "#{@key} =", key, _
  if e or !t => return aux.r500 res, "failed to query #{@kind}"
  if !t.length => return aux.r400 res
  res.json t.0.data
update: ->
  key = req.params.id
  if !key => return aux.r404 res
  # TODO validation
  data = req.body
  (e,k) <- ds.save ds.key(@kind, key), {data}, _
  res.send!
  backend.multi.clean req, res
delete: (req, res) ->
  (e,exist,qset) <~ @exists req, res, _
  if e => return aux.r500 res, "failed to query #kind"
  if !exist => return aux.r404 res
  (e,k) <- ds.delete qset.0.key
  if e => return aux.r500 res, "failed to delete #kind"
  res.send!
