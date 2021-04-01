#!/bin/bash -e

ingest=${1:-}
if [ ! -z "$ingest" ]; then ingest=" $ingest"; fi
emacs -Q --batch -L . -l archive-contents --eval "(shmelpa-doit$ingest)"
if [ ! -e "archive-contents-final" ]; then
	touch "archive-contents-final"
fi
if ! diff -wc archive-contents-final archive-contents-staging ; then
    mv archive-contents-staging archive-contents-final
else
    rm archive-contents-staging
fi
LIVE="/opt/bitnami/nginx/html/packages/archive-contents"
if [ -f $LIVE ]; then
    cp -a archive-contents-final $LIVE
fi
