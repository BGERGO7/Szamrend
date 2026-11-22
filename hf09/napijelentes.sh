#!/usr/bin/env bash

set -euo pipefail

readonly EX_OK=0
readonly EX_USAGE=2
readonly EX_NETWORK=3
readonly CACHE_SECONDS=3600

ARFOLYAM_URL="${ARFOLYAM_URL:-https://api.frankfurter.dev/v1/latest?base=EUR&symbols=HUF,USD}"
IDOJARAS_URL="${IDOJARAS_URL:-https://api.open-meteo.com/v1/forecast?latitude=47.5&longitude=19.05&daily=temperature_2m_max,temperature_2m_min&timezone=Europe%2FBudapest}"
UNNEPNAP_URL="${UNNEPNAP_URL:-https://date.nager.at/api/v3/PublicHolidays/2026/HU}"

FORMATUM="szoveg"
FRISSITS=0
MAX_TIME=10
CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/napijelentes"

usage() {
    cat <<'EOF'
Hasznalat: napijelentes.sh [KAPCSOLOK]

Kapcsolok:
  --formatum szoveg|json  kimeneti formatum (alap: szoveg)
  --frissits              kényszeríti a friss hálózati lekérdezést
  --max-time MASODPERC     HTTP idotullepes minden kereshez (alap: 10)
  --cache-dir UT        sajat cache-konyvtar
  -h, --help             segitseg
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --formatum)
            [[ $# -ge 2 ]] || { echo "Hiba: a --formatumhez ertek kell." >&2; exit "$EX_USAGE"; }
            FORMATUM="$2"
            shift 2
            ;;
        --frissits)
            FRISSITS=1
            shift
            ;;
        --max-time)
            [[ $# -ge 2 ]] || { echo "Hiba: a --max-timehoz ertek kell." >&2; exit "$EX_USAGE"; }
            MAX_TIME="$2"
            shift 2
            ;;
        --cache-dir)
            [[ $# -ge 2 ]] || { echo "Hiba: a --cache-dirhoz ertek kell." >&2; exit "$EX_USAGE"; }
            CACHE_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit "$EX_OK"
            ;;
        *)
            echo "Hiba: ismeretlen kapcsolo: $1" >&2
            usage >&2
            exit "$EX_USAGE"
            ;;
    esac
done

if [[ "$FORMATUM" != "szoveg" && "$FORMATUM" != "json" ]]; then
    echo "Hiba: a --formatum csak a szoveg vagy json ertek lehet." >&2
    exit "$EX_USAGE"
fi

if ! [[ "$MAX_TIME" =~ ^[0-9]+([.][0-9]+)?$ ]] || [[ "$MAX_TIME" == "0" ]]; then
    echo "Hiba: a --max-time pozitív szám legyen." >&2
    exit "$EX_USAGE"
fi

TODAY=$(TZ=Europe/Budapest date '+%F')
if date -v+1d '+%F' >/dev/null 2>&1; then
    TOMORROW=$(TZ=Europe/Budapest date -v+1d '+%F')
else
    TOMORROW=$(TZ=Europe/Budapest date -d 'tomorrow' '+%F')
fi

mkdir -p "$CACHE_DIR"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

for name in arfolyam idojaras unnepnap; do
    printf 'null\n' > "$TMP_DIR/$name.json"
done

declare -a ISSUES=()
AVAILABLE=0

file_age_seconds() {
    local file="$1"
    local modified now

    if [[ -e "$file" ]]; then
        if modified=$(stat -f %m "$file" 2>/dev/null); then
            :
        else
            modified=$(stat -c %Y "$file")
        fi
        now=$(date +%s)
        echo "$((now - modified))"
    else
        echo "$((CACHE_SECONDS + 1))"
    fi
}

fetch_data() {
    local name="$1" label="$2" url="$3"
    local cache_file="$CACHE_DIR/$name.json"
    local download_file="$TMP_DIR/$name.download.json"
    local age

    age=$(file_age_seconds "$cache_file")
    if [[ "$FRISSITS" -eq 0 ]] && [[ "$age" -ge 0 ]] && [[ "$age" -lt "$CACHE_SECONDS" ]] &&
       jq -e . "$cache_file" >/dev/null 2>&1; then
        cp "$cache_file" "$TMP_DIR/$name.json"
        AVAILABLE=$((AVAILABLE + 1))
        return
    fi

    if curl -fsS --max-time "$MAX_TIME" -o "$download_file" "$url" 2>/dev/null; then
        if jq -e . "$download_file" >/dev/null 2>&1; then
            mv "$download_file" "$cache_file"
            cp "$cache_file" "$TMP_DIR/$name.json"
            AVAILABLE=$((AVAILABLE + 1))
            return
        fi
        ISSUES+=("$label: a válasz nem érvényes JSON.")
    else
        ISSUES+=("$label: hálózati hiba, HTTP-hiba vagy időtúllépés.")
    fi

    if [[ -f "$cache_file" ]] && jq -e . "$cache_file" >/dev/null 2>&1; then
        cp "$cache_file" "$TMP_DIR/$name.json"
        ISSUES+=("$label: a friss hálózati adat nem érhető el, lejárt cache-fájl kerül felhasználásra.")
        AVAILABLE=$((AVAILABLE + 1))
    fi
}

fetch_data "arfolyam" "árfolyam" "$ARFOLYAM_URL"
fetch_data "idojaras" "időjárás" "$IDOJARAS_URL"
fetch_data "unnepnap" "ünnepnapok" "$UNNEPNAP_URL"

if [[ "$AVAILABLE" -eq 0 ]]; then
    echo "Hiba: egyik adatforrás sem érhető el. Ellenőrizd a hálózatot vagy használd az elérhető cache-adatokat." >&2
    exit "$EX_NETWORK"
fi

NORMALIZED="$TMP_DIR/normalized.json"
jq -n \
    --slurpfile rates "$TMP_DIR/arfolyam.json" \
    --slurpfile weather "$TMP_DIR/idojaras.json" \
    --slurpfile holidays "$TMP_DIR/unnepnap.json" \
    --arg today "$TODAY" \
    --arg tomorrow "$TOMORROW" '
    def number_or_null:
        if type == "number" then . else null end;
    def index_for($times; $date):
        [ $times
          | to_entries[]
          | select(.value == $date)
          | .key
        ] | first // null;
    def at($values; $index):
        if ($index | type) == "number"
           and ($values | type) == "array"
           and ($index >= 0)
           and ($index < ($values | length))
        then $values[$index] | number_or_null
        else null end;

    ($rates[0] // null) as $rates_raw |
    ($weather[0] // null) as $weather_raw |
    ($holidays[0] // null) as $holidays_raw |
    (($weather_raw.daily // null) | if type == "object" then . else {} end) as $daily |
    (($daily.time // []) | if type == "array" then . else [] end) as $times |
    (($holidays_raw // []) | if type == "array" then . else [] end) as $holiday_list |
    (index_for($times; $today)) as $today_index |
    (index_for($times; $tomorrow)) as $tomorrow_index |
    ([ $holiday_list[]
       | select(type == "object" and ((.date // .localDate // "") >= $today))
    ] | sort_by(.date // .localDate) | first // null) as $next_holiday |

    {
        exchange: {
            date: (if ($rates_raw | type) == "object" then ($rates_raw.date // null) else null end),
            eur_huf: (
                if ($rates_raw | type) == "object"
                   and (($rates_raw.rates // null) | type) == "object"
                   and (($rates_raw.rates.HUF // null) | type) == "number"
                then $rates_raw.rates.HUF else null end
            ),
            eur_usd: (
                if ($rates_raw | type) == "object"
                   and (($rates_raw.rates // null) | type) == "object"
                   and (($rates_raw.rates.USD // null) | type) == "number"
                then $rates_raw.rates.USD else null end
            )
        },
        weather: {
            today: {
                date: $today,
                max: at($daily.temperature_2m_max // []; $today_index),
                min: at($daily.temperature_2m_min // []; $today_index)
            },
            tomorrow: {
                date: $tomorrow,
                max: at($daily.temperature_2m_max // []; $tomorrow_index),
                min: at($daily.temperature_2m_min // []; $tomorrow_index)
            }
        },
        holiday: {
            date: (
                if $next_holiday != null then ($next_holiday.date // $next_holiday.localDate // null) else null end
            ),
            name: (
                if $next_holiday != null then ($next_holiday.localName // $next_holiday.name // null) else null end
            )
        }
    }
' > "$NORMALIZED"

HOLIDAY_DATE=$(jq -r '.holiday.date // empty' "$NORMALIZED")
if [[ -n "$HOLIDAY_DATE" ]]; then
    TODAY_SECONDS=$(TZ=Europe/Budapest date -j -f '%Y-%m-%d' "$TODAY" '+%s' 2>/dev/null || TZ=Europe/Budapest date -d "$TODAY" '+%s')
    HOLIDAY_SECONDS=$(TZ=Europe/Budapest date -j -f '%Y-%m-%d' "$HOLIDAY_DATE" '+%s' 2>/dev/null || TZ=Europe/Budapest date -d "$HOLIDAY_DATE" '+%s')
    HOLIDAY_DAYS=$(((HOLIDAY_SECONDS - TODAY_SECONDS) / 86400))
else
    HOLIDAY_DAYS=null
fi

HOLIDAY_NAME=$(jq -r '.holiday.name // empty' "$NORMALIZED")
[[ -n "$HOLIDAY_NAME" ]] || HOLIDAY_NAME="nem elérhető"
EXCHANGE_DATE=$(jq -r '.exchange.date // empty' "$NORMALIZED")
[[ -n "$EXCHANGE_DATE" ]] || EXCHANGE_DATE="nem elérhető"

if [[ "$FORMATUM" == "json" ]]; then
    if [[ ${#ISSUES[@]} -gt 0 ]]; then
        jq -n '$ARGS.positional' --args "${ISSUES[@]}" > "$TMP_DIR/issues.json"
    else
        jq -n '$ARGS.positional' --args > "$TMP_DIR/issues.json"
    fi
    jq -n \
        --slurpfile report "$NORMALIZED" \
        --slurpfile issues "$TMP_DIR/issues.json" \
        --argjson holiday_days "$HOLIDAY_DAYS" \
        '$report[0] |
         .holiday.days = $holiday_days |
         . + {issues: $issues[0]}'
else
    cat <<EOF
Napi jelentés
=============

Árfolyam ($EXCHANGE_DATE):
  EUR/HUF: $(jq -r 'if .exchange.eur_huf == null then "nem elérhető" else (.exchange.eur_huf | tostring) end' "$NORMALIZED")
  EUR/USD: $(jq -r 'if .exchange.eur_usd == null then "nem elérhető" else (.exchange.eur_usd | tostring) end' "$NORMALIZED")

Időjárás, Budapest:
  Mai nap ($TODAY):
    minimum: $(jq -r 'if .weather.today.min == null then "nem elérhető" else ((.weather.today.min | tostring) + " °C") end' "$NORMALIZED")
    maximum: $(jq -r 'if .weather.today.max == null then "nem elérhető" else ((.weather.today.max | tostring) + " °C") end' "$NORMALIZED")
  Holnap ($TOMORROW):
    minimum: $(jq -r 'if .weather.tomorrow.min == null then "nem elérhető" else ((.weather.tomorrow.min | tostring) + " °C") end' "$NORMALIZED")
    maximum: $(jq -r 'if .weather.tomorrow.max == null then "nem elérhető" else ((.weather.tomorrow.max | tostring) + " °C") end' "$NORMALIZED")

Következő magyar ünnepnap:
  $HOLIDAY_NAME
  Napok múlva: $(if [[ "$HOLIDAY_DAYS" == "null" ]]; then echo "nem elérhető"; else echo "$HOLIDAY_DAYS"; fi)
EOF
fi

if [[ ${#ISSUES[@]} -gt 0 ]]; then
    if [[ "$FORMATUM" == "szoveg" ]]; then
        printf '\nFigyelmeztetések:\n'
        printf '  - %s\n' "${ISSUES[@]}"
    fi
fi
