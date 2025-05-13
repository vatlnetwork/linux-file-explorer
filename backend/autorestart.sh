#!/bin/sh

# this requires a linux system in order to run
while true; do
  echo "-------------------------------------------------------------------------------------------"
  # Compile the application
  go build
  
  # Start the application in background
  $@ &
  PID=$!
  echo "PID: $PID"
  
  # Wait for either file changes or process exit
  # Using a temporary file for communication
  TMP_STATUS=$(mktemp)
  
  # Start file monitoring in background
  (inotifywait -r -e modify . && echo "MODIFIED" > $TMP_STATUS && kill -TERM $PID 2>/dev/null) &
  INOTIFY_PID=$!
  
  # Wait for the main process to terminate
  wait $PID
  EXIT_CODE=$?

  echo "-------------------------------------------------------------------------------------------"
  
  # Kill file watcher if it's still running
  kill $INOTIFY_PID 2>/dev/null || true
  
  # Check why we terminated
  if [ -f $TMP_STATUS ] && [ "$(cat $TMP_STATUS)" = "MODIFIED" ]; then
    echo "Files changed, restarting..."
  elif [ $EXIT_CODE -eq 0 ]; then
    echo "Process exited with code 0, terminating autorestart"
    rm $TMP_STATUS
    exit 0
  else
    echo "Process crashed or terminated with code $EXIT_CODE"
    echo "Waiting for file changes before restarting..."
    
    # Wait for file changes before restarting
    inotifywait -r -e modify .
    echo "Files changed, restarting..."
  fi
  
  # Clean up
  rm $TMP_STATUS
  rm golang-web-core 2>/dev/null || true

  clear
done
