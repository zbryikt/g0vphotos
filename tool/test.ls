require! <[fs gcloud]>

datastore = gcloud.datastore

ds = new datastore.Dataset do
  projectId: \keen-optics-617
  #keyFilename: \/Users/tkirby/.ssh/google/g0vphotos/key.json

query = ds.createQuery <[test]> 
query.filter "fieldb =", "qw" 
query.order \+fielda

console.log query
(e,t,n) <- ds.runQuery query, _
console.log e,t,n
console.log t
