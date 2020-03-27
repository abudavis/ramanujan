#!/bin/bash

# NAME: ace_config_applybaroverride.sh
# Usage: NA
# INITIAL CREATION DATE:	March 27, 2020
# lAST MODIFIED DATE:	March 27, 2020
# AUTHOR:   www.integrationpattern.com
# DESCRIPTION:
# 	This script generates a new bar file from the baroverride .properties file

if [ -z "$MQSI_VERSION" ]; then
  source /opt/ibm/ace-11/server/bin/mqsiprofile
fi

if ls /home/aceuser/initial-config/bars/*.bar >/dev/null 2>&1; then
  for bar in /home/aceuser/initial-config/bars/*.bar
  do
		echo "---"
		echo $bar
		ls -ltr /home/aceuser/initial-config/bars
		ls -ltr $bar
		echo "---"
    mqsiapplybaroverride -b $bar -p /home/aceuser/initial-config/applybaroverride/*.properties -r
		#-o $bar //snce this flag is absent above input file is overwritten
		ls -ltr /home/aceuser/initial-config/bars
  done
fi
