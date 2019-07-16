#!/bin/bash

get_latest_kubespray_minor() {

  set -o pipefail

  LATEST_MINOR=$1

  until TAGS=$(curl -s https://api.github.com/repos/kubernetes-sigs/kubespray/releases | jq -r .[].tag_name | sort -Vr); do sleep 10; done
  export TAGS

  # Get latest of each minor
  LATEST=""
  NUMBER=1
  for i in $TAGS; do
    i=$(echo $i | sed 's/v//g')
    MAJOR=$(echo $i | cut -d . -f 1)
    MINOR=$(echo $i | cut -d . -f 2)
    MICRO=$(echo $i | cut -d . -f 3)

    if [ "${MAJOR}.${MINOR}" == "$LATEST" ]; then
      continue
    fi
    LATEST="${MAJOR}.${MINOR}" 
    if [ "$LATEST_MINOR" == "$NUMBER" ]; then
      echo v${MAJOR}.${MINOR}.${MICRO}
      break
    fi

    NUMBER=$(echo ${NUMBER} + 1 | bc )
  done

}

export -f get_latest_kubespray_minor
