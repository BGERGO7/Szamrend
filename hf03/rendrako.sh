#!/bin/bash

DIR=""
RENDEZETT=0

for arg in "$@"; do
    if [ "$arg" = "--rendezett" ]; then
        RENDEZETT=true
    elif [ -z "$DIR" ]; then
        DIR="$arg"
    fi
done

if [[ -z "$DIR" ]]; then
    echo "Hiba: Nem adtál meg könyvtárat a parancssorban!" >&2
    exit 1
fi

if [[ ! -d "$DIR" ]]; then
    echo "Hiba: A megadott könyvtár ('$DIR') nem létezik!" >&2
    exit 1
fi


f_count=$(find "$DIR" -type f | wc -l)
d_count=$(find "$DIR" -type d | wc -l)
echo "- Fájlok száma: $f_count" 
echo "- Könyvtárak száma: $d_count" 
echo ""

echo "- Az 5 legnagyobb fájl:" 
find "$DIR" -type f -exec du -h {} + 2>/dev/null | sort -rh | head -n 5 
echo ""

old_count=$(find "$DIR" -type f -mtime +30 | wc -l) 
echo "- 30 napnál régebben módosított fájlok száma: $old_count" 
echo ""

echo "- Üres fájlok listája:" 
find "$DIR" -type f -empty 
echo ""

echo "- Fájlok megoszlása kiterjesztés szerint:" 
find "$DIR" -type f -name "*.*" | sed 's/.*\.//' | sort | uniq -c | sort -rn 
echo ""

echo "- Mindenki számára írható fájlok (o+w):" 
find "$DIR" -type f -perm -o+w 
echo ""


if [[ "$RENDEZETT" == true ]]; then
    echo "=== RENDRAKÁS ==="
    echo "Biztonsági öv: Tervezett műveletek listája:"
    echo "1. Létrehozom a '_rendezett/' és az '_egyeb/' mappákat egymás mellé."
    echo "2. A fájlokat kiterjesztésük szerint almappákba MÁSOLOM a '_rendezett/' alá."
    echo "3. A kiterjesztés nélküli fájlok az '_egyeb/' mappába kerülnek."
    echo "4. A mindenki által írható fájlokról (o+w) leveszem a jogot az eredeti helyükön."
    
    # Két külön mappa létrehozása az aktuális könyvtárban
    mkdir -p "_rendezett" "_egyeb"

    find "$DIR" -type f -print0 | while IFS= read -r -d '' f; do
        filename=$(basename "$f")
        ext="${filename##*.}"

        if [[ "$ext" == "$filename" ]] || [[ "$filename" == .* && "$ext" == "${filename:1}" ]]; then
            # Kiterjesztés nélküli fájlok a különálló _egyeb mappába mennek
            dest="_egyeb"
        else
            # Kiterjesztéssel rendelkezők a _rendezett mappa almappáiba
            dest="_rendezett/$ext"
        fi

        mkdir -p "$dest"
        cp "$f" "$dest/"
    done
    echo "Fájlok másolása befejezve."

    echo ""
    echo "Jogosultságok elvétele (o-w):"
    find "$DIR" -type f -perm -o+w -print0 | while IFS= read -r -d '' f; do
        chmod o-w "$f"
        echo "Jog elvéve: $f"
    done
    echo "Rendrakás befejezve."
fi