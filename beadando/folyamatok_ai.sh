#!/bin/sh

INDULO="indulo.dat"
AKTUALIS="aktualis.dat"

# Ha még nem létezik az aktuális fájl, létrehozzuk az indulóból
if [ ! -f "$AKTUALIS" ]; then
    if [ -f "$INDULO" ]; then
        cp "$INDULO" "$AKTUALIS"
    else
        touch "$AKTUALIS"
    fi
fi

case "$1" in
    --start)
        if [ -z "$2" ]; then
            printf "Hiba: Adja meg az alkalmazás nevét!\n"
            exit 1
        fi
        
        # Új PID generálása (a legnagyobb jelenlegi PID + 1)
        if [ ! -s "$AKTUALIS" ]; then
            PID=1000
        else
            PID=$(awk '{print $1}' "$AKTUALIS" | sort -rn | head -n 1)
            PID=$((PID + 1))
        fi
        
        # Hozzáadás a fájl végéhez 'S' státusszal
        printf "%s %s S\n" "$PID" "$2" >> "$AKTUALIS"
        printf "Folyamat elindítva: %s (PID: %s)\n" "$2" "$PID"
        ;;
        
    --stop)
        if [ -z "$2" ]; then
            printf "Hiba: Adja meg a PID számot!\n"
            exit 1
        fi
        
        awk -v p="$2" '{if ($1 == p && $3 == "S") $3="T"; print $0}' "$AKTUALIS" > tmp_akt.dat && mv tmp_akt.dat "$AKTUALIS"
        printf "Folyamat (%s) terminálva (T státusz).\n" "$2"
        ;;
        
    --kill)
        if [ -z "$2" ]; then
            printf "Hiba: Adja meg a PID számot!\n"
            exit 1
        fi
        
        grep -v "^$2 " "$AKTUALIS" > tmp_akt.dat && mv tmp_akt.dat "$AKTUALIS"
        printf "Folyamat (%s) véglegesen törölve a listából.\n" "$2"
        ;;
        
    --lista)
        printf "PID\tNÉV\t\tSTÁTUSZ\n"
        printf "--------------------------------\n"
        cat "$AKTUALIS"
        ;;
        
    *)
        printf "Használat: %s {--start <alkalmazás> | --stop <PID> | --kill <PID> | --lista}\n" "$0"
        exit 1
        ;;
esac