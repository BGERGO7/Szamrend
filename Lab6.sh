#!/bin/bash

echo "asdsdklmsad"
echo -n "nincs sortores"
echo #csak sortores
echo

printf "nev: %s, kor: %d\n" "Anna" 20

echo "asd" > proba.txt # file-ba iras ATIRJA 
echo "asd2" >> proba.txt #file-ba iras HOZZAADJA

cat proba.txt #fajl olvasas

ls nincs_ilyen_file 2> hiba.txt # hibauzenet csatornaja a 2.
ls nincs_ilyen_file 2> /dev/null #/dev/null egy vegtelen feketelyuk

cat hiba.txt #egesz file
head -2 proba.txt #elso 2 sor 
tail -1 proba.txt # utolso 1 sor 
wc -l proba.txt # hany sor van benne
wc -w proba.txt # hany szo

nev="Anna" # valtozo
echo "A neve $nev" #valtozo szovegbe

mai_datum=$(date + %Y-%m-%d)
echo "ma $mai_date van"

# alapbol felvett parameter valtozok
echo "ennek a scriptnek a neve: $0"
echo "kaptunk $# parametert is"
echo "itt vannak a parametereink: #@"
echo "az elso parameterunk ez: $1"

grep "asd" proba.txt