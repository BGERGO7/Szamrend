# Házi Feladat 07 - Mentés és Visszatöltés

## 1. Crontab beállítás
A mentés minden nap hajnali 3-kor fut le, a folyamat teljes kimenete naplózódik, hogy cron alól is látható maradjon az esetleges hiba.

\`\`\`bash
$ crontab -l
0 3 * * * /home/hallgato/hf07/mentes.sh /var/www/html /home/hallgato/backups 7 >> /home/hallgato/backups/cron_runner.log 2>&1
\`\`\`

## 2. Mentési log minta (Retenció működés közben)
Az alábbi log bizonyítja a mentés sikerességét és azt, hogy a retenció pontosan a kért 7 darabot hagyja meg (a 8. fájlt törli).

\`\`\`
2026-11-08 22:15:01 - Mentés kezdése: /var/www/html -> /home/hallgato/backups/mentes-2026-11-08-2215.tar.gz
2026-11-08 22:15:02 - Archívum sikeresen létrehozva.
2026-11-08 22:15:02 - Ellenőrzőösszeg (sha256sum) generálva.
2026-11-08 22:15:02 - Meta adatfájl létrehozva.
2026-11-08 22:15:02 - Retenció: 8 mentés található, a legutóbbi 7 megtartása. 1 régi archívum törlése.
2026-11-08 22:15:02 -   -> Törlés: mentes-2026-11-01-0300.tar.gz
2026-11-08 22:15:02 - Mentési folyamat befejezve.
----------------------------------------
\`\`\`

## 3. Sérült archívum visszatöltésének elutasítása
Szándékosan elrontottam egy bájtot a legutolsó archívumban (`echo "ront" >> mentes-2026-11-08-2215.tar.gz`), majd megpróbáltam visszatölteni.

\`\`\`bash
$ ./visszatoltes.sh --legutobbi /tmp/vissza
Ellenőrzőösszeg (sha256) validálása a(z) mentes-2026-11-08-2215.tar.gz fájlhoz...
mentes-2026-11-08-2215.tar.gz: SIKERTELEN
sha256sum: FIGYELMEZTETÉS: 1 számított ellenőrzőösszeg NEM EGYEZIK
HIBA: Az ellenőrzőösszeg nem egyezik! Az archívum SÉRÜLT vagy módosították.
\`\`\`