#!/bin/bash -e

emacs -Q --batch -L . -l archive-contents \
  --eval "(if-let ((bad (shmelpa-check-deliverables))) (princ (format \"Bad: %s\n\" (mapconcat (function symbol-name) bad \" \")) (function external-debugging-output)) (princ \"All good!\n\" (function external-debugging-output)))"
