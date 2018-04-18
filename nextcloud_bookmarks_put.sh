#!/bin/bash
# Upload and restore Nextcloud bookmarks
# https://blog.sleeplessbeastie.eu/2018/04/18/how-to-backup-and-restore-nextcloud-bookmarks/

# temporary file to store cookie
cookie_file=$(mktemp)

# delete temporary file on exit
trap "unlink $cookie_file" EXIT

# usage info
usage(){
  echo "Usage:"
  echo "  $0 -r nextcloud_url -u username -p passsword -f json_board_file"
  echo ""
  echo "Parameters:"
  echo "  -r nextcloud_url   : set Nextcloud URL (required)"
  echo "  -u username        : set username (required)"
  echo "  -p password        : set password (required)"
  echo "  -f file            : exported bookmarks (required)"
  echo ""
}

# parse parameters
while getopts "r:u:p:f:" option; do
  case $option in
    "r")
      param_nextcloud_address="${OPTARG}"
      param_nextcloud_address_defined=true
      ;;
    "u")
      param_username="${OPTARG}"
      param_username_defined=true
      ;;
    "p")
      param_password="${OPTARG}"
      param_password_defined=true
      ;;
    "f")
      param_file="${OPTARG}"
      param_file_defined=true
      ;;
    \?|:|*)
      usage
      exit
      ;;
  esac
done

if [ "${param_nextcloud_address_defined}" = true ] && \
   [ "${param_username_defined}"          = true ] && \
   [ "${param_password_defined}"          = true ] && \
   [ "${param_file_defined}"              = true ] && \
   [ -f "${param_file}"                          ]; then

  request_token=$(curl -c ${cookie_file} --silent --location  -X GET --user "${param_username}:${param_password}" "${param_nextcloud_address}/apps/bookmarks/bookmark/" | grep "data-requesttoken" | sed "s/.*<head.*\"\(.*\)\">/\1/")

  result=$(curl -b ${cookie_file} --silent --header "OCS-REQUEST: true" --header "requesttoken: ${request_token}" -F "bm_import=@./${param_file};type=text/html" --location -X POST --user "${param_username}:${param_password}" --header 'Accept: application/json' "${param_nextcloud_address}/index.php/apps/bookmarks/bookmark/import" | jq -r 'select(.status != "success") | .status')
  if [ -n "${result}" ]; then
    echo "There was an error \"${result}\". Skipping."
  else
    echo "Uploaded Nextcloud bookmarks from file \"${param_file}\""
  fi
else
  usage
fi
