# HF08 - Dockerizalt logtool

## Adatok

Az image-ben az HF5-os `logtool.sh` van csomagolva. Az alap `alpine:3.20`,
mert kis meretu kepet ad. Az Alpine a BusyBox implementacioit tartalmazza,
nem a GNU coreutils csomagot; a script azonban csak azokkal a leirasokkal
hasznalt parancsokat hasznal (`bash`, `awk`, `sort`, `uniq`, `head`, `wc`,
`cat`, `mktemp`), amelyek mind elerhetok a BusyBoxban vagy Bashban.

Tovabbi telepites: `bash` (a script interpretatora) es `curl`. Nem
telepultunk jq-t, mert a logtool ezt nem hasznalja. A kepben egyetlen
dolgot, a logtoolt tartalmazza plusz az alapcsomagokat.

## Build es futtatas

```sh
docker build -t logtool:1.0 .
docker run --rm logtool:1.0 --help
docker run --rm -v "$PWD/adatok:/adatok:ro" logtool:1.0 -f /adatok/access.log -t 5
docker run --rm --entrypoint whoami logtool:1.0
docker images logtool:1.0
```

A `-v "$PWD/adatok:/adatok:ro"` vegere tett `:ro` a bind mountot csak
olvashatova teszi. Ezzel a kontener nem tudja megvaltoztatni vagy torolni a
host `adatok` konyvtarat. Ez kulonosen megfelelo, mert a logtool bemenetet
csak olvassa, ugyanakkor hiba eseten sem irhatja felul vagy nem torolheti a
forrasadatokat. Output-kent legyen csatolt volume vagy konteneren beluli fajl
helyett kulon konyvtar, ha a kontenernek kell fajlban elmentenie valamit.

## A Docker cache es retegsorrend

Meresi korulmenyek: Docker Desktop 29.8.2, Apple arm64, macOS, Alpine
3.20. Az idot `/usr/bin/time -p` merte a teljes `docker build` paranctol a
kesz image exportalasig.

| Eset | Ido |
|---|---:|
| Elso, tiszta build (`--no-cache`) | 5.65 s |
| Jo retegsorrend, csak a script modositasa utan | 1.54 s |
| Rossz retegsorrend, `COPY . .` a csomagtelepites elott | 2.97 s |

A jo Dockerfileben a ritkan valtozo `apk` illetve felhasznalo-letrehozas
retegek elobb vannak, a gyakran modositott `logtool.sh` pedig utoljara
kerul be. A scriptet egyetlen commenttel modositottam a jo illetve rossz
ujrabuild kozott. Jo sorrendben a csomagtelepito retegek cache-ben maradtak,
csak a scriptet tartalmazo retegek es az utana levo lepesek futottak ujra.

A rossz visszaellenorzest a `Dockerfile.bad` tartalmazza: ott a
`COPY . .` elott van az `apk add` lepeshez kepest. A scriptvaltozas
megvaltoztatja a korabbi COPY-cache-t, ezert utana az
`apk add` kotelezoen ujra lefutott. A kiserletben ez 1.43 s-mal lassabb
volt a jo sorrendnel.

## .dockerignore

Kizarjuk a `.git` mappat, a Python cache-eket, ideiglenes fajlokat, a
tesztcelu `adatok/` konyvtarat es a build dokumentaciot. Igy nincs
forras vagy szemét az image build contextjeben. A `.git` nem kell az
image runtime-hoz, az `adatok/` pedig bind mounttal jut a kontenerbe.

## Image, kontener es nem-root futas

Az image a teljes futtathato recept es rendszerkomponensek; a kontener az
image egy futo peldanya. Egy leallt kontenerbe mentett valtozasok nem lesznek
automatikusan tartosak; a futasi adatokhoz bind mountot vagy named volumeot
hasznalunk.

Az image `app` nevu, nem root felhasznalokent indul:

```sh
$ docker run --rm --entrypoint whoami logtool:1.0
app
```
