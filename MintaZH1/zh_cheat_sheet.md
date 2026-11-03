# Bash és awk ZH cheat sheet

Ez az összefoglaló a `general.sh`, a `chat.log` és a `hutoor.sh` mintafeladatok alapján készült. A célja, hogy ZH előtt gyorsan át tudd nézni a legfontosabb Bash- és awk-fogalmakat.

---

## 1. A terminál alapjai

### Könyvtárak

```bash
pwd
```

Kiírja, hogy melyik könyvtárban vagy.

```bash
ls
ls -l
ls -la
```

Fájlok és könyvtárak listázása:

- `ls`: egyszerű lista;
- `ls -l`: részletes lista;
- `ls -a`: rejtett fájlok is;
- `ls -la`: részletes lista rejtett fájlokkal együtt.

```bash
cd konyvtar
cd ..
cd ~
```

- `cd konyvtar`: belépés egy könyvtárba;
- `cd ..`: egy szinttel feljebb;
- `cd ~`: visszalépés a saját home könyvtárba.

### Fájlok megtekintése

```bash
cat file.txt
head file.txt
head -n 5 file.txt
tail file.txt
tail -n 5 file.txt
```

- `cat`: teljes fájl kiírása;
- `head`: eleje;
- `tail`: vége.

Nagy fájlnál jobb a `head` vagy a `tail`, mert nem ír ki mindent.

### Fájl létrehozása és törlése

```bash
touch file.txt
mkdir mappa
mkdir -p nagy/utvonal/mappa
rm file.txt
rmdir mappa
```

Az `rm` töröl. Ezzel óvatosan bánj.

### Jogosultság és futtatás

Egy script futtathatóvá tétele:

```bash
chmod +x script.sh
```

Futtatás:

```bash
./script.sh
bash script.sh
```

A kettő nem teljesen ugyanaz:

- `./script.sh`: a fájl első sora, a shebang dönti el, mivel fusson;
- `bash script.sh`: közvetlenül Bash-sel indítod.

Shebang:

```bash
#!/bin/bash
```

Ez megmondja, hogy a script Bash-sel fusson.

---

## 2. Bash script alapjai

### Változók

Változó létrehozása:

```bash
name="Bence"
count=10
```

Az `=` körül nem lehet szóköz:

```bash
name="Bence"   # jó
name = "Bence" # rossz
```

Változó használata:

```bash
echo "$name"
```

Mindig érdemes idézőjelet használni:

```bash
echo "$name"
```

Ez megőrzi a szóközöket és megakadályozza, hogy a shell több részre törje az értéket.

### Parancssori argumentumok

Ha ezt futtatod:

```bash
./script.sh egyik masik harmadik
```

akkor:

```text
$0 = ./script.sh
$1 = egyik
$2 = masik
$3 = harmadik
$# = 3
$@ = az összes argumentum
```

Példa:

```bash
echo "A program neve: $0"
echo "Az elso argumentum: $1"
echo "Az argumentumok szama: $#"
```

### Argumentum ellenőrzése

```bash
if [ -z "$1" ]; then
    echo "Hiba: hianyzo argumentum!" >&2
    exit 1
fi
```

Jelentése:

- `[` és `]`: feltételvizsgálat;
- `-z`: üres-e a szöveg;
- `"$1"`: az első argumentum;
- `>&2`: a hibát a standard hibakimenetre írja;
- `exit 1`: hibásan áll le.

Fontos: a `[` valójában egy parancs, ezért a szóközök kötelezőek:

```bash
if [ -z "$1" ]; then
```

Nem jó:

```bash
if [-z "$1"]; then
```

### Gyakori tesztek

```bash
[ -z "$x" ]       # üres szöveg
[ -n "$x" ]       # nem üres szöveg
[ -f "$file" ]    # reguláris fájl
[ -d "$dir" ]     # könyvtár
[ -e "$path" ]    # létező útvonal
[ -r "$file" ]    # olvasható fájl
[ -w "$file" ]    # írható fájl
[ -x "$file" ]    # futtatható fájl
[ "$a" = "$b" ]   # szövegek egyenlők
[ "$a" != "$b" ]  # szövegek különböznek
[ "$a" -eq "$b" ] # számok egyenlők
[ "$a" -lt "$b" ] # a kisebb b-nél
[ "$a" -le "$b" ] # a kisebb vagy egyenlő
[ "$a" -gt "$b" ] # a nagyobb b-nél
[ "$a" -ge "$b" ] # a nagyobb vagy egyenlő
```

