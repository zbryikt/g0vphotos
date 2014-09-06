require! <[fs gcloud]>
storage = gcloud.storage

# NOTE
# gcloud-node doesn't bring predefinedAcl parameter
# ( check gcloud-node/lib/storage/index.js : 
#   function Bucket.prototype.getWritableStream_, line 426, qs object
# )
# we need a patch that add "predefinedAcl: 'publicRead' in qs object

KEYFILE = \/Users/tkirby/.ssh/google/g0vphotos/key.json
bucket = {}
<[raw medium thumb]>map ->
  config = {bucketName: "#it.g0v.photos"}
  if fs.exists-sync KEYFILE => config = config <<< {keyFilename: KEYFILE}
  bucket[it] = new storage.Bucket config

base = do
  write: (type, name, data, cb) ->
    bucket[type].write "#name", {
      data: data
      metadata: {contentType: "image/jpg"}
    }, (e) -> cb e
  
  id: (data) ->
    p = parseInt(crypto.createHash(\md5).update(JSON.stringify(data)).digest(\hex),16).toString(36)
    new Date!getTime!toString(37) + parseInt(2000000 + 8000000 * Math.random!)toString(36) + p
  local-file: ->
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

module.exports = base
