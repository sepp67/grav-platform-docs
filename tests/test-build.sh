#!/bin/sh
# Le docker build de l'image applicative réussit.
. "$(dirname "$0")/lib.sh"

log "docker build -t $IMAGE $REPO_ROOT"
docker build -t "$IMAGE" "$REPO_ROOT"
log "build réussi"
