#!/bin/bash

# only run when we have a BALENA_DEVICE_UUID env var
if [[ $BALENA_DEVICE_UUID ]]; then
  # read the refresh token file
  if [[ $REFRESH_TOKEN_FILE ]]; then
    # mount the token folder
    mkdir -p /mnt/data
    mount /dev/mmcblk0p6 /mnt/data

    if [[ -f "$REFRESH_TOKEN_FILE" ]]; then
      echo "found refresh token file at $REFRESH_TOKEN_FILE";
      export REFRESH_TOKEN=`cat $REFRESH_TOKEN_FILE`
    else
      echo "refresh token file $REFRESH_TOKEN_FILE not found"
    fi
  else
    echo "REFRESH_TOKEN_FILE env var not set"
  fi

  if [[ $REFRESH_TOKEN ]] && [[ $NOTIFY_URL ]]; then
    curl -X POST \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $REFRESH_TOKEN" \
      -d "{ \"uuid\": \"$BALENA_DEVICE_UUID\" }" \
      $NOTIFY_URL

    echo "notified API at $NOTIFY_URL"
  else
    echo "no REFRESH_TOKEN or no NOTIFY_URL set"
    echo "NOTIFY_URL: $NOTIFY_URL"
  fi
else
  echo "BALENA_DEVICE_UUID env var not set"
fi
