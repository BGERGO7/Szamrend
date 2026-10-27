#!/bin/sh

INDULO="indulo.dat"
AKTUALIS="aktualis.dat"

if [ ! -f "$AKTUALIS" ]; then
    if [ -f "$INDULO" ]; then
        cp "$INDULO" "$AKTUALIS"
    else
        touch "$AKTUALIS"
    fi
fi

case "$1" in 
    -start)
        if [ -z "$2" ]; then
            echo "Hiba: Adja meg az alkalmazás nevét!"
            exit 1
        fi

        PID=0

        while read -r elso_oszlop _; do
            if [ -n "$elso_oszlop" ] && [ "$elso_oszlop" -gt "$PID" ]; then
                PID=$elso_oszlop
            fi
        done < "$AKTUALIS"

        PID=$((PID + 1))

        echo "$PID $2 S" >> "$AKTUALIS"
        echo "Folyamat elindítva: $2 (PID: $PID)"

        ;;

    -stop)
        if [ -z "$2" ]; then
            echo "Hiba: Adja meg a PID számot!"
            exit 1
        fi

        temp=$(
            while read -r pid nev status; do
                if [ "$pid" = "$2" ] && [ "$status" = "S" ]; then
                    status="T"
                fi
                echo "$pid $nev $status"
            done < "$AKTUALIS"
        )

        echo "$temp" > "$AKTUALIS"
        echo "Folyamat ($2) leállítva (T státusz)."
        ;;

    -kill)
        if [ -z "$2" ]; then
            echo "Hiba: Adja meg a PID számot!"
            exit 1
        fi

        temp=$(
            while read -r pid nev status; do
                if [ "$pid" != "$2" ]; then
                    echo "$pid $nev $status"
                fi
            done < "$AKTUALIS"
        )

        echo "$temp" > "$AKTUALIS"
        echo "Folyamat $2 törölve."
        ;;

    -lista)
        while read -r pid nev status; do
            echo "$pid $nev $status"
        done < "$AKTUALIS"
        ;;
esac