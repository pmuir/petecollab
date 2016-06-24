#!/bin/bash
set -eu
export DOCKER_HOST='tcp://10.1.2.2:2376'
pushd /sharedfolder/github.com/eivantsov/ticketmonster/

BRANCH=production
git checkout $BRANCH >> /dev/null 2>&1  
echo "### Updating git branch '$BRANCH'...\n"
#git pull
# TODO insert git update commands
SHA1="$(git log --pretty=format:'%h' -n 1)"
echo "### Fetched revision $SHA1\n"
echo "### Running Maven build...\n"
# TODO insert maven command, redirect all output to /dev/null
mvn package #&> /dev/null
echo "### Built ticket-monster.war using maven\n"
echo "### Running Linux container builds...\n"
cp target/ticket-monster.war misc/Dockerfiles/ticketmonster-ha/ticket-monster.war
pushd misc/
docker run -it --rm -v $(pwd):/work/ -e DETACH=1 -e DOCKER_HOST dustymabe/ansible-container --debug run
popd

# TODO insert container builds, redirect all output to /dev/null
echo "Built Linux container for TicketMonster + WildFly\n"
echo "Starting ansible-container to bring up containers in production...\n"
# TODO insert ansible container start, redirect all output to /dev/null
echo "Brought up TicketMonster using ansible-container"
docker ps
popd
exit
