#!/bin/bash
set -eu
export DOCKER_HOST="${DOCKER_HOST:=tcp://10.1.2.2:2376}"
WORKSPACE=${WORKSPACE:=/sharedfolder/github.com/eivantsov/ticketmonster/}

cd $WORKSPACE &> /dev/null

BRANCH=production
git checkout $BRANCH &> /dev/null

function build() {
  echo -e "### Updating git branch '$BRANCH'...\n"
  git pull origin $BRANCH
  SHA1="$(git log --pretty=format:'%h' -n 1)"
  echo -e "### Fetched revision $SHA1\n"


  echo -e "### Running Maven build...\n"
  mvn package #&> /dev/null
  echo -e "### Built ticket-monster.war using maven\n"

  echo -e "### Build and deploy to production using ansible-container...\n"
  cp target/ticket-monster.war misc/Dockerfiles/ticketmonster-ha/ticket-monster.war
  pushd misc/
  docker run -it --rm -v $(pwd):/work/ -e DETACH=1 -e DOCKER_HOST dustymabe/ansible-container --debug run
  popd

  echo -e "### Brought up TicketMonster using ansible-container\n"
  docker ps
}

echo -e "### Polling for updates to git...\n"
while true; do
  git fetch &> build_log.txt
  echo -n '.'
  if [ -s build_log.txt ]; then
    build
    exit
  fi
  sleep 5s
done
