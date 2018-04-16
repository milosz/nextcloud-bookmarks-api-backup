#!/bin/bash
# Download NextCloud bookmarks
# https://blog.sleeplessbeastie.eu/2018/04/18/how-to-backup-and-restore-nextcloud-bookmarks/

# current date and time
current_datetime="$(date +%Y%m%d_%H%M%S)"

# usage info
usage(){
  echo "Usage:"
  echo "  $0 -r nextcloud_url -u username -p passsword [-f filename|-t]"
  echo ""
  echo "Parameters:"
  echo "  -r nextcloud_url   : set NextCloud URL (required)"
  echo "  -u username        : set username (required)"
  echo "  -p password        : set password (required)"
  echo "  -f filename        : set filename w/o suffix (optional)"
  echo "  -t                 : add timestamp to output filename (optional)"
  echo ""
}

# parse parameters
while getopts "r:u:p:f:t" option; do
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
      param_filename="${OPTARG}"
      param_filename_defined=true
      ;;
    "t")
      param_date_prefix=true
      ;;
    \?|:|*)
      usage
      exit
      ;;
  esac
done

if [ "${param_nextcloud_address_defined}" = true ] && \
   [ "${param_username_defined}"          = true ] && \
   [ "${param_password_defined}"          = true ]; then

  if [ "${param_filename_defined}" = true ]; then
    filename="${param_filename}"
  else
    filename="nextcloud-bookmarks"
  fi

  if [ "${param_date_prefix}" = true ]; then
    filename="${filename}-${current_datetime}.html"
  else
    filename="${filename}.html"
  fi

  result=$(curl --silent --output - -X GET --user "${param_username}:${param_password}" --header "Accept: application/json" "${param_nextcloud_address}/apps/bookmarks/public/rest/v2/bookmark" | \
           jq -r 'select(.status != "success") | .status')
  if [ -n "${result}" ]; then
    echo "There was an error \"${result}\' when downloading NextCloud bookmarks for user ${param_username}. Skipping."
  else
    curl --silent --output "${filename}"  -X GET --user "${param_username}:${param_password}"  "${param_nextcloud_address}/apps/bookmarks/public/rest/v2/bookmark/export"
    echo "Downloaded NextCloud bookmarks to file \"${filename}\""
  fi
else
  usage
fi
