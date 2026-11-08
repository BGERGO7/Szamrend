#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SOURCE_DIR="${1:-}"
TARGET_DIR="${2:-}"
RETENTION="${3:-7}"

if [[ -z "$SOURCE_DIR" || -z "$TARGET_DIR" ]]; then
    echo "Használat: $0 <forrás_könyvtár> <cél_könyvtár> [retenció_szám]"
    exit 1
fi

# Abszolút útvonalak generálása
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "HIBA: A forráskönyvtár ($SOURCE_DIR) nem létezik!"
    exit 1
fi
SOURCE_DIR=$(realpath "$SOURCE_DIR")

mkdir -p "$TARGET_DIR"
TARGET_DIR=$(realpath "$TARGET_DIR")
LOG_FILE="${TARGET_DIR}/mentes.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 1. Zárolás (flock)
exec 9>"${TARGET_DIR}/.mentes.lock"
if ! flock -n 9; then
    log "FIGYELMEZTETÉS: A mentés már fut egy másik példányban. Kilépés."
    exit 0 
fi

# 2. Archívum elkészítése
TIMESTAMP=$(date +%Y-%m-%d-%H%M)
ARCHIVE_NAME="mentes-${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${TARGET_DIR}/${ARCHIVE_NAME}"

log "Mentés kezdése: $SOURCE_DIR -> $ARCHIVE_PATH"

if tar -czf "$ARCHIVE_PATH" -C "$SOURCE_DIR" .; then
    log "Archívum sikeresen létrehozva."
else
    log "HIBA: Az archívum létrehozása sikertelen."
    exit 1
fi

# 3. Ellenőrzőösszeg és Meta fájl
cd "$TARGET_DIR" || exit 1

sha256sum "$ARCHIVE_NAME" > "${ARCHIVE_NAME}.sha256"
log "Ellenőrzőösszeg (sha256sum) generálva."

FILE_COUNT=$(find "$SOURCE_DIR" -type f | wc -l)
ARCHIVE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)

cat <<EOF > "${ARCHIVE_NAME}.meta"
Dátum: $(date '+%Y-%m-%d %H:%M:%S')
Méret: $ARCHIVE_SIZE
Fájlok száma: $FILE_COUNT
EOF
log "Meta adatfájl létrehozva."

# 4. Retenció kezelése (glob használatával a ShellCheck miatt, ls parse helyett)
shopt -s nullglob
BACKUPS=( mentes-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9].tar.gz )
TOTAL_BACKUPS=${#BACKUPS[@]}

if (( TOTAL_BACKUPS > RETENTION )); then
    TO_DELETE=$(( TOTAL_BACKUPS - RETENTION ))
    log "Retenció: $TOTAL_BACKUPS mentés található, a legutóbbi $RETENTION megtartása. $TO_DELETE régi archívum törlése."
    for (( i=0; i<TO_DELETE; i++ )); do
        DEL_FILE="${BACKUPS[$i]}"
        log "  -> Törlés: $DEL_FILE"
        rm -f "$DEL_FILE" "${DEL_FILE}.sha256" "${DEL_FILE}.meta"
    done
else
    log "Retenció: Nincs szükség törlésre ($TOTAL_BACKUPS <= $RETENTION)."
fi

log "Mentési folyamat befejezve."
echo "----------------------------------------" >> "$LOG_FILE"