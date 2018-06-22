#!/usr/bin/env bash

ACTION=$1
CONTAINER_ID=$2

docker-compose kill

function echo_and_run {
  echo "$" "$@"
  eval $(printf '%q ' "$@") < /dev/tty
}

if [ "$ACTION" == "backup" ]; then
  # Determine the volumes for the specified container
  VOLUMES=`docker inspect -f '{{ range .Mounts }}{{ .Name }}:{{ .Destination }};{{end}}' $CONTAINER_ID`

  # Use the ; character to separate the volumes string into an array
  IFS=';' read -ra VOLUMES <<< "$VOLUMES"

  echo "Container $CONTAINER_ID has ${#VOLUMES[@]} volume(s):"

  # Delete any existing backup
  rm -Rf $CONTAINER_ID
  mkdir $CONTAINER_ID

  for VOLUME in "${VOLUMES[@]}"
  do
    echo "  $VOLUME"

    IFS=':' read -ra VOLUME <<< "$VOLUME"

    VOLUME_NAME=${VOLUME[0]}
    VOLUME_DESTINATION=${VOLUME[1]}

    docker run --rm --volumes-from $CONTAINER_ID -v $(pwd)/$CONTAINER_ID:/backup ubuntu tar cf /backup/$VOLUME_NAME.tar $VOLUME_DESTINATION

    echo "$VOLUME_NAME:$VOLUME_DESTINATION" >> $CONTAINER_ID/volumes.txt

  done
fi

if [ "$ACTION" == "restore" ]; then
  IFS=$'\r\n' GLOBIGNORE='*' command eval  "VOLUMES=($(cat $CONTAINER_ID/volumes.txt))"

  echo "Container $CONTAINER_ID has ${#VOLUMES[@]} volume(s):"

  for VOLUME in "${VOLUMES[@]}"
  do
    echo "  $VOLUME"

    IFS=':' read -ra VOLUME <<< "$VOLUME"

    VOLUME_NAME=$(echo ${VOLUME[0]} | cut -d '.' -f1)
    VOLUME_DESTINATION=${VOLUME[1]}

    echo_and_run docker run -v $VOLUME_NAME:$VOLUME_DESTINATION --name $VOLUME_NAME-container ubuntu /bin/bash

    echo_and_run docker run --rm --volumes-from $VOLUME_NAME-container -v $(pwd)/$CONTAINER_ID:/backup ubuntu bash -c "mkdir -p $VOLUME_DESTINATION && cd / && tar xvf /backup/$VOLUME_NAME.tar"

    echo_and_run docker rm $VOLUME_NAME-container
  done
fi