### Logikai operátorok

```bash
[ feltetel1 ] && [ feltetel2 ]
```

Mindkét feltételnek igaznak kell lennie.

```bash
[ feltetel1 ] || [ feltetel2 ]
```

Legalább az egyiknek igaznak kell lennie.

```bash
if [ "$#" -lt 4 ] || [ -z "$4" ]; then
    echo "Hianyzo nev!" >&2
    exit 1
fi
```

### `case`

A `case` több lehetséges érték közül választ:

```bash
case "$1" in
    --help)
        echo "Sugo"
        exit 0
        ;;
    -f)
        echo "Fajl feldolgozasa"
        ;;
    *)
        echo "Ismeretlen kapcsolo" >&2
        exit 1
        ;;
esac
```

- `;;`: lezár egy ágat;
- `*)`: minden más érték;
- `esac`: a `case` vége.

Több érték egy ágban:

```bash
--keres|--tol|--ig)
```

Ez azt jelenti, hogy bármelyik felsorolt kapcsoló ugyanabba az ágba kerüljön.

### Ciklus

```bash
while [ "$i" -le "$#" ]; do
    echo "$i"
    i=$((i + 1))
done
```

Az `i=$((i + 1))` aritmetikai kifejezés.

### Kilépési kódok

```bash
exit 0
```

Sikeres befejezés.

```bash
exit 1
```

Hibás befejezés.

Az előző parancs kódja:

```bash
echo "$?"
```

### Kimenetek

```bash
echo "normalis uzenet"
echo "hiba" >&2
```

- standard kimenet: `stdout`;
- standard hibakimenet: `stderr`.

Átirányítás:

```bash
./script.sh > output.txt
```

A standard kimenetet fájlba írja, a korábbi tartalmat felülírja.

```bash
./script.sh >> output.txt
```

A fájl végéhez hozzáfűz.

```bash
./script.sh 2> error.txt
```

A hibakimenetet fájlba írja.

```bash
./script.sh > output.txt 2> error.txt
```

A normál és a hibakimenet külön fájlba kerül.

```bash
./script.sh > all.txt 2>&1
```

A normál és hibakimenet ugyanabba a fájlba kerül.

Példa:

```bash
./general.sh C706RO > chat.log
```

---

## 3. Fájlok, csövek és parancsok összekapcsolása

### Pipe: `|`

```bash
cat chat.log | awk '{ print NR }'
```

Az első parancs kimenete a második bemenete.

Gyakori lánc:

```bash
awk '{ print $3 }' chat.log | sort -u | awk 'END { print NR }'
```

Lépések:

1. az awk kiír egy mezőt;
2. `sort -u` rendezi és kiszűri a duplikációt;
3. a második awk megszámolja a sorokat.

### `sort`

```bash
sort file.txt
sort -u file.txt
sort -n file.txt
sort -r file.txt
sort -k2,2nr file.txt
```

- `-u`: egyedi sorok;
- `-n`: számként rendez;
- `-r`: fordított sorrend;
- `-k2,2`: csak a második mező a rendezési kulcs;
- `-k2,2nr`: a második mező szerint, numerikusan, csökkenően.

Például:

```text
Bence_305 1185
Domi_303 1190
Kata_312 1139
```

```bash
sort -k2,2nr
```

eredménye:

```text
Domi_303 1190
Bence_305 1185
Kata_312 1139
```

Több rendezési kulcs:

```bash
sort -k2,2nr -k1,1
```

Elsőként az üzenetszám szerint rendez, döntetlen esetén név szerint.

### `head`, `tail`, `wc`

```bash
head -n 3 file.txt
tail -n 3 file.txt
wc -l file.txt
```

- `head -n 3`: első 3 sor;
- `tail -n 3`: utolsó 3 sor;
- `wc -l`: sorok száma.

Awk-kal:

```bash
awk 'END { print NR }' file.txt
```

---

## 4. Az awk alapötlete

Az awk soronként olvassa a bemenetet.

Általános szerkezete:

```bash
awk 'feltetel { muvelet }' file.txt
```

Példa:

```bash
awk '/@/ { print }' chat.log
```

Kiírja azokat a sorokat, amelyekben szerepel az `@`.

