#!/bin/bash
set -eu
export DOCKER_HOST="${DOCKER_HOST:=tcp://10.1.2.2:2376}"
WORKSPACE=${WORKSPACE:=/sharedfolder/github.com/eivantsov/ticketmonster/}

cd $WORKSPACE &> /dev/null

BRANCH=production
git checkout $BRANCH &> /dev/null

function build() {
  echo "### Updating git branch '$BRANCH'...\n"
  #git pull
  # TODO insert git update commands
  SHA1="$(git log --pretty=format:'%h' -n 1)"
  echo "### Fetched revision $SHA1\n"
  echo "### Running Maven build...\n"
  # TODO insert maven command, redirect all output to /dev/null
  mvn package #&> /dev/null
  echo "### Built ticket-monster.war using maven\n"

  echo "### Build/Deploy to production using ansible-container...\n"
  cp target/ticket-monster.war misc/Dockerfiles/ticketmonster-ha/ticket-monster.war
  pushd misc/
  docker run -it --rm -v $(pwd):/work/ -e DETACH=1 -e DOCKER_HOST dustymabe/ansible-container --debug run
  popd

  echo "### Brought up TicketMonster using ansible-container\n"
  docker ps
}

echo "### Polling for updates to git...\n"
while true; do
  git fetch &> build_log.txt
  echo "$BRANCH"
  if [ -s build_log.txt ]; then
    build
    exit
  fi
  sleep 5s
done
