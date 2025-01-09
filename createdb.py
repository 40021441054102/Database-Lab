from CODB.RKDBH.Queries import *
from CODB.RKDBH.DBH import *

db = DBHandler(
    "qssl",
    "1234",
    "postgres",
    "localhost"
)
db.connect()
# db.execQuery(Queries.Table.Add("galaxy_types"))
db.addAllTables()
# db.execQuery(Queries.Table.Add("galaxies"))
db.disconnect()
print()