#!/bin/bash -x

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

type_header='Content-Type: application/json'
uri="https://${PE_CONSOLE}:8143/orchestrator/v1/jobs?limit=1&offset=2"
data='X-Authentication:'"$token"
echo $data

response=$(curl -s --insecure --header "$type_header" --header $data "$uri")
echo $response 
