#!/bin/bash

valid_date() {
    awk -v value="$1" '
    BEGIN {
        if (value !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/) {
            exit 1
        }
        split(value, parts, /[-T:]/)
        year = parts[1] + 0
        month = parts[2] + 0
        day = parts[3] + 0
        hour = parts[4] + 0
        minute = parts[5] + 0
        second = parts[6] + 0
        days_in_month = 31
        if (month == 4 || month == 6 || month == 9 || month == 11) {
            days_in_month = 30
        } else if (month == 2) {
            leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
            days_in_month = leap ? 29 : 28
        }
        if (month < 1 || month > 12 || day < 1 || day > days_in_month ||
            hour > 23 || minute > 59 || second > 59) {
            exit 1
        }
    }'
}

case "$1" in
    "")
        echo "Hiba: Hianyzo file!" 1>&2
        exit 1
        ;;
    --help)
        echo "Hasznalat: $0 -f FAJL [muvelet]"
        echo "  --keres MINTA       kis/nagybetu-fuggetlen regexes kereses"
        echo "  --tol DATUM         ettol a datumtol"
        echo "  --ig DATUM          eddig a datumig"
        echo "  --csatorna NEV      csak ezt a csatornat"
        echo "  --csak-privat       csak privat uzenetek"
        echo "  --gyanusitott       top 3 gyanusitett indoklassal"
        exit 0
        ;;
    -f)
        if [ -z "$2" ]; then
            echo "Hiba: Hianyzo file!" 1>&2
            exit 1
        fi
        if [ ! -e "$2" ] || [ ! -r "$2" ]; then
            echo "Hiba: A file nem letezik vagy nem olvashato: $2" 1>&2
            exit 1
        fi

        if [ "$#" -ge 3 ]; then
            case "$3" in
                --gyanusitott)
                    awk '
                    function add_person(name) {
                        people[name] = 1
                    }
                    {
                        is_private = substr($2, 1, 1) == "@"
                        if (is_private) {
                            sender = substr($2, 2)
                        } else if (substr($2, 1, 1) == "#") {
                            sender = substr($3, 2, length($3) - 2)
                        } else {
                            next
                        }
                        add_person(sender)
                        if (is_private) {
                            private_sent[sender]++
                        }
                        text = tolower($0)
                        if (text ~ /sajtom|hutot|tejfol|maradekom|kozosben|nem mehet tovabb/) {
                            complaints[sender]++
                        }
                        if (text ~ /en biztos nem voltam|csak epp lementem vizert|egesz nap konyvtarban voltam|nem eszem mas kajajat|szerintem tudom ki az/) {
                            excuses[sender]++
                        }
                        split($1, time, "T")
                        split(time[2], clock, ":")
                        hour = clock[1] + 0
                        if (hour >= 1 && hour < 4) {
                            late[sender]++
                        }
                    }
                    END {
                        for (person in people) {
                            if (complaints[person] > max_complaints) {
                                max_complaints = complaints[person]
                            }
                            if (private_sent[person] > max_private) {
                                max_private = private_sent[person]
                            }
                        }
                        for (person in people) {
                            if (max_complaints > 0) {
                                complaint_points = 3 - int(complaints[person] * 3 / max_complaints)
                            } else {
                                complaint_points = 0
                            }
                            if (max_private > 0) {
                                private_points = int(private_sent[person] * 3 / max_private)
                            } else {
                                private_points = 0
                            }
                            late_points = (late[person] < 3 ? late[person] : 3)
                            excuse_points = (excuses[person] < 3 ? excuses[person] : 3)
                            score = complaint_points + late_points + excuse_points + private_points
                            printf "%d\t%s\tpanasz=%d (+%d), hajnali=%d (+%d), mentegetozes=%d (+%d), privat=%d (+%d)\n", \
                                score, person, complaints[person], complaint_points, \
                                late[person], late_points, excuses[person], excuse_points, \
                                private_sent[person], private_points
                        }
                    }
                    ' "$2" | sort -t '	' -k1,1nr -k2,2 | head -3 | awk -F '	' '
                    BEGIN {
                        print "Top 3 gyanusitett:"
                        print "Nev              Pont  Jelek"
                    }
                    {
                        printf "%-16s %4d  %s\n", $2, $1, $3
                    }
                    '
                    exit 0
                    ;;

                --keres|--tol|--ig|--csatorna|--csak-privat)
                    search=""
                    from=""
                    to=""
                    channel=""
                    private_only=0
                    i=3
                    while [ "$i" -le "$#" ]; do
                        option="${!i}"
                        case "$option" in
                            --keres|--tol|--ig|--csatorna)
                                next=$((i + 1))
                                if [ "$next" -gt "$#" ] || [ -z "${!next}" ]; then
                                    echo "Hiba: Hianyzo ertek a(z) $option kapcsolohoz!" 1>&2
                                    exit 1
                                fi
                                case "$option" in
                                    --keres) search="${!next}" ;;
                                    --tol)
                                        if ! valid_date "${!next}"; then
                                            echo "Hiba: Ervenytelen datum: ${!next}" 1>&2
                                            exit 1
                                        fi
                                        from="${!next}"
                                        ;;
                                    --ig)
                                        if ! valid_date "${!next}"; then
                                            echo "Hiba: Ervenytelen datum: ${!next}" 1>&2
                                            exit 1
                                        fi
                                        to="${!next}"
                                        ;;
                                    --csatorna) channel="#${!next}" ;;
                                esac
                                i=$((i + 2))
                                ;;
                            --csak-privat)
                                private_only=1
                                i=$((i + 1))
                                ;;
                            *)
                                echo "Hiba: Ismeretlen szuro: $option" 1>&2
                                exit 1
                                ;;
                        esac
                    done
                    awk -v pattern="$search" -v from="$from" -v to="$to" \
                        -v channel="$channel" -v private_only="$private_only" '
                    {
                        matched = 1
                        if (pattern != "" && tolower($0) !~ tolower(pattern)) {
                            matched = 0
                        }
                        if (from != "" && $1 < from) {
                            matched = 0
                        }
                        if (to != "" && $1 > to) {
                            matched = 0
                        }
                        is_private = substr($2, 1, 1) == "@"
                        if (channel != "" && $2 != channel) {
                            matched = 0
                        }
                        if (private_only && !is_private) {
                            matched = 0
                        }
                        if (matched) {
                            print
                            count++
                        }
                    }
                    END {
                        print "Talalatok:", count + 0
                    }
                    ' "$2"
                    exit 0
                    ;;

                --kivel)
                    if [ -z "$4" ]; then
                        echo "Hiba: Hianyzo nev!" 1>&2
                        exit 1
                    fi
                    if ! awk -v person="$4" '
                    {
                        if (substr($2, 1, 1) == "#") {
                            sender = substr($3, 2, length($3) - 2)
                            if (sender == person) {
                                print
                                found = 1
                            }
                        } else if (substr($2, 1, 1) == "@") {
                            sender = substr($2, 2)
                            recipient = substr($4, 2)
                            if (sender == person || recipient == person) {
                                print
                                found = 1
                            }
                        }
                    }
                    END {
                        if (!found) {
                            print "Hiba: Nincs ilyen resztvevo: " person > "/dev/stderr"
                            exit 1
                        }
                    }
                    ' "$2"
                    then
                        exit 1
                    fi
                    exit 0
                    ;;

                --beszelgetes)
                    if [ -z "$4" ] || [ -z "$5" ]; then
                        echo "Hiba: Ket nevet kell megadni!" 1>&2
                        exit 1
                    fi
                    awk -v first="$4" -v second="$5" '
                    substr($2, 1, 1) == "@" {
                        sender = substr($2, 2)
                        recipient = substr($4, 2)
                        if ((sender == first && recipient == second) ||
                            (sender == second && recipient == first)) {
                            print
                        }
                    }
                    ' "$2"
                    exit 0
                    ;;

                --export)
                    if [ -z "$4" ]; then
                        echo "Hiba: Hianyzo mappa!" 1>&2
                        exit 1
                    fi
                    mkdir -p "$4"
                    awk -v directory="$4" '
                    function safe_name(name) {
                        gsub(/[^[:alnum:]_.-]/, "_", name)
                        return name
                    }
                    function write_message(file, message) {
                        if (!(file in initialized)) {
                            printf "%s", "" > file
                            close(file)
                            initialized[file] = 1
                        }
                        print message >> file
                        close(file)
                    }
                    {
                        if (substr($2, 1, 1) == "#") {
                            sender = substr($3, 2, length($3) - 2)
                            file = directory "/" safe_name(sender) ".log"
                            write_message(file, $0)
                        } else if (substr($2, 1, 1) == "@") {
                            sender = substr($2, 2)
                            recipient = substr($4, 2)
                            file = directory "/" safe_name(sender) ".log"
                            write_message(file, $0)
                            file = directory "/" safe_name(recipient) ".log"
                            write_message(file, $0)
                        }
                    }
                    ' "$2"
                    echo "Export kesz: $4"
                    exit 0
                    ;;
                *)
                    echo "Hiba: Ismeretlen kapcsolo: $3" 1>&2
                    echo "Hasznalat: $0 -f FAJL [muvelet]"
                    echo "  --keres MINTA       kis/nagybetu-fuggetlen regexes kereses"
                    echo "  --tol DATUM         ettol a datumtol"
                    echo "  --ig DATUM          eddig a datumig"
                    echo "  --csatorna NEV      csak ezt a csatornat"
                    echo "  --csak-privat       csak privat uzenetek"
                    echo "  --gyanusitott       top 3 gyanusitett indoklassal"
                    exit 1
                    ;;
            esac
        fi

        #osszes uzenet, privat uzenetek
        awk '
        END { printf "%-24s %d\n", "Osszes uzenet:", NR }
        /@/ { count++ }
        END { printf "%-24s %d\n", "Privat uzenetek:", count + 0 }
        ' "$2"

        #Resztvevok szama

        awk '
        {
            if (substr($2, 1, 1) == "#") {
                print substr($3, 2, length($3) - 2)
            } else if (substr($2, 1, 1) == "@") {
                print substr($2, 2)
                print substr($4, 2)
            }
        }
        ' "$2" | sort -u | awk 'END { printf "%-24s %d\n", "Resztvevok:", NR }'

        #elso es utolso uzenet datuma

       awk '
        NR == 1 {
            elso = $1
        }
        {
            utolso = $1
        }
        END {
            printf "%-24s %s\n", "Elso uzenet datuma:", elso
            printf "%-24s %s\n", "Utolso uzenet datuma:", utolso
        }
        ' "$2"

        #resztvevok toplistaja uzenetszammal

        printf "\n%s\n%-16s %s\n%-16s %s\n" \
            "Resztvevok toplistaja:" "Resztvevo" "Uzenetek" "---------" "--------"
        awk '
        {
            if (substr($2, 1, 1) == "#") {
                name = substr($3, 2, length($3) - 2)
            } else if (substr($2, 1, 1) == "@") {
                name = substr($2, 2)
            }
            messages[name]++
        }
        END {
            for (name in messages) {
                print name, messages[name]
            }
        }
        ' "$2" | sort -k2,2nr -k1,1 | awk '{ printf "%-16s %7d\n", $1, $2 }'

        #uzenetek csatornankent

        printf "\n%s\n%-16s %s\n%-16s %s\n" \
            "Uzenetek csatornankent:" "Csatorna" "Uzenetek" "--------" "--------"
        awk '
        {
            if (substr($2, 1, 1) == "#") {
                channels[$2]++
            } else if (substr($2, 1, 1) == "@") {
                channels["privat"]++
            }
        }
        END {
            for (channel in channels) {
                print channel, channels[channel]
            }
        }
        ' "$2" | sort -k2,2nr -k1,1 | awk '{ printf "%-16s %7d\n", $1, $2 }'

        
        ;;

    *)  
        echo "Rossz kapcsolo! Hasznalat: $0 -f FAJL [muvelet]" 1>&2
        echo "  --keres MINTA       kis/nagybetu-fuggetlen regexes kereses"
        echo "  --tol DATUM         ettol a datumtol"
        echo "  --ig DATUM          eddig a datumig"
        echo "  --csatorna NEV      csak ezt a csatornat"
        echo "  --csak-privat       csak privat uzenetek"
        echo "  --gyanusitott       top 3 gyanusitett indoklassal"
        exit 1
        ;;
esac