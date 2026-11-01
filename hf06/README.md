## 1. Mit csinál a `set -euo pipefail`?

*   **`set -e` (errexit):** A script azonnal leáll, ha bármelyik parancs nem nullás (hibás) visszatérési kóddal zárul. Megakadályozza, hogy egy hiba után a script csőstül futson tovább a hibás állapotban.
*   **`set -u` (nounset):** A script hibát dob és leáll, ha egy nem definiált (deklariáratlan) változóra hivatkozunk. Megvédi a kódot a gépelési hibáktól és a kiürült változókból eredő nem várt viselkedéstől (pl. `rm -rf "$MIGET_VAR/"`).
*   **`set -o pipefail`:** Csővezeték (`|`) esetén a teljes csővezeték visszatérési értéke az utolsó hibás (nem 0) parancs kódja lesz, nem pedig az utolsó parancsé. Ha a csővezeték közepén hibázik egy parancs, az így nem takarózhat le a sikeres végső parancssor mögött.

---

## 2. A "Csapda": A `set -e` és a `curl` hibakezelése

A `set -e` beállítás miatt ha egy parancs nem nullás kódra fut, a script azonnal leállna. Mivel a `curl` hálózati hibánál vagy hiányzó oldalnál nem nullás kóddal tér vissza, a script alapértelmezés szerint az első hibás URL-nél megszakadna.

### A megoldás:
A Bash-ben ha egy parancs egy `if` feltétel részeként, vagy egy logikai operátor (`||` vagy `&&`) bal oldalán fut, a `set -e` **felfüggeszti az azonnali kilépést**, mert a shell úgy tekinti, hogy a kód szándékosan kezeli a hibás kimenetet.

A scriptben ezt az alábbi szerkezettel oldottuk meg:

```bash
if curl -sSL --fail ... "$url" -o "$tmp_file"; then
    success=true
    break
else
    last_status=$?
fi
```

## 3. Egy futás logja

[2026-11-01 18:10:57] === Letöltési folyamat indítása ===
[2026-11-01 18:10:57] Feldolgozás alatt: https://api.frankfurter.dev/v1/latest
[2026-11-01 18:10:57] Próbálkozás 1/3 (https://api.frankfurter.dev/v1/latest) - várakozás: 1s
[2026-11-01 18:10:58] Sikeres letöltés és mozgatás: downloads/file_1.json
[2026-11-01 18:10:58] Feldolgozás alatt: https://api.open-meteo.com/v1/forecast?latitude=47.5&longitude=19.05&current=temperature_2m
[2026-11-01 18:10:58] Próbálkozás 1/3 (https://api.open-meteo.com/v1/forecast?latitude=47.5&longitude=19.05&current=temperature_2m) - várakozás: 1s
[2026-11-01 18:10:58] Sikeres letöltés és mozgatás: downloads/file_2.json
[2026-11-01 18:10:58] Feldolgozás alatt: https://date.nager.at/api/v3/PublicHolidays/2026/HU
[2026-11-01 18:10:58] Próbálkozás 1/3 (https://date.nager.at/api/v3/PublicHolidays/2026/HU) - várakozás: 1s
[2026-11-01 18:10:58] Sikeres letöltés és mozgatás: downloads/file_3.json
[2026-11-01 18:10:58] Feldolgozás alatt: https://httpbin.org/status/500
[2026-11-01 18:10:58] Próbálkozás 1/3 (https://httpbin.org/status/500) - várakozás: 1s
[2026-11-01 18:10:59] Hiba a letöltés során (curl kód: 56) URL: https://httpbin.org/status/500
[2026-11-01 18:11:00] Próbálkozás 2/3 (https://httpbin.org/status/500) - várakozás: 2s
[2026-11-01 18:11:00] Hiba a letöltés során (curl kód: 56) URL: https://httpbin.org/status/500
[2026-11-01 18:11:02] Próbálkozás 3/3 (https://httpbin.org/status/500) - várakozás: 4s
[2026-11-01 18:11:03] Hiba a letöltés során (curl kód: 56) URL: https://httpbin.org/status/500
[2026-11-01 18:11:03] Sikertelen letöltés 3 próbálkozás után: https://httpbin.org/status/500 (curl kód: 56)
[2026-11-01 18:11:03] Feldolgozás alatt: https://httpbin.org/delay/10
[2026-11-01 18:11:03] Próbálkozás 1/3 (https://httpbin.org/delay/10) - várakozás: 1s
[2026-11-01 18:11:14] Sikeres letöltés és mozgatás: downloads/file_5.json
[2026-11-01 18:11:14] Feldolgozás alatt: https://ez.a.domain.biztosan.nem.letezik/valami.json
[2026-11-01 18:11:14] Próbálkozás 1/3 (https://ez.a.domain.biztosan.nem.letezik/valami.json) - várakozás: 1s
[2026-11-01 18:11:14] Hiba a letöltés során (curl kód: 6) URL: https://ez.a.domain.biztosan.nem.letezik/valami.json
[2026-11-01 18:11:15] Próbálkozás 2/3 (https://ez.a.domain.biztosan.nem.letezik/valami.json) - várakozás: 2s
[2026-11-01 18:11:15] Hiba a letöltés során (curl kód: 6) URL: https://ez.a.domain.biztosan.nem.letezik/valami.json
[2026-11-01 18:11:17] Próbálkozás 3/3 (https://ez.a.domain.biztosan.nem.letezik/valami.json) - várakozás: 4s
[2026-11-01 18:11:17] Hiba a letöltés során (curl kód: 6) URL: https://ez.a.domain.biztosan.nem.letezik/valami.json
[2026-11-01 18:11:17] Sikertelen letöltés 3 próbálkozás után: https://ez.a.domain.biztosan.nem.letezik/valami.json (curl kód: 6)
[2026-11-01 18:11:17] === Összefoglaló: Sikeres=4, Sikertelen=2 ===
[2026-11-01 18:11:17] Ideiglenes könyvtár törlése: /var/folders/t4/msb0l0xn3txd5v42ky5f3q3c0000gn/T/tmp.c7lSvXgzuY