A rövid forma:

```awk
/minta/
```

ugyanazt jelenti, mint:

```awk
/minta/ { print }
```

### Mezők

Alapértelmezésben az awk szóközök és tabulátorok alapján mezőkre bont.

Egy chat sor:

```text
2026-03-08T20:06:13 #tanulas <Marci_301> nem eszem mas kajajat
```

Mezők:

```text
$1 = 2026-03-08T20:06:13
$2 = #tanulas
$3 = <Marci_301>
$4 = nem
$5 = eszem
$6 = mas
$7 = kajajat
```

Fontos változók:

```awk
$0  # teljes aktuális sor
$1  # első mező
$2  # második mező
NF  # mezők száma az aktuális sorban
NR  # aktuális sor sorszáma az egész bemenetben
FNR # aktuális sor sorszáma az aktuális fájlban
```

### `BEGIN`, sorblokk, `END`

```awk
BEGIN {
    print "A feldolgozas kezdete"
}

{
    print "Ezt minden sorra vegrehajtja"
}

END {
    print "A feldolgozas vege"
}
```

- `BEGIN`: fájl előtt, egyszer;
- `{ ... }`: minden sorra;
- `END`: fájl után, egyszer.

Összes sor:

```bash
awk 'END { print NR }' file.txt
```

### Feltételek

```awk
$2 == "#konyha" { print }
```

Csak a `#konyha` csatorna sorai.

```awk
$1 < from { next }
```

Ha a dátum korábbi, a `next` átugorja az aktuális sort.

Logikai operátorok:

```awk
&&  # és
||  # vagy
!   # negáció
```

### Számlálás

```awk
/@/ {
    count++
}
END {
    print count
}
```

Ha nincs találat, az awk tömb- vagy számlálóváltozója alapból 0-ként viselkedik.

Biztos nulla:

```awk
print count + 0
```

### Összegzés

```awk
{
    sum += $2
}
END {
    print sum
}
```

### Egyedi értékek asszociatív tömbbel

```awk
{
    people[$1] = 1
}
END {
    for (name in people) {
        count++
    }
    print count
}
```

Ha ugyanaz a név többször szerepel, ugyanazt a tömbelem írjuk felül, tehát csak egyszer számít.

### Csoportosítás

```awk
{
    messages[$2]++
}
END {
    for (channel in messages) {
        print channel, messages[channel]
    }
}
```

Ez csatornánként megszámolja az üzeneteket.

---

## 5. Awk szövegkezelés

### `length`

```awk
length($3)
```

Egy szöveg hosszát adja vissza.

### `substr`

```awk
substr(szoveg, kezdo_pozicio, hossz)
```

Az awk-ban a pozíciók 1-től kezdődnek.

```awk
substr("Bence_305", 1, 5)
```

Eredmény:

```text
Bence
```

Ha nincs hossz:

```awk
substr("Bence_305", 7)
```

Eredmény:

```text
305
```

Chat név levágása:

```awk
substr($3, 2, length($3) - 2)
```

Ha `$3` értéke `<Marci_301>`, az eredmény `Marci_301`.

Privát név levágása:

```awk
substr($2, 2)
```

Ha `$2` értéke `@Bence_305`, az eredmény `Bence_305`.

### `tolower`, `toupper`

```awk
tolower($0)
toupper($0)
```

Kisbetűssé, illetve nagybetűssé alakít.

Kisbetű-független keresés:

```awk
tolower($0) ~ tolower(pattern)
```

### `split`

```awk
split($1, parts, "T")
```

Feldarabolja az első mezőt a `T` karakter mentén.

Ha `$1` ez:

```text
2026-03-08T20:06:13
```

akkor:

```text
parts[1] = 2026-03-08
parts[2] = 20:06:13
```

Idő feldarabolása:

```awk
split(parts[2], clock, ":")
hour = clock[1] + 0
```

### `sub` és `gsub`

```awk
sub(/@/, "", name)
```

Az első találatot cseréli le.

```awk
gsub(/minta/, "csere", name)
```

Az összes találatot lecseréli.

Biztonságos fájlnév:

```awk
gsub(/[^[:alnum:]_.-]/, "_", name)
```

Minden olyan karaktert `_`-re cserél, amely nem:

- betű;
- szám;
- `_`;
- `.`;
- `-`.

