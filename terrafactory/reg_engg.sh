eng_name=$1
payload='{ 
    "name": "'$1'",
    "hostname": "'$1'",
    "username": "admin",
    "password": "delphix",
    "insecure_ssl": true
}'
echo $payload
curl -X 'POST' \
  'https://dct101.dlpxdc.co/v3/management/engines' \
  -H 'accept: application/json' \
  -H 'Authorization: apk 1.pvR2JlMe9MEWHHV38yhNPbGMOHV9W1R2iiGYguXXSgskSIlAlyeNxiDmESFGNBLC' \
  -H 'Content-Type: application/json' \
  -d "$payload" -o ../k8s_helm_resource/output.json -k | jq '.'
