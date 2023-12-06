refresh.sh
#!/bin/bash

#
# Copyright (c) 2023 by Delphix. All rights reserved.
#

# Check if three arguments are provided
# if [ $# -ne 3 ]; then
#   echo "Usage: $0 DCT_URL API_KEY VDB_NAME"
#   exit 1
# fi

# Assign the input parameters to variables
dct_url=$1
api_key=$2
vdb_name=$3

# Display the values of the parameters
echo "DCT URL: $dct_url"
echo "API KEY: $api_key"
echo "VDB NAME: $vdb_name"

# Construct the URL:
scheme="https://"
api_version="/v3"
baseurl=$scheme$dct_url$api_version

# Construct the Authorization header
fixed_header="Authorization: apk "
auth_header=$fixed_header$api_key
echo "HEADER: $auth_header"

# Get the VDB ID from VDB NAME
forward_path_get_vdb_id="/vdbs/search?limit=50&sort=id&permission=READ"
get_vdb_id_url="$baseurl$forward_path_get_vdb_id"

# Get the request body to get the VDB ID from VDB NAME
get_vdb_id_req_body="{\"filter_expression\": \"name EQ '$vdb_name'\"}"

vdb_name_response=$(curl -X 'POST' "$get_vdb_id_url" -H 'accept: application/json' -H "$auth_header" -H 'Content-Type: application/json' -d "$get_vdb_id_req_body" -k)
if [ $? -ne 0 ]; then
  echo "Error: Failed to make the request to get the VDB ID from VDB NAME"
  exit 1
fi
echo "$vdb_name_response"

vdb_array=$(echo "$vdb_name_response" | jq -r '.items')
vdb_id=$(echo "$vdb_array" | jq -r '.[].id')
source_id=$(echo "$vdb_array" | jq -r '.[].parent_dsource_id')
echo "SOURCE_ID: $source_id"

# Get the SNAPSHOT ID from VDB_ID
forward_path_get_snapshot_id="/snapshots/search?limit=50&sort=-timestamp"
get_snapshot_id_url="$baseurl$forward_path_get_snapshot_id"
snapshot_from_vdb_id_response=$(curl -X 'POST' "$get_snapshot_id_url" -H 'accept: application/json' -H "$auth_header" -H 'Content-Type: application/json' -d '{"filter_expression": "dataset_id EQ '\'$source_id\''"}' -k)
if [ $? -ne 0 ]; then
  echo "Error: Failed to make the request to get the SNAPSHOT ID from the Source ID"
  exit 1
fi

if [ -z $4]; then
  snapshot_array=$(echo "$snapshot_from_vdb_id_response" | jq -r '.items')
  echo "Snapshot array: {$snapshot_array=$}"
  snapshot_id=$(echo "$snapshot_array" | jq -r '.[0].id')
  echo "Snapshot id for dsource: {$snapshot_id=$}"
else
  snapshot_id=$4
fi
echo "SNAPSHOT_ID: $snapshot_id"

# refresh the vdb to the latest snapshot
forward_path_vdb="/vdbs/"
forward_path_refresh="/refresh_by_snapshot"
refresh_url="$baseurl$forward_path_vdb$vdb_id$forward_path_refresh"

refresh_request_body="{\"snapshot_id\": \"$snapshot_id\"}"
echo "$refresh_request_body"

refresh_response=$(curl -X 'POST' "$refresh_url" -H 'accept: application/json' -H "$auth_header" -H 'Content-Type: application/json' -d "$refresh_request_body" -k)
if [ $? -ne 0 ]; then
  echo "Error: Failed to make the request to refresh the VDB to a latest SNAPSHOT"
  exit 1
fi

echo "REFRESH_RESPONSE: $refresh_response"