### `printf`

```awk
printf "%-16s %7d\n", name, count
```

- `%-16s`: szöveg, balra igazítva, 16 karakter szélességgel;
- `%7d`: egész szám, jobbra igazítva, 7 karakter szélességgel;
- `\n`: sortörés.

Példa:

```awk
printf "%-24s %d\n", "Osszes uzenet:", NR
```

---

## 6. Regexek

Az awk regexe a `/.../` jelek között van.

```awk
/sajt/
```

Tartalmazza a `sajt` szöveget.

```awk
$0 ~ /sajt/
```

A teljes sor illeszkedik a mintára.

```awk
$0 !~ /sajt/
```

A teljes sor nem illeszkedik.

### Gyakori regex jelek

```text
.       bármilyen egy karakter
^       sor eleje
$       sor vége
*       nulla vagy több előző elem
+       egy vagy több előző elem
?       nulla vagy egy előző elem
|       vagy
[...]   karakterosztály
[^...]  minden, ami nem a felsorolt
```

Példák:

```awk
/sajt|tejfol/
```

`sajt` vagy `tejfol`.

```awk
/^@/
```

`@` a sor elején.

```awk
/^[0-9][0-9]/
```

Két számmal kezdődik.

```awk
/[[:alnum:]_]/
```

Betű, szám vagy aláhúzás.

### Regex a shellből

```bash
./hutoor.sh -f chat.log --keres 'sajt|tejfol'
```

A regexet érdemes aposztrófok közé tenni, hogy a shell ne próbálja meg értelmezni.

---

## 7. A `chat.log` formátuma

### Nyilvános üzenet

```text
2026-03-08T20:06:13 #tanulas <Marci_301> nem eszem mas kajajat
```

Mezők:

```text
$1 = dátum és idő
$2 = csatorna
$3 = küldő, < > jelek között
$4-től = üzenet szövege
```

### Privát üzenet

```text
2026-03-08T20:17:06 @Bence_305 -> @Zsofi_310 : ne a kozosben beszeljunk errol
```

Mezők:

```text
$1 = dátum és idő
$2 = küldő @ jellel
$3 = ->
$4 = címzett @ jellel
$5 = :
$6-től = üzenet szövege
```

### Dátum összehasonlítása

Az ISO formátum miatt ez működik:

```awk
if ($1 < from) {
    next
}
```

Formátum:

```text
YYYY-MM-DDTHH:MM:SS
```

Nem jó kevert formátumokat összehasonlítani, például:

```text
2026.03.10
10/03/2026
```

---

## 8. Gyakori mintafeladatok

### Sorok száma

```bash
awk 'END { print NR }' chat.log
```

### `@` jelet tartalmazó üzenetek száma

```bash
awk '/@/ { count++ } END { print count + 0 }' chat.log
```

### Első és utolsó dátum

```bash
awk '
NR == 1 {
    first = $1
}
{
    last = $1
}
END {
    print "Elso:", first
    print "Utolso:", last
}
' chat.log
```

### Egy adott csatorna üzenetei

```bash
awk '$2 == "#konyha" { print }' chat.log
```

### Csak privát üzenetek

```bash
awk 'substr($2, 1, 1) == "@" { print }' chat.log
```

### Egy személyhez kapcsolódó privát üzenetek

```bash
awk -v person="Bence_305" '
substr($2, 1, 1) == "@" {
    sender = substr($2, 2)
    recipient = substr($4, 2)
    if (sender == person || recipient == person) {
        print
    }
}
' chat.log
```

### Két személy beszélgetése

```bash
awk -v first="Bence_305" -v second="Zsofi_310" '
substr($2, 1, 1) == "@" {
    sender = substr($2, 2)
    recipient = substr($4, 2)
    if ((sender == first && recipient == second) ||
        (sender == second && recipient == first)) {
        print
    }
}
' chat.log
```

### Résztvevők száma

```bash
awk '
{
    if (substr($2, 1, 1) == "#") {
        name = substr($3, 2, length($3) - 2)
        people[name] = 1
    } else if (substr($2, 1, 1) == "@") {
        people[substr($2, 2)] = 1
        people[substr($4, 2)] = 1
    }
}
END {
    for (name in people) {
        count++
    }
    print count
}
' chat.log
```

### Üzenetek száma résztvevőnként

```bash
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
' chat.log | sort -k2,2nr -k1,1
```

