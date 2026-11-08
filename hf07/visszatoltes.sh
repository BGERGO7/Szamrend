#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

PROBA=0
BACKUP_ARG=""
TARGET_DIR=""

# Paraméterek feldolgozása
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --proba) PROBA=1; shift ;;
        --legutobbi) BACKUP_ARG="--legutobbi"; shift ;;
        *)
            if [[ -z "$BACKUP_ARG" ]]; then
                BACKUP_ARG="$1"
            elif [[ -z "$TARGET_DIR" ]]; then
                TARGET_DIR="$1"
            else
                echo "Ismeretlen paraméter: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Ha nincsenek argumentumok, kilistázzuk a mappában elérhető mentéseket
if [[ -z "$BACKUP_ARG" || -z "$TARGET_DIR" ]]; then
    echo "Használat: $0 [--proba] <mentés_neve.tar.gz | --legutobbi> <cél_könyvtár>"
    echo -e "\nElérhető mentések az aktuális könyvtárban:"
    shopt -s nullglob
    for meta in mentes-*.meta; do
        ARCHIVE_NAME="${meta%.meta}"
        if [[ -f "$ARCHIVE_NAME" ]]; then
            SIZE=$(grep "^Méret:" "$meta" | cut -d' ' -f2)
            DATE=$(grep "^Dátum:" "$meta" | cut -d' ' -f2-)
            echo " - $ARCHIVE_NAME (Méret: $SIZE, Készült: $DATE)"
        fi
    done
    exit 0
fi

# Mentés kiválasztása
if [[ "$BACKUP_ARG" == "--legutobbi" ]]; then
    shopt -s nullglob
    BACKUPS=( mentes-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9].tar.gz )
    if (( ${#BACKUPS[@]} == 0 )); then
        echo "HIBA: Nem található mentés az aktuális könyvtárban."
        exit 1
    fi
    BACKUP_FILE="${BACKUPS[-1]}" # A legutolsó elem a legújabb
else
    BACKUP_FILE="$BACKUP_ARG"
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "HIBA: A megadott mentés nem található: $BACKUP_FILE"
    exit 1
fi

# 1. SHA256 ellenőrzés
echo "Ellenőrzőösszeg (sha256) validálása a(z) $BACKUP_FILE fájlhoz..."
if ! sha256sum -c "${BACKUP_FILE}.sha256"; then
    echo "HIBA: Az ellenőrzőösszeg nem egyezik! Az archívum SÉRÜLT vagy módosították."
    exit 1
fi
echo "✓ Ellenőrzőösszeg rendben."

# 2. Célkönyvtár felkészítése és felülírás-védelem
if [[ ! -d "$TARGET_DIR" ]]; then
    if (( PROBA == 0 )); then
        mkdir -p "$TARGET_DIR"
    else
        echo "[PRÓBA] Létrehoznám a célkönyvtárat: $TARGET_DIR"
    fi
fi

if [[ -d "$TARGET_DIR" ]] && [[ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]]; then
    echo -n "FIGYELEM: A célkönyvtár ($TARGET_DIR) nem üres! A folyamat felülírhat fájlokat. Folytatja? (i/n): "
    read -r valasz
    if [[ "$valasz" != "i" && "$valasz" != "I" && "$valasz" != "igen" ]]; then
        echo "Visszatöltés megszakítva a felhasználó kérésére."
        exit 0
    fi
fi

# 3. Visszatöltés (vagy próba)
if (( PROBA == 1 )); then
    echo "--- PRÓBA MÓD (--proba) ---"
    echo "A következő fájlok lennének kibontva a(z) $TARGET_DIR könyvtárba:"
    tar -tzf "$BACKUP_FILE"
else
    echo "Visszatöltés folyamatban a(z) $TARGET_DIR könyvtárba..."
    if tar -xzf "$BACKUP_FILE" -C "$TARGET_DIR"; then
        echo "✓ Visszatöltés sikeresen befejeződött."
    else
        echo "HIBA történt a visszatöltés közben."
        exit 1
    fi
fi