#!/bin/bash -e

emacs -Q --batch -L . -l archive-contents \
  --eval "(let ((all (shmelpa-all-contents))
                (specific shmelpa--outliers-check-pkg)) \
            (shmelpa-doctor-contents shmelpa-ingested-file shmelpa-staging-file \
               shmelpa-final-file :at-most 1 :specific specific))"
