#!/usr/bin/env bash

# usage: bash index.sh -o ~/stack/nginx/html/index.html
cat <(curl -sSL https://raw.githubusercontent.com/commercial-emacs/commercial-emacs/master/README.md) /dev/fd/3 3<<EOF | pandoc -s "$@"


### Are You a UNIX-driven research enterprise?

No, but if *you* are, let us show you how Emacs can be
your soup-to-nuts computing platform.  Pick up the phone,
and call the professionals at Command Line Systems.

<blockquote>
<p>We're ready to believe you.</p>
<p>— <cite>Ghostbusters, 1984</cite></p>

EOF
