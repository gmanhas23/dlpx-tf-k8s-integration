# Start a Session
curl -i -c cookies.txt -X POST -H "Content-Type:application/json" http://engine-gm.dlpxdc.co/resources/json/delphix/session -d '{
    "version":{
        "minor":11,
        "major":1, 
        "micro":16, 
        "type":"APIVersion"
    },
    "type":"APISession"
}'


# Authenticate
curl -i -c cookies.txt -b cookies.txt -X POST -H "Content-Type:application/json" http://engine-gm.dlpxdc.co/resources/json/delphix/login -d '{
    "password":"delphix",
    "type":"LoginRequest",
    "target":"DOMAIN",
    "username":"admin"
}'

container_id=$(echo "$1" | sed 's/[0-9]*-//')
# Take Snapshots
curl -i -b cookies.txt -X POST -H "Content-Type:application/json" http://engine-gm.dlpxdc.co/resources/json/delphix/database/${container_id}/sync -d '{
    "parameters": {
        "resync": false
    },
    "type": "AppDataSyncParameters"
}'
