var themis2Password = "CYGNUS_MONGO_PASS"

rs.initiate({
  _id: "rs0",
  members: [{ _id: 0, host: "mongodb:27017" }]
})

db = db.getSiblingDB("admin")

db.createUser({
  user: "themis2",
  pwd: themis2Password,
  roles: [{ role: "readWrite", db: "sth_themis2" }]
})

db = db.getSiblingDB("sth_themis2")

db.createCollection("sth_x002f")
db.sth_x002f.createIndex({ location: "2dsphere" })
