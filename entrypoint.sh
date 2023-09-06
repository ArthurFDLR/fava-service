#!/bin/bash

service rsyslog start
service cron start

source /app/app.conf
source "$USER_CONF_FILE"

echo "Pulling ledger repository..."
/app/pull_ledger.sh

echo "Starting fava ($REPOSITORY_DIR/$BEAN_FILE)..."
/app/bin/fava $REPOSITORY_DIR/$BEAN_FILE --port $FAVA_PORT