#!/usr/bin/env bash

set -euo pipefail

readonly EX_OK=0
readonly EX_USAGE=2
readonly EX_NOFILE=3

FILE=""
TOP_N=10
STATUS=""
OUTPUT=""
QUIET=0

usage() {
    cat <<EOF
Hasznalat: $0 -f FAJL [KAPCSOLOK]
Kapcsolok:
  -h, --help       kiirja a hasznalatot es kilep 0-val
  -f, --file FAJL  a feldolgozando log (kotelezo)
  -t, --top N      hany elemet mutasson a toplistakban (alap: 10)
  -s, --status KOD csak az adott statuszkodu sorokat nezze
  -o, --output FAJL a riportot fajlba irja
  -q, --quiet      csak a vegso osszefoglalo sort irja ki
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit "$EX_OK" ;;
            -f|--file) FILE="${2:-}"; shift 2 ;;
            -t|--top) TOP_N="${2:-}"; shift 2 ;;
            -s|--status) STATUS="${2:-}"; shift 2 ;;
            -o|--output) OUTPUT="${2:-}"; shift 2 ;;
            -q|--quiet) QUIET=1; shift ;;
            *) 
                echo "Hiba: ismeretlen kapcsolo: $1" >&2
                usage >&2
                exit "$EX_USAGE" 
                ;;
        esac
    done

    if [[ -z "$FILE" ]]; then
        echo "Hiba: a -f kapcsoloval meg kell adni a logfajlt!" >&2
        usage >&2
        exit "$EX_USAGE"
    fi
}

ellenoriz_bemenet() {
    local f="$1"
    if [[ ! -r "$f" ]]; then
        echo "Hiba: a logfajl nem olvashato vagy nem letezik: $f" >&2
        exit "$EX_NOFILE"
    fi
}

szur_log() {
    local in_file="$1" stat="$2" out_file="$3"
    if [[ -n "$stat" ]]; then
        awk -F'"' -v s="$stat" '{split($3, a, " "); if(a[1]==s) print $0}' "$in_file" > "$out_file"
    else
        cat "$in_file" > "$out_file"
    fi
}

top_ip() {
    local f="$1" top="$2"
    echo "LEGAKTIVABB IP CIMEK (TOP $top)"
    echo "-------------------------------"
    awk '{print $1}' "$f" | sort | uniq -c | sort -nr | head -n "$top" | \
        awk '{printf "%-18s %12d\n", $2, $1}'
}

statusz_megoszlas() {
    local f="$1" total
    total=$(wc -l < "$f")
    echo "STATUSZKOD-MEGOSZLAS"
    echo "--------------------"
    awk -F'"' '{split($3, a, " "); print a[1]}' "$f" | sort | uniq -c | sort -nr | \
        awk -v t="$total" '{printf "%-12s %12d %9.2f%%\n", $2, $1, 100*$1/t}'
}

osszefoglalo() {
    local f="$1" total top_ip top_cnt arany
    total=$(wc -l < "$f")
    if [[ "$total" -eq 0 ]]; then
        echo "KOVETKEZTETES: Nincs feldolgozhato adat."
        return
    fi
    read -r top_cnt top_ip <<< "$(awk '{print $1}' "$f" | sort | uniq -c | sort -nr | head -n 1)"
    arany=$(awk -v c="$top_cnt" -v t="$total" 'BEGIN { printf "%.2f", 100 * c / t }')
    echo "KOVETKEZTETES: A legaktivabb IP a $top_ip, ami az osszes keres $arany%-at adta."
}

riport_generalas() {
    local f="$1" top="$2" q="$3"
    
    if [[ "$q" -eq 1 ]]; then
        osszefoglalo "$f"
        return
    fi
    
    echo "LOG RIPORT"
    echo "=========="
    echo "Osszes keres: $(wc -l < "$f")"
    echo "Egyedi IP-cimek: $(awk '{print $1}' "$f" | sort -u | wc -l)"
    echo ""
    top_ip "$f" "$top"; echo ""
    statusz_megoszlas "$f"; echo ""
    osszefoglalo "$f"
}


parse_args "$@"
ellenoriz_bemenet "$FILE"

tmp_log=$(mktemp)
trap 'rm -f "$tmp_log"' EXIT

szur_log "$FILE" "$STATUS" "$tmp_log"

if [[ -n "$OUTPUT" ]]; then
    riport_generalas "$tmp_log" "$TOP_N" "$QUIET" > "$OUTPUT"
else
    riport_generalas "$tmp_log" "$TOP_N" "$QUIET"
fi