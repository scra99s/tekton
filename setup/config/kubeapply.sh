#!/usr/bin/bash

declare workingDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $workingDir/.secrets.ini

##
# The worlds most ghetto templating engine! :)
# param {string} $1 filepath to template yaml file.
function deployTemplate() {
  ( echo "cat <<EOF >final.yml";
    cat $1;
    echo "EOF";
  ) >temp.yml; . temp.yml
  cat final.yml | kubectl.exe apply -f -
  rm temp.yml final.yml
}

deployTemplate "$1"
