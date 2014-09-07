require! <[fs gcloud]>

data = JSON.parse(fs.read-file-sync \current.json .toString!)
d = data.0.create_date
console.log d
console.log new Date d

datastore = gcloud.datastore

ds = new datastore.Dataset do
  projectId: \keen-optics-617
  #keyFilename: \/Users/tkirby/.ssh/google/g0vphotos/key.json

query = ds.createQuery <[pic]> 
query = query.order \author

console.log query
(e,t,n) <- ds.runQuery query, _
console.log e,t,n
