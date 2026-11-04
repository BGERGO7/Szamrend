#!/bin/bash

case "$1" in
    -h|--help)
        echo "Hasznalat: $0 -f FAJL [muvelet]"
        echo "--keres MINTA       kis/nagybetu-fuggetlen regexes kereses"
        echo "--tol DATUM         ettol a datumtol"
        echo "--ig DATUM          eddig a datumig"
        echo "--csatorna NEV      csak ezt a csatornat"
        echo "--csak-privat       csak privat uzenetek"
        echo "Fejlesztes alatt :)"
        echo "--fotervezo         top 3 gyanusitott indoklassal"
        echo "--tuntetes          tuntetes lehetseges datuma"

        echo "Peldahivasok:"
        echo "./barlang.sh -d chatlog/falusi-chat.log"
        echo "./barlang.sh -d chatlog/falusi-chat.log --keres 'tuntet|sztrajk' --tol 2026-11-01 --csak-privat"
        
        exit 0
        ;;
    -d|--dir)
        if [[ -z "$2" ]]; then
            echo "Hiba: Hianyzo file!" >&2
            exit 1
        fi

        if [[ "$#" -ge 3 ]]; then
            case "$3" in
                --kivel)
                    if [[ -z "$4" ]]; then
                        echo "Hiba: Hianyzo nev!" >&2
                        exit 1
                    fi

                    awk -v person="$4" '
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
                            print "Hiba: Nincs ilyen resztvevo: "
                            exit 1
                        }
                    }
                    ' "$2"
                    
                    exit 0
                    ;;

                --beszelgetes)
                    if [[ -z "$4" ]] || [[ -z "$5" ]]; then
                        echo "Hiba: Ket nevet kell megadni!" >&2
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
                    if [[ -z "$4" ]]; then
                        echo "Hiba: Hianyzo mappa!" >&2
                        exit 1
                    fi
                    mkdir -p "$4"
                    awk -v directory="$4" '
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
                            file = directory "/" sender ".log"
                            write_message(file, $0)
                        } else if (substr($2, 1, 1) == "@") {
                            sender = substr($2, 2)
                            recipient = substr($4, 2)
                            file = directory "/" sender ".log"
                            write_message(file, $0)
                            file = directory "/" recipient ".log"
                            write_message(file, $0)
                        }
                    }
                    ' "$2"
                    echo "Export kesz: $4"
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
                                if [[ "$next" -gt "$#" ]] || [[ -z "${!next}" ]]; then
                                    echo "Hiba: Hianyzo ertek a(z) $option kapcsolohoz!" >&2
                                    exit 1
                                fi
                                case "$option" in
                                    --keres) 
                                        search="${!next}" 
                                        ;;
                                    --tol)
                                        from=$(date -j -f "%Y-%m-%d" "${!next}" "+%Y-%m-%dT23:59:59")
                                        ;;
                                    --ig)
                                        to=$(date -j -f "%Y-%m-%d" "${!next}" "+%Y-%m-%dT23:59:59")
                                        ;;
                                    --csatorna) 
                                        channel="#${!next}" 
                                        ;;
                                esac
                                i=$((i + 2))
                                ;;
                            --csak-privat)
                                private_only=1
                                i=$((i + 1))
                                ;;
                            *)
                                echo "Hiba: Ismeretlen szuro: $option" >&2
                                exit 1
                                ;;
                        esac
                    done
                    awk -v pattern="$search" -v from="$from" -v to="$to" -v channel="$channel" -v private_only="$private_only" '
                    {
                        matched = 1
                        if (pattern != "" && tolower($0) !~ tolower(pattern)) {
                            matched = 0
                        }
                        if (from != "" && $1 <= from) {
                            matched = 0
                        }
                        if (to != "" && $1 >= to) {
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
                        print "Talalatok:", count
                    }
                    ' "$2"
                    exit 0
                    
                    ;; 
            esac
        fi

        echo ""
        echo "Áttekintés"
        echo "-----------"

        awk '
        END { printf "%-24s %d\n", "Osszes uzenet:", NR }
        /@/ { countP++ }
        END { printf "%-24s %d\n", "Privat uzenetek:", countP}
        /@/ { countN++ }
        END {printf "%-24s %d\n", "Nyilvanos uzenetek:", countN}
        ' "$2"

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

        printf "\n%s\n%-24s %s\n%-24s %s\n" \
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
        ' "$2" | sort -k2nr | awk '{ printf "%-24s %7s\n", $1, $2 }' | head -n 10


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
        ' "$2" | sort -k2nr | awk '{ printf "%-16s %7d\n", $1, $2 }'

        ;;
    *)
        echo "Rossz kapcsolo! Hasznalat: $0 -f FAJL [muvelet]" >&2
        echo "  --keres MINTA       kis/nagybetu-fuggetlen regexes kereses"
        echo "  --tol DATUM         ettol a datumtol"
        echo "  --ig DATUM          eddig a datumig"
        echo "  --csatorna NEV      csak ezt a csatornat"
        echo "  --csak-privat       csak privat uzenetek"
        echo "Fejlesztes alatt :)"
        echo "  --fotervezo         top 3 gyanusitott indoklassal"
        echo "  --tuntetes          tuntetes lehetseges datuma"
        exit 1
        ;;
esac