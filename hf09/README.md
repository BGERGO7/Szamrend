# HF09 - Napi jelentés

## Futtatás

```sh
./napijelentes.sh
./napijelentes.sh --formatum szoveg
./napijelentes.sh --formatum json
./napijelentes.sh --frissits --max-time 5 --formatum json
```

## Példa szöveges kimenetre

```text
Napi jelentés
=============

Árfolyam (2026-11-20):
  EUR/HUF: 373.55
  EUR/USD: 1.099

Időjárás, Budapest:
  Mai nap (2026-11-22):
    minimum: 3.2 °C
    maximum: 8.4 °C
  Holnap (2026-11-23):
    minimum: 1.3 °C
    maximum: 4.9 °C

Következő magyar ünnepnap:
  Karácsony
  Napok múlva: 33
```

## Példa JSON-kimenetre

```json
{
  "exchange": {
    "date": "2026-11-20",
    "eur_huf": 373.55,
    "eur_usd": 1.099
  },
  "weather": {
    "today": {
      "date": "2026-11-22",
      "max": 8.4,
      "min": 3.2
    },
    "tomorrow": {
      "date": "2026-11-23",
      "max": 4.9,
      "min": 1.3
    }
  },
  "holiday": {
    "date": "2026-12-25",
    "name": "Karácsony",
    "days": 33
  },
  "issues": []
}
```

A JSON minden kulcsot tartalmaz. Ha egy API nem adja vissza a kért
értéket, az JSON mezője `null`, a szöveges kimenetben pedig
`nem elérhető`.

## Mi történik hálózat nélkül

Minden APIhoz külön cache tartozik a
`${XDG_CACHE_HOME:-$HOME/.cache}/napijelentes` konyvtarban.
Egy cache-fájl legfeljebb egy óráig használható frissként, és
`--frissits` kényszeríti a lekérdezést.

Ha hálózat vagy HTTP-hiba miatt nem sikerül friss adatot kapni,
a script először még a már létező cache-fájlt próbálja felhasználni,
még ha az lejárt is. Ez lehetővé teszi, hogy a többi API adata
megjelenjen részleges jelentésben. `issues` tartalmazza az
elmaradt források és hibák leírását.

Ha minden forrás nélküli és nincs használható cache, a script
értelmes hibaüzenettel áll le:

```text
Hiba: egyik adatforrás sem érhető el. Ellenőrizd a hálózatot vagy használd az elérhető cache-adatokat.
```

Nem indul el végtelen lógó kérés, mert minden `curl` hívásra
érvényes a `--max-time` (alapértelmezetten 10 másodperc).
A lekérés HTTP hibáknál `-fS` miatt sem tekinti sikernek a választ,
és a `jq -e .` ellenőrzi, hogy érvényes-e a kapott JSON.

Egy cím például idézőjelű városnévvel vagy ünnepnévvel is biztonságosan
kerülhet a JSON-ba, mert a kimenetet `jq --arg`/`--argjson` paraméterekkel
építjük, nem szövegösszefűzéssel.

## Eredményellenőrzés

```sh
./napijelentes.sh --formatum json | jq .
shellcheck napijelentes.sh
```

Egy második, cache-t használó futás jelentősen gyorsabb volt az elsőnél:
első friss lekérés: 0.43 s; második cache-futás: 0.09 s.

Teszthez URL-en kívül az `ARFOLYAM_URL`, `IDOJARAS_URL` és
`UNNEPNAP_URL` környezeti változók írhatók felül.
