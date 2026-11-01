#!/usr/bin/env bash

set -euo pipefail

DEST_DIR="downloads"
LOG_FILE="download.log"
URL_FILE="${1:-urls.txt}"

mkdir -p "$DEST_DIR"

# Időbélyeges naplózó függvény
log() {
    printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

# Temp könyvtár létrehozása
TMP_DIR=$(mktemp -d)

# Trap beállítása takarításra bármilyen kilépési pontnál (EXIT)
cleanup() {
    log "Ideiglenes könyvtár törlése: $TMP_DIR"
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

log "=== Letöltési folyamat indítása ==="

if [[ ! -f "$URL_FILE" ]]; then
    printf "Hiba: A megadott URL fájl nem létezik: %s\n" "$URL_FILE" >&2
    exit 1
fi

SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_URLS=()

url_index=1

while IFS= read -r url || [[ -n "$url" ]]; do
    # Üres sorok és kommentek átugrása
    [[ -z "$url" || "$url" =~ ^[[:space:]]*# ]] && continue

    log "Feldolgozás alatt: $url"
    printf "Letöltés: %s ...\n" "$url"

    tmp_file="$TMP_DIR/download_$url_index.tmp"
    final_file="$DEST_DIR/file_$url_index.json"
    
    success=false
    attempt=1
    delay=1
    last_status=0

    while [[ $attempt -le 3 ]]; do
        log "Próbálkozás $attempt/3 ($url) - várakozás: ${delay}s"
        
        # A 'set -e' megkerülése || segítségével: elkapjuk a curl kilépési kódját
        if curl -sSL --fail --connect-timeout 5 --max-time 15 "$url" -o "$tmp_file"; then
            last_status=0
            success=true
            break
        else
            last_status=$?
        fi

        log "Hiba a letöltés során (curl kód: $last_status) URL: $url"
        
        if [[ $attempt -lt 3 ]]; then
            sleep "$delay"
            delay=$((delay * 2))
        fi
        attempt=$((attempt + 1))
    done

    if [[ "$success" == "true" ]]; then
        # Atomi írás: csak akkor kerül a célkönyvtárba, ha a letöltés hiánytalan
        mv "$tmp_file" "$final_file"
        log "Sikeres letöltés és mozgatás: $final_file"
        printf " -> SIKER\n"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        log "Sikertelen letöltés 3 próbálkozás után: $url (curl kód: $last_status)"
        printf " -> HIBA\n"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_URLS+=("$url (Curl hibakód: $last_status)")
    fi

    url_index=$((url_index + 1))
done < "$URL_FILE"

printf "\n================ ÖSSZEFOGLALÓ ================\n"
printf "Sikeres letöltések: %d\n" "$SUCCESS_COUNT"
printf "Sikertelen letöltések: %d\n" "$FAILED_COUNT"

log "=== Összefoglaló: Sikeres=$SUCCESS_COUNT, Sikertelen=$FAILED_COUNT ==="

if [[ $FAILED_COUNT -gt 0 ]]; then
    printf "\nSikertelen URL-ek listája:\n"
    for failed in "${FAILED_URLS[@]}"; do
        printf " - %s\n" "$failed"
    done
    exit 1
fi

exit 0