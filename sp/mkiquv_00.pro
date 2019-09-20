;;2010.09.27   T.Anan


pro mkiquv_00,file,rtrd,iquv,iquverr,hd,amp,imgs,    $
             dark=dark,flat=flat,period=period,rtrderr=rtrderr
    
;rtrd [deg],period [s]
;file='/dst_arch/vs/2010/20100502/WW0_he20100502_170105087.fits'
;file='/dst_arch/vs/20091229/sp_he20091229_153404782.fits'

pol_level0,file,imgs,hd,dt,rtwv
nx=fix(hd[0].naxis1)
ny=fix(hd[0].naxis2)
nt=fix(hd[0].naxis3)
expo=float(hd[0].expo)                 ;[us]
if keyword_set(period) eq 1 then begin
  phase,rtwv,dt,ph,period,period=period    ;ph[rad],period[s]
endif else begin
    phase,rtwv,dt,ph,period   ;ph[rad],period[s]
endelse
rtrd1=rtrd*!dtor                       ;[rad]
;xt=ph+offset(expo,period,nx,ny)               ;[rad]
xt=ph+60.*!dtor               ;[rad]
;frph= 
;r2=

expo= expo*1e-6
ci1 = expo * 0.5  ;$
          ; + expo * r2 cos(frph) * cos(rtrd1)
          ;ci2 = -1. * period * r2 / 2./!pi * sin(2.*!pi*expo/period) $
          ;  * sin(frph) * sin(rtrd1)
          ;cq1 = ci2
          ;cu1 = ci2
cq2 = period /8./!pi * sin(4.*!pi*expo/period) * (1. - cos(rtrd1))*0.5 ;$
          ;  +period * r2 /4./!pi *sin(4.*!pi*expo/period) $
          ;  *cos(frph)*sin(rtrd1*0.5)*sin(1.5*rtrd1)
cu2 = cq2
cv1 = period /4./!pi * sin(2.*!pi*expo/period) * sin(rtrd1) ;  $
          ;  +period * r2 /2./!pi * sin(2.*!pi*expo/period)    $tt
          ; * cos(frph) * sin(2.*rtrd1)
cq3 = expo*0.5 * ( 1. + cos(rtrd1) )*0.5  ; $
          ;  + expo * r2 * cos(frph) * cos(rtrd1*0.5) * cos(rtrd1*1.5)


if keyword_set(dark) eq 0 then dark=fltarr(nx,ny)
if keyword_set(flat) eq 0 then flat=fltarr(nx,ny)+1.
data=fltarr(nx,ny,nt)
for i=0,nt-1 do data[*,*,i] = ( float(imgs[*,*,i]) - dark ) / flat
demodu,data,xt,amp,chi


;===========================================================;
;============ IQUV (fringe approximation version) ==========;

ii = (amp[*,*,0] - cq3 * amp[*,*,6]/cq2 )/ci1     ;I
qq = amp[*,*,6]/cq2     ;Q
uu = amp[*,*,5]/cu2     ;U
vv = amp[*,*,3]/cv1     ;V

ro_n  = 0.98141443d
tau_n = 0.19801076d
ro_c  = 1.d
tau_c = 6.2291202d
position='west'
th_en = 0.d
del_en= 0.d
th_ex = 0.d
del_ex= 0.d
incli = 0.d
ha=float(hd[0].ha)/3600.*15.d*!dtor         ;[rad]
zd=float(hd[0].zd)/3600.d*!dtor             ;[rad]
mat=invert(m_dst(position,ro_N,tau_N,ro_C,tau_C,ha,zd,incli,   $
                 th_en,del_en,th_ex,del_ex))

iquv=fltarr(nx,ny,4)
ii1 = mat[0,0]*ii + mat[1,0]*qq + mat[2,0]*uu + mat[3,0]*vv
qq1 = mat[0,1]*ii + mat[1,1]*qq + mat[2,1]*uu + mat[3,1]*vv
uu1 = mat[0,2]*ii + mat[1,2]*qq + mat[2,2]*uu + mat[3,2]*vv
vv1 = mat[0,3]*ii + mat[1,3]*qq + mat[2,3]*uu + mat[3,3]*vv
iquv[*,*,0] = ii1
iquv[*,*,1] = qq1/ii1
iquv[*,*,2] = uu1/ii1
iquv[*,*,3] = vv1/ii1


;===========================================================;
;======================= error =============================;

;== error of retardation ==;

if keyword_set(rtrderr) eq 0 then rtrderr=0.
rtrd2= rtrd1+rtrderr*!dtor
dci1 = expo * 0.5
dcq2 = period /8./!pi * sin(4.*!pi*expo/period) * (1. - cos(rtrd2))*0.5
dcu2 = dcq2
dcv1 = period /4./!pi * sin(2.*!pi*expo/period) * sin(rtrd2)
dcq3 = expo*0.5 * ( 1. + cos(rtrd2) )*0.5

Ierr1= abs( (amp[*,*,0] - cq3 * amp[*,*,6]/cq2 )/ci1 - (amp[*,*,0] - dcq3 * amp[*,*,6]/dcq2 )/dci1 )
Qerr1= abs( amp[*,*,6]/cq2 - amp[*,*,6]/dcq2 )
Uerr1= abs( amp[*,*,5]/cu2 - amp[*,*,5]/dcu2 )
verr1= abs( amp[*,*,3]/cv1 - amp[*,*,3]/dcv1 )

;== error of rotating angle ==;

th   = 0.74*!dtor          ; [rad]
xt   = ph + offset(expo,period,nx,ny) +th
demodu,data,xt,damp,dchi

Ierr2= abs( (amp[*,*,0] - cq3 * amp[*,*,6]/cq2 )/ci1 - (damp[*,*,0] - cq3 * damp[*,*,6]/cq2 )/ci1 )
Qerr2= abs( amp[*,*,6]/cq2 - damp[*,*,6]/cq2 )
Uerr2= abs( amp[*,*,5]/cu2 - damp[*,*,5]/cu2 )
verr2= abs( amp[*,*,3]/cv1 - damp[*,*,3]/cv1 )

;== error of fitting ==;

for i=0,6 do damp[*,*,i] = chi[*,*,i] + amp[*,*,i]
Ierr3= abs( (amp[*,*,0] - cq3 * amp[*,*,6]/cq2 )/ci1 - (damp[*,*,0] - cq3 * damp[*,*,6]/cq2 )/ci1 )
Qerr3= abs( amp[*,*,6]/cq2 - damp[*,*,6]/cq2 )
Uerr3= abs( amp[*,*,5]/cu2 - damp[*,*,5]/cu2 )
verr3= abs( amp[*,*,3]/cv1 - damp[*,*,3]/cv1 )

;== error  ==;
iquverr=[[[Ierr1>Ierr2>Ierr3]],   $
        [[(Qerr1>Qerr2>Qerr3)/iquv[*,*,0]]],    $
        [[(Uerr1>Uerr2>Uerr3)/iquv[*,*,0]]],    $
        [[(Verr1>Verr2>Verr3)/iquv[*,*,0]]]]


;===========================================================;

END
