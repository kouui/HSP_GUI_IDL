;+
; NAME       : phase.pro (procedure)
; PURPOSE :
; 	return phase and period of rotating waveplate
; CATEGORY :
;        idlpro/polobs/
; CALLING SEQUENCE :
;        phase,rtwv,dt,expo,ph,perio,period=period,/draw
; INPUTS :
; 	rtwv --  voltage of sensor monitaring waveplate angle
; 	dt   --  raw data of time to capture image (Prosilica GE1650)
; OUTPUT :
;	ph   --  phase of rotating waveplate (rad)
;	perio--  period of rotating waveplate (sec)
; OPTIONAL INPUT PARAMETERS :
;	period-  period of rotating waveplate (sec)
;                ,when you decide period forcibly
; KEYWORD PARAMETERS :
;       draw --  draw situation or not
; MODIFICATION HISTORY :
;        T.A. '10/06/08
;        T.A. '10/06/20  change to procedure, keywords period
;-
;*************************************************************************
pro phase,rtwv,dt,ph,perio,period=period,draw=draw
     ;period[s],perio[s],ph[rad]

dt1=ULong64(dt)
tt=(dt1[*,0]*(ULong64(2)^32)+dt1[*,1])/79861111.d
mxtt=max(tt);+expo*10.d^(-6)                ;[sec]
ntt=size(tt,/dim)
nwv=size(rtwv,/dim)
thr=( mean(max(rtwv))+mean(min(rtwv)) )*0.5

p0=0.
for i=0,nwv[1]-2 do begin
    if (rtwv[i] gt thr) and $
      (rtwv[i+1] lt thr) then begin

        if (mean(p0) eq 0) then begin
            p0=i
        endif else begin
            p0=[p0,i]
        endelse
    endif
endfor

if keyword_set(period) then begin
    perio=period*1.
    t0=float(p0[0]-(nwv[1]-1))/2000.+mxtt
    ph=2.*!pi*(tt-t0)/perio
endif else begin
    np0=size(p0,/dim)
    if np0[0] lt 2 then begin
        print,'rtwv too short'
        ph=-1
        perio=-1
    endif else begin
        p1=fltarr(np0[0]-1)
        for i=0,np0[0]-2 do p1[i]=p0[i+1]-p0[i]
        perio=float(median(p1))/2000.             ;sec
        t0=float(p0[0]-(nwv[1]-1))/2000.+mxtt
        ph=2.*!pi*(tt-t0)/perio
    endelse
endelse

if keyword_set(draw) then begin
    if perio eq -1 then begin
        print,'connot draw'
    endif else begin
        set_line_color
        vomx=max(rtwv)
        yr=[0,vomx+1.5]

        window,0,xs=1000,ys=500
        x1=2.*!pi*(findgen(nwv[1])-p0[0])/2000./perio*!radeg
        plot,x1,rtwv,yr=yr,xtitle='phase [deg]',   $
          ytitle='voltage',color=0,background=1
        oplot,ph*!radeg,fltarr(nwv[1])+mean(vomx)+1.,color=3,psym=7
        loadct,0
    endelse
endif


end
