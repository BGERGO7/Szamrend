#!/usr/bin/env bash
# Hasznalat: ./general-log.sh NEPTUN > access.log
set -euo pipefail

SEED="$(printf '%s' "${1:?adj meg egy Neptun-kodot}" | cksum | awk '{print $1}')"
awk -v seed="$SEED" 'BEGIN {
  srand(seed)
  nu = split("/ /index.html /api/v1/users /api/v1/orders /login /admin /static/app.js /kepek/logo.png", ut, " ")
  nm = split("GET GET GET GET POST POST PUT DELETE", md, " ")
  ns = split("200 200 200 200 200 301 404 403 500 502", st, " ")
  for (i = 0; i < 4000; i++) {
    ip = sprintf("%d.%d.%d.%d", 10+int(rand()*40), int(rand()*256), int(rand()*256), 1+int(rand()*254))
    if (rand() < 0.18) ip = "193.224.41.77"
    elapsed = i*17 + int(rand()*11)
    day = 21 + int(elapsed / 86400)
    hour = int(elapsed / 3600) % 24
    minute = int(elapsed / 60) % 60
    second = elapsed % 60
    printf "%s - - [%s] \"%s %s HTTP/1.1\" %s %d %.3f\n", ip,
      sprintf("%02d/Sep/2026:%02d:%02d:%02d +0200", day, hour, minute, second),
      md[int(rand()*nm)+1], ut[int(rand()*nu)+1], st[int(rand()*ns)+1],
      200+int(rand()*90000), rand()*2.5
  }
}'
