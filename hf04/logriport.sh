#!/usr/bin/env bash
# Hasznalat: ./logriport.sh access.log
set -euo pipefail

if [[ $# -ne 1 ]]; then
    printf 'Hasznalat: %s LOGFAJL\n' "$0" >&2
    exit 2
fi
if [[ ! -r $1 ]]; then
    printf 'Hiba: a logfajl nem olvashato vagy nem letezik: %s\n' "$1" >&2
    exit 1
fi

awk -F'"' '
function sort_desc(values, keys, n,    i, j, tv, tk) {
    for (i = 1; i <= n; i++) {
        for (j = i + 1; j <= n; j++) {
            if (values[j] > values[i] ||
                (values[j] == values[i] && keys[j] < keys[i])) {
                tv = values[i]; values[i] = values[j]; values[j] = tv
                tk = keys[i]; keys[i] = keys[j]; keys[j] = tk
            }
        }
    }
}
{
    split($1, prefix, " ")
    split($2, request, " ")
    split($3, suffix, " ")
    ip = prefix[1]
    status = suffix[1] + 0
    response_time = suffix[3] + 0
    timestamp = substr(prefix[4], 2)
    split(timestamp, time_parts, ":")
    hour = time_parts[2] + 0
    url = request[2]

    total++
    if (!(ip in seen_ip)) {
        seen_ip[ip] = 1
        unique_ips++
    }
    ip_count[ip]++
    status_count[status]++
    if (status >= 400) error_url[url]++
    hour_count[hour]++
    if (hour_count[hour] > peak_count) {
        peak_count = hour_count[hour]
        peak_hour = hour
    }
    total_time += response_time
    if (status == 200) {
        time_200 += response_time
        count_200++
    }
    if (status == 500) {
        time_500 += response_time
        count_500++
    }
}
END {
    if (total == 0) {
        print "Hiba: a logfajl ures vagy nem megfelelo formatumu." > "/dev/stderr"
        exit 1
    }

    for (key in ip_count) {
        ip_n++
        ip_values[ip_n] = ip_count[key]
        ip_keys[ip_n] = key
    }
    sort_desc(ip_values, ip_keys, ip_n)

    for (key in status_count) {
        status_n++
        status_values[status_n] = status_count[key]
        status_keys[status_n] = key
    }
    sort_desc(status_values, status_keys, status_n)

    for (key in error_url) {
        error_n++
        error_values[error_n] = error_url[key]
        error_keys[error_n] = key
    }
    sort_desc(error_values, error_keys, error_n)

    printf "LOG RIPORT\n"
    printf "===========\n\n"
    printf "Osszes keres:       %d\n", total
    printf "Egyedi IP-cimek:    %d\n\n", unique_ips

    printf "10 LEGAKTIVABB IP\n"
    printf "%-18s %12s\n", "IP-cim", "Keresek"
    printf "%-18s %12s\n", "------------------", "------------"
    limit = (ip_n < 10 ? ip_n : 10)
    for (i = 1; i <= limit; i++)
        printf "%-18s %12d\n", ip_keys[i], ip_values[i]
    printf "\n"

    printf "STATUSZKOD-MEGOSZLAS\n"
    printf "%-12s %12s %10s\n", "Statusz", "Darab", "Arany"
    printf "%-12s %12s %10s\n", "------------", "------------", "----------"
    for (i = 1; i <= status_n; i++)
        printf "%-12s %12d %9.2f%%\n", status_keys[i], status_values[i],
            100 * status_values[i] / total
    printf "\n"

    printf "HIBAS KERESEK (4xx, 5xx)\n"
    printf "%-35s %12s\n", "URL", "Darab"
    printf "%-35s %12s\n", "-----------------------------------", "------------"
    if (error_n == 0)
        printf "%-35s %12s\n", "(nincs)", 0
    else
        for (i = 1; i <= error_n; i++)
            printf "%-35s %12d\n", error_keys[i], error_values[i]
    printf "\n"

    printf "ORANKENTI KERESEKSZAM\n"
    printf "%-12s %12s\n", "Ora", "Keresek"
    printf "%-12s %12s\n", "------------", "------------"
    for (i = 0; i < 24; i++)
        if (i in hour_count)
            printf "%02d:00-%02d:59  %12d\n", i, i, hour_count[i]
    printf "Csucsora: %02d:00-%02d:59 (%d keres)\n", peak_hour, peak_hour,
        peak_count
    printf "\n"

    printf "VALASZIDO\n"
    printf "%-24s %12s\n", "Kategoria", "Atlag (s)"
    printf "%-24s %12s\n", "------------------------", "------------"
    printf "%-24s %12.3f\n", "Osszesen", total_time / total
    if (count_200 > 0)
        printf "%-24s %12.3f\n", "200-as keresek", time_200 / count_200
    else
        printf "%-24s %12s\n", "200-as keresek", "n/a"
    if (count_500 > 0)
        printf "%-24s %12.3f\n", "500-as keresek", time_500 / count_500
    else
        printf "%-24s %12s\n", "500-as keresek", "n/a"
    printf "\n"

    printf "KOVETKEZTETES: A legaktivabb IP a %s, ami az osszes keres %.2f%%-at adta.\n",
        ip_keys[1], 100 * ip_values[1] / total
}' "$1"
