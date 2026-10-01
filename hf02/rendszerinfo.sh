#!/usr/bin/env bash

# Mit csinál: Rövid, formázott összefoglalót ír ki a gép aktuális állapotáról.
# Hogyan kell hívni: ./rendszerinfo.sh [opcionális/kimeneti/fájl]
# Mit ad vissza: 0-t sikeres futás esetén, 1-et, ha a fájlba írás meghiúsul

# Változók használata mindig idézőjelek között
CELFAJL="$1"

# Függvény az információk legenerálására
informaciok_lekerese() {
    printf '%-20s %s\n' "Hosztnév:" "$(hostname)"
    printf '%-20s %s\n' "Kernelverzió:" "$(uname -r)"
    printf '%-20s %s\n' "Uptime:" "$(uptime | sed 's/^[ \t]*//')"
    printf '%-20s %s\n' "Felhasználó:" "$(whoami)"
    printf '%-20s %s\n' "Home mérete:" "$(du -sh "$HOME" 2>/dev/null | awk '{print $1}')"
    printf '%-20s %s\n' "Szabad hely ( / ):" "$(df -h / | awk 'NR==2 {print $4}')"
    printf '%-20s %s\n' "Futó folyamatok:" "$(ps -e | wc -l)"
}

# Ha megadtak paramétert (nem üres a változó), fájlba írunk
if [ -n "$CELFAJL" ]; then
    # Megpróbáljuk a fájlba irányítani a kimenetet. Hiba esetén a >&2 a stderr-re irányít.
    if ! informaciok_lekerese > "$CELFAJL" 2>/dev/null; then
        printf 'Hiba: Nem lehet írni a megadott fájlba: "%s"\n' "$CELFAJL" >&2
        exit 1
    fi
else
    # Ha nem adtak meg paramétert, a képernyőre (stdout) írunk
    informaciok_lekerese
fi

# Sikeres lefutás
exit 0
