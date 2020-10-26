#!/bin/bash

function bold()
{
    echo -e "\033[1m${1}\033[22m"
}

function dim()
{
    echo -e "\033[2m${1}\033[22m"
}

function italic()
{
    echo -e "\033[3m${1}\033[23m"
}

function underline()
{
    echo -e "\033[4m${1}\033[24m"
}

function red()
{
    echo -e "\033[31m${1}\033[39m"
}

function green()
{
    echo -e "\033[32m${1}\033[39m"
}

PE_CONSOLE=$1

if [[ -z "${PE_CONSOLE}"  ]];then
  echo "Usage: $0 [pe-console-fqdn]"
  exit 2
fi

bold "Aquiring token"
type_header='Content-Type: application/json'
uri="https://${PE_CONSOLE}:4433/rbac-api/v1/auth/token"
data='{"login": "admin", 
       "password": "pie"}'

response=$(curl -s --insecure --header "$type_header" --request POST "$uri" --data "$data")
token=$(echo $response | cut -d\" -f4)

# /pdb/query/v4/nodes

type_header='Content-Type: application/json'
uri="https://${PE_CONSOLE}:8081/pdb/query/v4/nodes"
data='X-Authentication:'"$token"
echo $data

response=$(curl -s --insecure --header "$type_header" --header $data --request POST "$uri")
echo $response 
node='average-summer.delivery.puppetlabs.net'
# bold "Classifier call for node=$node"
# dim "curl -k -X GET https://${PE_CONSOLE}:4433/classifier-api/v2/classified/nodes/${node}\?token\=${token}"
# curl -k -X GET https://${PE_CONSOLE}:4433/classifier-api/v2/classified/nodes/${node}\?token\=${token}

bold "Orchestration call check"
auth_header="X-Authentication: $token"
uri="https://${PE_CONSOLE}:8143/orchestrator/v1/jobs"

curl --insecure --header "$auth_header" "$uri"