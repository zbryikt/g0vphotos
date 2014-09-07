require! <[fs]>

data = JSON.parse(fs.read-file-sync \current.json .toString!)
d = data.0.create_date
console.log d
console.log new Date d
