function ta_nomoduscat,file1,file2,dark=dark,flat=flat

pol_level0,file1,imgs1,hd,dt1,rtwv1
pol_level0,file2,imgs2,hd,dt2,rtwv2
nx   = fix(hd[0].naxis1)
ny   = fix(hd[0].naxis2)
nt   = fix(hd[0].naxis3)
nx2  = nx/2
expo = float(hd[0].expo)        ; [us]
expos= expo*1e-6                ; [s]
if keyword_set(dark) eq 0 then dark=fltarr(nx,ny)
if keyword_set(flat) eq 0 then flat=fltarr(nx,ny)+1.
ta_phase,rtwv1,dt1,ph1,period1,fps1      ; ph[rad],period[s]
ta_phase,rtwv2,dt2,ph2,period2,fps2      ; ph[rad],period[s]
fact = period1/4./!pi/expos * sin(4.*!pi*expos/period1)

data1= fltarr(nx,ny,nt)
data2= fltarr(nx,ny,nt)
for j=0,nt-1 do begin
    data1[*,*,j] = (imgs1[*,*,j] - dark)/flat
    data2[*,*,j] = (imgs2[*,*,j] - dark)/flat
endfor
demodu,data1,ph1,amp1,chi1
demodu,data2,ph2,amp2,chi2

scat1=amp1[*,*,0]*fact - sqrt(amp1[*,*,5]^2 + amp1[*,*,6]^2)
scat2=amp2[*,*,0]*fact - sqrt(amp2[*,*,5]^2 + amp2[*,*,6]^2)
tmp=min([median(scat1[0:nx2-1,*]),median(scat1[nx2:nx-1,*])],nn)
if nn eq 0 then scat1[nx2:nx-1,*]=fltarr(nx2,ny) else $
  scat1[0:nx2-1,*]=fltarr(nx2,ny)
tmp=min([median(scat2[0:nx2-1,*]),median(scat2[nx2:nx-1,*])],nn)
if nn eq 0 then scat2[nx2:nx-1,*]=fltarr(nx2,ny) else $
  scat2[0:nx2-1,*]=fltarr(nx2,ny)

scat=[ [[scat1+scat2]],   $
       [[scat1/amp1[*,*,0]*fact + scat2/amp2[*,*,0]*fact]] ]

wdef,0,nx,ny
stepper,scat;<1>0;<300>0

return,scat
END
;============================================================
dir='C:\data\dst\20110216\'
;dir='C:\data\dst\20101214\'

file1=dir+'00p_0_20110216_143654485.fits'	;normal
file2=dir+'90p_0_20110216_143535135.fits'	;normal
file1=dir+'00p_1_20110216_144619696.fits'	;normal+RM90
file2=dir+'90p_1_20110216_144715325.fits'	;normal+RM90
;file1=dir+'00p_2_20110216_145653949.fits'	;normal+RM90,hanaokasan
;file2=dir+'90p_2_20110216_145558916.fits'	;normal+RM90,hanaokasan
file1=dir+'00p_3_20110216_154113882.fits'	;normal+RM90-ascompenseter
file2=dir+'90p_3_20110216_154211074.fits'	;normal+RM90-ascompenseter
file1=dir+'00p_4_20110216_160240349.fits'	;normal+RM90,hanaokasan(<->micronicol)
file2=dir+'90p_4_20110216_160150989.fits'	;normal+RM90,hanaokasan(<->micronicol)

dir='C:\data\dst\20110217\'
file1=dir+'00p_5_20110217_142124909.fits'	;normal,�l�Hlight
file2=dir+'90p_5_20110217_142237172.fits'	;normal,�l�Hlight
file1=dir+'00p_6_20110217_143447935.fits'	;�l�Hlight,normal<->micronicol(f5.5),
file2=dir+'90p_6_20110217_143345197.fits'	;�l�Hlight,normal<->micronicol(f5.5),


dfile='C:/data/dst/20110216/dark200e0g20110216_150114379.fits'
dfile='C:/data/dst/20110217/dark200e0g8b20110217_142517414.fits'
mreadfits,dfile,h,imgs
dark=rebin(imgs,200,150,1)


res=ta_nomoduscat(file1,file2,dark=dark)



END

