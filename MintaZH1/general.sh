#!/usr/bin/env bash
# ./general.sh NEPTUN > chat.log
set -euo pipefail
S="$(printf '%s' "${1:?adj meg egy Neptun-kodot}" | cksum | awk '{print $1}')"
awk -v seed="$S" 'BEGIN{
  srand(seed)
  nn=split("Kata_312 Bence_305 Zsofi_310 Marci_301 Peti_308 Reka_315 Domi_303", n, " ")
  nc=split("emelet3 konyha memek tanulas", c, " ")
  np=split("megint eltunt a sajtom|ki hagyta nyitva a hutot|van meg tejfol|en biztos nem voltam|egesz nap konyvtarban voltam|csak epp lementem vizert|valaki megette a maradekomat|holnap veszek uj zarat|nem eszem mas kajajat|ez igy nem mehet tovabb|szerintem tudom ki az|ne a kozosben beszeljunk errol", p, "|")
  t=1773000000
  for(i=0;i<8000;i++){
    t += 60 + int(rand()*900)
    a=n[int(rand()*nn)+1]
    if(rand()<0.78) printf "%s #%-9s <%s> %s\n", iso(t), c[int(rand()*nc)+1], a, p[int(rand()*np)+1]
    else { do { b=n[int(rand()*nn)+1] } while(b==a)
           printf "%s @%s -> @%s : %s\n", iso(t), a, b, p[int(rand()*np)+1] }
  }
}
function iso(x,days,seconds,z,era,doe,yoe,y,doy,month_part,month,day,hour,minute,second){
  days=int(x/86400)
  seconds=x-days*86400
  z=days+719468
  era=(z>=0 ? int(z/146097) : int((z-146096)/146097))
  doe=z-era*146097
  yoe=int((doe-int(doe/1460)+int(doe/36524)-int(doe/146096))/365)
  y=yoe+era*400
  doy=doe-(365*yoe+int(yoe/4)-int(yoe/100))
  month_part=int((5*doy+2)/153)
  day=doy-int((153*month_part+2)/5)+1
  month=month_part+(month_part<10 ? 3 : -9)
  y+=(month<=2)
  hour=int(seconds/3600)
  minute=int((seconds%3600)/60)
  second=seconds%60
  return sprintf("%04d-%02d-%02dT%02d:%02d:%02d", y, month, day, hour, minute, second)
}'