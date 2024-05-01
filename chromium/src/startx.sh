#!/usr/bin/env bash

echo "--- List Input Devices ---"
xinput list
echo "----- End of List --------"

function reverse_window_coordinates () {
  local INPUT=$1

  IFS=', ' read -a coords <<< $INPUT
  if [ ${#coords[@]} -eq 2 ]; then
    echo "${coords[1]},${coords[0]}"
  else
    echo "Screen coordinates not set correctly, so cannot reverse them."
  fi
}

function rotate_touch () {
  echo "Rotating Input ($1): $2"
  local TRANSFORM='Coordinate Transformation Matrix'

  case "$2" in
    normal)   xinput set-prop "$1" "$TRANSFORM" 1 0 0 0 1 0 0 0 1;;
    inverted) xinput set-prop "$1" "$TRANSFORM" -1 0 1 0 -1 1 0 0 1;;
    left)     xinput set-prop "$1" "$TRANSFORM" 0 -1 1 1 0 0 0 0 1;;
    right)    xinput set-prop "$1" "$TRANSFORM" 0 1 0 -1 0 1 0 0 1;;
  esac
}

if [[ -z "$WINDOW_SIZE" ]]; then
  # detect the window size from the framebuffer file
  echo "Detecting window size from framebuffer"
  export WINDOW_SIZE=$( cat /sys/class/graphics/fb0/virtual_size )
  echo "Window size detected as $WINDOW_SIZE"
else
  echo "Window size set by environment variable to $WINDOW_SIZE"
fi

if [[ -z "$WINDOW_POSITION" ]]; then
  export WINDOW_POSITION="0,0"
fi

# rotate screen if env variable is set [normal, inverted, left or right]
if [[ ! -z "$ROTATE_DISPLAY" ]]; then
  sleep 3 && xrandr -o $ROTATE_DISPLAY

  #If the display is rotated to left or right, we need to reverse the size and position coords
  if [[ "$ROTATE_DISPLAY" == "left" ]] || [[ "$ROTATE_DISPLAY" == "right" ]]; then

    echo "Display rotated to portait. Reversing screen coordinates"

    #window size
    REVERSED_SIZE="$(reverse_window_coordinates $WINDOW_SIZE)"
    WINDOW_SIZE=$REVERSED_SIZE
    echo "Reversed window size: $WINDOW_SIZE"

    #window position, if set
    if [[ "$WINDOW_POSITION" -ne "0,0" ]]
    then
      REVERSED_POSITION="$(reverse_window_coordinates $WINDOW_POSITION)"
      export WINDOW_POSITION=$REVERSED_POSITION
      echo "Reversed window position: $WINDOW_POSITION"
    fi
  fi

  echo "Rotate Touch Inputs"
  if [[ ! -z "$TOUCHSCREEN" ]]; then
    rotate_touch "$TOUCHSCREEN" "$ROTATE_DISPLAY"
  else
    devices=$( xinput --list | fgrep Touch | sed -E 's/^.*id=([0-9]+).*$/\1/' )
    for device in ${devices} ;do
        rotate_touch $device $ROTATE_DISPLAY
    done
  fi
fi

# these two lines remove the "restore pages" popup on chromium.
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /data/chromium/'Local State' > /dev/null 2>&1 || true
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/; s/"exit_type":"[^"]\+"/"exit_type":"Normal"/' /data/chromium/Default/Preferences > /dev/null 2>&1 || true

# Set chromium version into an EnVar for later
export VERSION=`chromium-browser --version`
echo "Installed browser version: $VERSION"

# stop the screen blanking
xset s off -dpms

# read the refresh token file
if [[ $REFRESH_TOKEN_FILE ]]; then
  if [[ -f "$REFRESH_TOKEN_FILE" ]]; then
    export REFRESH_TOKEN=`cat $REFRESH_TOKEN_FILE`
  fi
fi

if [[ $REFRESH_TOKEN ]]; then
    export DISPLAY_URL="$DISPLAY_URL?token=$REFRESH_TOKEN"
fi

export LAUNCH_URL="file:///home/chromium/index.html?url=${DISPLAY_URL}"

/usr/bin/chromium-browser \
  --disable-features=TranslateUI \
  --disable-component-extensions-with-background-pages \
  --disable-background-networking \
  --disable-sync \
  --metrics-recording-only \
  --disable-default-apps \
  --no-default-browser-check \
  --no-first-run \
  --disable-backgrounding-occluded-windows \
  --disable-renderer-backgrounding \
  --disable-background-timer-throttling \
  --force-fieldtrials=*BackgroundTracing/default/ \
  --window-size="$WINDOW_SIZE" \
  --window-position="$WINDOW_POSITION" \
  --autoplay-policy=no-user-gesture-required \
  --noerrdialogs \
  --disable-session-crashed-bubble \
  --check-for-update-interval=31536000 \
  --disable-dev-shm-usage \
  --noerrdialogs \
  --disable-session-crashed-bubble \
  --high-dpi-support=0 \
  --hide-scrollbars \
  --enable-zero-copy \
  --num-raster-threads=4 \
  --ignore-gpu-blocklist \
  --enable-gpu-rasterization \
  --app="$LAUNCH_URL"

