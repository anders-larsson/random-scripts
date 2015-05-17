#!/bin/bash

for flashplugin in /usr/lib32/nsbrowser/plugins/libflashplayer.so /usr/lib64/nsbrowser/plugins/libflashplayer.so; do
  if [[ -f ${flashplugin} ]]; then
    sed -i.orig -re s/_NET_ACTIVE_WINDOW/XNET_ACTIVE_WINDOW/ \
      ${flashplugin}
  else
    echo $flashplugin missing
  fi
done
