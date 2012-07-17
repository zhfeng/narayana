#!/bin/sh

if [ "x"$JBOSS_HOME = "x" ]; then
	echo "set JBOSS_HOME first"
	exit
fi

./build.sh clean install -DskipTests
./build.sh -f XTS/localjunit/pom.xml --projects xtstest,crash-recovery-tests -Parq "$@" clean install -Dtest=TestATCrashDuringCommit#MultiParticipantPrepareAndCommitTest