### Üzenetek száma csatornánként

```bash
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
' chat.log | sort -k2,2nr
```

---

## 9. Paraméterek feldolgozása

Egyszerű kapcsoló:

```bash
case "$1" in
    --help)
        echo "Sugo"
        exit 0
        ;;
esac
```

Kapcsoló értékkel:

```bash
--keres sajt
```

Az aktuális kapcsoló sorszáma:

```bash
i=3
option="${!i}"
```

Ha `i=3`, akkor `${!i}` a `$3` értékét adja.

Következő argumentum:

```bash
next=$((i + 1))
value="${!next}"
```

Kettővel lépés:

```bash
i=$((i + 2))
```

### Kombinálható kapcsolók

```bash
./hutoor.sh -f chat.log \
    --keres 'sajt|tejfol' \
    --tol 2026-03-10T00:00:00 \
    --ig 2026-03-20T23:59:59 \
    --csatorna konyha \
    --csak-privat
```

Az ilyen feldolgozásnál minden kapcsoló egy változót állít be, majd egyetlen awk dolgozza fel a fájlt.

---

## 10. Hibakezelés

### Hiányzó argumentum

```bash
if [ -z "$2" ]; then
    echo "Hiba: Hianyzo file!" >&2
    exit 1
fi
```

### Nem létező fájl

```bash
if [ ! -e "$2" ] || [ ! -r "$2" ]; then
    echo "Hiba: A file nem letezik vagy nem olvashato: $2" >&2
    exit 1
fi
```

`/dev/null` létezik és olvasható, ezért elfogadható bemenet:

```bash
./hutoor.sh -f /dev/null
```

### Ismeretlen kapcsoló

```bash
*)
    echo "Hiba: Ismeretlen kapcsolo!" >&2
    exit 1
    ;;
```

### Üres bemenet

Az awk nem omlik össze üres fájlnál. Például:

```awk
END {
    print count + 0
}
```

Nullával osztás ellen:

```awk
if (max > 0) {
    points = int(value * 3 / max)
} else {
    points = 0
}
```

### Dátumvalidálás

A formátum önmagában nem elég:

```text
2026-13-45
```

formailag hasonlít dátumra, de érvénytelen.

Ellenőrizni kell:

- hónap: 1–12;
- nap: az adott hónapban megengedett tartomány;
- óra: 0–23;
- perc: 0–59;
- másodperc: 0–59.

---

## 11. Export fájlokba

Awk fájlba írás:

```awk
print $0 >> file
close(file)
```

- `>>`: hozzáfűzés;
- `close(file)`: bezárja a fájlt.

Újrafuttatásnál figyelni kell, mert a `>>` önmagában duplikálhatja a tartalmat. Egy fájlt először ki lehet üríteni:

```awk
if (!(file in initialized)) {
    printf "%s", "" > file
    close(file)
    initialized[file] = 1
}
```

Ezután lehet hozzáfűzni:

```awk
print message >> file
close(file)
```

Könyvtár létrehozása Bash-ben:

```bash
mkdir -p "$directory"
```

---

## 12. Gyanúsított-pontszám példa

Több jelből pontszámot lehet számítani:

```awk
score = complaint_points + late_points + excuse_points + private_points
```

Példa részpontok:

```awk
late_points = (late[person] < 3 ? late[person] : 3)
```

Ez a rövid feltételes operátor:

```text
feltetel ? igaz_ertek : hamis_ertek
```

Jelentése:

- ha 3-nál kevesebb hajnali üzenet van, annyi pont;
- egyébként maximum 3 pont.

Arányos pontozás:

```awk
private_points = int(private_sent[person] * 3 / max_private)
```

Fontos: mindig kezeld azt az esetet, amikor a nevező nulla:

```awk
if (max_private > 0) {
    private_points = int(private_sent[person] * 3 / max_private)
} else {
    private_points = 0
}
```

Az ilyen pontszám csak heurisztika, nem bizonyíték.

---

## 13. Gyakori hibák

### Hibás változó-hozzárendelés

```bash
name = "Bence"
```

Helyesen:

```bash
name="Bence"
```

### Hiányzó szóköz a `[` mellett

Helytelen:

```bash
if [-z "$x"]; then
```

Helyes:

```bash
if [ -z "$x" ]; then
```

### Fájl át nem adása az awk-nak

