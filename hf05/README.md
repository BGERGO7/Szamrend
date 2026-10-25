# --help

Hasznalat: ./logtool.sh -f FAJL [KAPCSOLOK]
Kapcsolok:
  -h, --help       kiirja a hasznalatot es kilep 0-val
  -f, --file FAJL  a feldolgozando log (kotelezo)
  -t, --top N      hany elemet mutasson a toplistakban (alap: 10)
  -s, --status KOD csak az adott statuszkodu sorokat nezze
  -o, --output FAJL a riportot fajlba irja
  -q, --quiet      csak a vegso osszefoglalo sort irja ki

# ./logtool.sh -f access.log

LOG RIPORT
==========
Osszes keres:     4000
Egyedi IP-cimek:     3282

LEGAKTIVABB IP CIMEK (TOP 10)
-------------------------------
193.224.41.77               719
49.98.118.179                 1
49.98.108.29                  1
49.97.245.119                 1
49.92.213.205                 1
49.90.183.47                  1
49.89.31.68                   1
49.76.213.232                 1
49.70.227.79                  1
49.7.78.123                   1

# ./logtool.sh -f access.log -t 5

LOG RIPORT
==========
Osszes keres:     4000
Egyedi IP-cimek:     3282

LEGAKTIVABB IP CIMEK (TOP 5)
-------------------------------
193.224.41.77               719
49.98.118.179                 1
49.98.108.29                  1
49.97.245.119                 1
49.92.213.205                 1