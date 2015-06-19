#!/bin/bash

RACKET=$IROOT/racket
RETCODE=$(fw_exists ${RACKET}.installed)
[ ! "$RETCODE" == 0 ] || { \
  # Load environment variables
  source $RACKET.installed
  return 0; }

fw_get -o racket-src.tar.gz http://mirror.racket-lang.org/installers/recent/racket-src.tgz
fw_untar racket-src.tar.gz
mv racket racket-install
cd racket-install/src 
./configure --prefix=$RACKET
make
make install

echo "export RACKET_HOME=${RACKET}" > $RACKET.installed
echo -e "export PATH=${RACKET}/bin:\$PATH" >> $RACKET.installed

source $RACKET.installed
