require! <[fs gcloud lwip mongodb crypto ../storage]>
datastore = gcloud.datastore

ds = new datastore.Dataset do
  projectId: \keen-optics-617

items = JSON.parse( fs.read-file-sync \current.json )
next = -> setTimeout parse, 0

data = do
  author: \BOOKSHOW
  license: "CC BY 3.0"
  tag: "kp-unlimited,"
  event: ""
  desc: "RGBA × 柯文哲野生官網 unlimited 設計工作營：開場前準備 @ yourspace"
  create_date: new Date("2014-09-06 00:00:00")
  id: \pic1409972207346_18041221168

(e,k) <- ds.save {key: ds.key(\pic, null), data}, _
if e => console.log "[ERROR] fail to save ds: #e"