Helytelen:

```bash
awk 'END { print NR }'
```

Ez csak akkor olvas fájlt, ha pipe-ból kap bemenetet.

Helyes:

```bash
awk 'END { print NR }' "$file"
```

### `$2` félreértése

Shellben:

```bash
$2
```

a script második argumentuma.

Awk-ban:

```awk
$2
```

az aktuális sor második mezője.

### Regex és shell idézőjelek

```bash
--keres 'sajt|tejfol'
```

Az aposztróf megakadályozza, hogy a shell értelmezze a regex speciális jeleit.

### `awk` és `gawk`

macOS-en a `/usr/bin/awk` BSD awk, amely nem feltétlenül támogat minden GNU awk-függvényt. Például a `strftime()` és `asorti()` hiányozhat.

Ezért ZH-s feladatnál használj hordozható awk-megoldásokat:

- `substr`;
- `length`;
- `split`;
- `tolower`;
- `printf`;
- asszociatív tömbök;
- `sort` külső parancsként.

### Dátumok szöveges összehasonlítása

Csak azonos ISO formátum esetén biztonságos:

```text
2026-03-10T00:00:00
```

### `strftime` macOS-en

Ha a feladat kötelezően sima awk-ot kér, ne használj `strftime()`-et. A dátumformázást vagy a bemeneti formátumot érdemes már eleve megfelelően kezelni.

---

## 14. ShellCheck és tesztelés

ShellCheck:

```bash
shellcheck hutoor.sh
```

Szintaktikai ellenőrzés:

```bash
bash -n hutoor.sh
```

Fontos tesztek:

```bash
./hutoor.sh --help
./hutoor.sh
./hutoor.sh -f nincs.log
./hutoor.sh -f chat.log --kivel NincsIlyenEmber
./hutoor.sh -f chat.log --tol 2026-13-45
./hutoor.sh -f /dev/null
```

Kilépési kód ellenőrzése:

```bash
./hutoor.sh --help
echo "$?"
```

Siker esetén `0`, hibánál általában nem nulla érték.

Kimenetek külön ellenőrzése:

```bash
./hutoor.sh -f nincs.log > out.txt 2> err.txt
```

---

## 15. ZH előtti gyors lista

### Bash

- [ ] Van shebang?
- [ ] Idézőjelben vannak a változók?
- [ ] Ellenőrzöd a hiányzó argumentumokat?
- [ ] A hibák `stderr`-re mennek?
- [ ] Hibánál `exit 1` történik?
- [ ] Sikeres futásnál `exit 0` történik?
- [ ] A fájl létezését és olvashatóságát ellenőrzöd?
- [ ] Az ismeretlen kapcsoló kezelve van?
- [ ] A `case` ágak végén van `;;`?

### Awk

- [ ] Tudod, hogy `$0`, `$1`, `$2`, `NF`, `NR` mit jelentenek?
- [ ] Tudod, mikor fut a `BEGIN` és az `END`?
- [ ] Számláláshoz `count++` kell?
- [ ] Összegzéshez `sum += ...` kell?
- [ ] Egyedi elemekhez asszociatív tömb kell?
- [ ] Regexhez `~` vagy `!~` kell?
- [ ] Szövegdaraboláshoz `substr` vagy `split` kell?
- [ ] Kisbetűs kereséshez `tolower` kell?
- [ ] Formázott kiíráshoz `printf` kell?
- [ ] Nem osztasz nullával?
- [ ] Üres fájlnál is értelmes eredmény jelenik meg?

### Parancsok

- [ ] `sort -u` eltávolítja a duplikációt?
- [ ] `sort -k2,2nr` második mező szerint, numerikusan, csökkenően rendez?
- [ ] `|` továbbadja az előző parancs kimenetét?
- [ ] `>` felülír, `>>` hozzáfűz?
- [ ] `2>` a hibakimenetet irányítja át?
- [ ] `wc -l` sorokat számol?

---

## 16. A legfontosabb egymondatos összefoglaló

**A Bash kezeli a paramétereket, kapcsolókat, hibákat és fájlokat; az awk soronként feldolgozza a fájlt, mezőket olvas, feltételeket vizsgál, számlál és tömbökben összesít; a `sort`, `head`, `tail` és pipe-ok segítségével a részeredményeket tovább lehet rendezni és feldolgozni.**
