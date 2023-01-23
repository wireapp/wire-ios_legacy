#!/bin/sh
set -x
if [[ ${DATADOG_IMPORT} -eq 1 ]]; then
    echo "KEEP COPY OF DATADOG FRAMEWORK";
else
    echo "REMOVE TRACE OF DATADOG FRAMEWORK";
    rm -rf $BUILT_PRODUCTS_DIR/$FRAMEWORKS_FOLDER_PATH/Datadog.framework
fi
