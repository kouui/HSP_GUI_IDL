; orcagui.pro
@orcalib

;**************************************************************
function version
  ver='0.1'   ; 2013/10/26 k.i.
  ver='0.2'   ; 2013/11/03 k.i., t.k.   p-structure, savefits_p
  ver='0.21'  ; 2013/11/09 k.i.,        Load
  ver='0.3'   ; 2014/04/01 k.i., m.s.   p.date_obs2, ROI
  ver='0.31'  ; 2014/04/08 k.i., t.k.   LOAD bug fix
  ver='0.4'   ; 2014/05/05 k.i., m.s.   OBS_START, wp.dt
  ver='0.5'   ; 2014/05/19 k.i.         LOAD bug fix, get_systime, wp.fnam
  ver='0.6'   ; 2014/05/21 k.i.         change wd structures
  ver='0.61'  ; 2014/05/24 k.i.         bug fix
  ver='0.7'   ; 2015/07/24 k.i.         o.ExTrig
  ver='0.8'   ; 2015/08/26 k.i.,a.t.    o.ExTrig for GET, filename ctime @exp.end
  ver='0.81'  ; 2016/02/11 k.i.         count -> lcount
  ver='0.82'  ; 2016/07/27 k.o.         just format code
  ver='0.9'   ; 2016/09/25 k.i.    	orca_capturemode_snap @obs_start, get
  ver='1.0'   ; 2016/11/11 k.o.     	refactoring
  ver='1.1'   ; 2016/12/06 k.o.     	enable log and autoscl functions/parallel processing for fits output
  ver='1.2'   ; 2017/05/01 K.O,T.A.     BRIDGE->idl6.4,  trigger polarity -> positive by Glass scan, use orcaobs in Extrig. mode
  ver='1.21'  ; 2017/05/03 k.i.   	orca_capturemode_snap in Get  to orcaobs, remove Extrig in orcaobs()
  ver='1.3'   ; 2017/07/09 k.i.   	ExTrig polarity selection button
  ver='1.4'   ; 2019/04/28 k.i.,k.o. 	use orcaobs when nimg ge 2, move set_trigmode and set_capturemode out of while loop at wd.OBS_START
  ver='1.41'  ; 2019/04/29 k.i.,a.m.  	Dxy plots, xmovie in Rev
  ver='1.42'  ; 2019.05.03 k.i.,a.m.  	sparse sampling
  ver='1.43'  ; 2019.05.05 k.i,  	obs_start if o.ExTrig or o.nimg ge 1 then begin	; <== ge 2 don't work
  ver='1.5'   ; 2019.05.08 k.i,  	display imgs[*,p.Height/2,*] if o.nimg gt 10

  return,ver
end

;**************************************************************
pro make_dir,dir
  ;--------------------------------------------------------------
  if !version.arch eq 'x86_64' then $
    oscomdll='C:\Projects\cprog\VS2010\oscom64\x64\Debug\oscom64.dll' $
  else  oscomdll='C:\Projects\cprog\VS2008\oscom32\Debug\oscom32.dll'
  d=file_search(dir)
  if d[0] eq '' then dmy=call_external(oscomdll,'Dmkdirs',dir)

end

;**************************************************************
function wdevid, wd
  ;--------------------------------------------------------------
  ; return event ID's (long tags) in wd (widget) structure

  nt0=n_tags(wd)
  typ=lonarr(nt0)
  for i=0,nt0-1 do typ[i]=size(wd.(i),/type)
  ii=where(typ eq 3, nt)
  typ=typ[ii]
  wdid=lonarr(nt)
  for i=0,nt-1 do wdid[i]=wd.(ii[i])

  return,wdid
end

;**************************************************************
pro orcagui_event, ev
  ;--------------------------------------------------------------
  common orcagui, wd, wdp, evid_p, o, p, img1, imgs
  ; wd  - widget structure
  ; o - obs params
  ; p - ORCA control parameters

  widget_control, ev.id, get_uvalue=value
  dbin=2048./wdp.p.wx/p.bin
  x0=p.regionx/dbin
  y0=p.regiony/dbin
  hpos=float([x0,y0,x0,y0])/wdp.p.wx+[0.05,0.05,0.2,0.17]

  if n_elements(wdid_p) eq 0 then evid_p=wdevid(wdp)
  ii=where(ev.id eq evid_p, count)
  if count ne 0 then orca_handle, ev, wdp, p, img1


  case (ev.id) of
    wd.NIMG: begin
      o.nimg=fix(gt_wdtxt(ev.id))
      imgs=OrcaObs(nimg=o.nimg)
      if o.nimg ge 10 then window,1,xs=p.Width/dbin,ys=o.nimg
    end
    wd.SNAP: begin
      p.date_obs=get_systime(ctime=ctime)
      img1=OrcaObs(nimg=1)
      p.date_obs2=get_systime()

      img=rebin(img1,p.Width/dbin,p.Height/dbin)>0
      dmin=wdp.p.min
      dmax=wdp.p.max
      if wdp.p.log_on then begin
        img=alog10(img>1)
        dmin=alog10(dmin>1)
        dmax=alog10(dmax>1)
      endif
      img=wdp.p.AUTOSCL_ON?bytscl(img):bytscl(img,min=dmin,max=dmax)
      tv,img,p.regionx/dbin,p.regiony/dbin
      o.filename=o.fnam+ctime
      widget_control,wd.FILENAME,set_value=o.filename
    end
    wd.GET: begin
      orca_idle    ;capture stop
      orca_capturemode_snap,nimg=o.nimg

      if o.ExTrig then begin
        if o.polarity eq 0 then $
          orca_settrigmode,'Start',polarity='Negative' $ ; for trigger test
        else $
          orca_settrigmode,'Start',polarity='Positive' ; for trigger test
      endif

      ;wait,1.  ;for safety finishing orca_capturemode_****,nimg=o.nimg (when nimg is large)

      p.date_obs=get_systime(ctime=ctime)
      imgs=OrcaObs(nimg=o.nimg,sparse=p.sparse)
      p.date_obs2=get_systime(ctime=ctime)
      if o.ExTrig then orca_settrigmode,'Internal'
      img1=imgs[*,*,o.nimg-1]
      img=rebin(img1,p.Width/dbin,p.Height/dbin)>0
      dmin=wdp.p.min
      dmax=wdp.p.max
      if wdp.p.log_on then begin
        img=alog10(img>1)
        dmin=alog10(dmin>1)
        dmax=alog10(dmax>1)
      endif
      img=wdp.p.AUTOSCL_ON?bytscl(img):bytscl(img,min=dmin,max=dmax)
      tv,img,p.regionx/dbin,p.regiony/dbin
      if o.nimg gt 10 then begin
	wset,1
	tvscl,reform(imgs[*,p.Height/2,*],p.Width/dbin,o.nimg)
	wset,0
      endif
      o.filename=o.fnam+ctime
      widget_control,wd.FILENAME,set_value=o.filename
      ;orca_idle    ;capture stop
    end
    wd.PROFS: begin
      img1=imgs[*,*,0]
      profiles,rebin(img1,wdp.p.wx,wdp.p.wy)
    end
    wd.REV: begin
      imgss=bytarr(p.Width/dbin,p.Height/dbin,o.nimg)
      for i=0,o.nimg-1 do begin
        img=rebin(imgs[*,*,i],p.Width/dbin,p.Height/dbin)>0
        dmin=wdp.p.min
        dmax=wdp.p.max
        if wdp.p.log_on then begin
          img=alog10(img>1)
          dmin=alog10(dmin>1)
          dmax=alog10(dmax>1)
        endif
        img=wdp.p.AUTOSCL_ON?bytscl(img):bytscl(img,min=dmin,max=dmax)
        tv,img,p.regionx/dbin,p.regiony/dbin
        xyouts,10,10,string(i,form='(i4.0)'),/dev
	imgss[*,*,i]=img
      endfor
      xmovie,imgss,/no_temp
    end
    wd.DXY: begin
      dxy=get_correl_offsets(imgs[p.Width/3:p.Width/3*2,p.Height/3:p.Height/3*2,*])
      window,2,xs=700,ys=800
      !p.multi=[0,1,2]
      plot,dxy[0,*],ytitle='dx'
      plot,dxy[1,*],ytitle='dy'
      wdok,'XY displacement'
      wdelete,2
      !p.multi=0
    end
    wd.SAVE: begin
      outfile=o.outdir+o.filename+'.fits'
      savefits_p,imgs,p,file=outfile
      print,'saved to '+outfile
    end
    wd.OBS_START: begin
      nbins=128 & imax=2l^16 -1
      ii=findgen(nbins)/nbins*imax
      lcount=0l

      orca_idle    ;capture stop

      if o.ExTrig or o.nimg ge 2 then begin
	   orca_capturemode_snap,nimg=o.nimg
      endif else begin
           orca_capturemode_sequence,nimg=o.nimg      ;-- set capturemode sequence
           orca_capture    ;continuous capturing start
      endelse

      wait,1.  ;for safety finishing orca_capturemode_****,nimg=o.nimg (when nimg is large)

      date_obs=get_systime(ctime=ctime,msec=msec)

      while ev.id ne wd.OBS_STOP do begin
       if o.ExTrig then begin
	   if o.polarity eq 0 then $
	      orca_settrigmode,'Start',polarity='Negative' $ ; for trigger test for UTF?
	    else $
	      orca_settrigmode,'Start',polarity='Positive' ; 2017.05.01 T.A. for trigger produced by Glass scan
	    ;OrcaOutTriggerExposure                       ; 2017.05.01 T.A. for multi spectrometry
        endif
        if lcount gt 0 then begin
          date_obs=get_systime(ctime=ctime,msec=msec)
          while msec lt msec0+o.dt*1000 do begin
            wait,0.001
            date_obs=get_systime(ctime=ctime,msec=msec)
          endwhile
        endif
        p.date_obs=date_obs
        if o.ExTrig or o.nimg ge 1 then begin	; <== ge 2 don't work
          imgs=orcaobs(nimg=o.nimg,sparse=p.sparse)
        endif else begin
          imgs=orca_getimg(nimg=o.nimg,sparse=p.sparse)
        endelse
        p.date_obs2=get_systime(ctime=ctime)
        ;if o.ExTrig then orca_settrigmode,'Internal'
        img1=imgs[*,*,o.nimg-1]
        img=rebin(img1,p.Width/dbin,p.Height/dbin)>0
        dmin=wdp.p.min
        dmax=wdp.p.max
        if wdp.p.log_on then begin
          img=alog10(img>1)
          dmin=alog10(dmin>1)
          dmax=alog10(dmax>1)
        endif
        img=wdp.p.AUTOSCL_ON?bytscl(img):bytscl(img,min=dmin,max=dmax)
        tv,img,p.regionx/dbin,p.regiony/dbin
        if wdp.p.hist_on then begin
          h=histogram(img1,max=imax,min=0,nbins=nbins)
          plot,ii,h,psym=10, $
            /noerase,/xstyle,charsize=0.5,pos=[0.05,0.05,0.27,0.2],color=127
        endif
        if wdp.p.mmm_on then begin
          mmm=uint([min(img1,max=max),mean(img1),max])
          xyouts,p.regionx/dbin,(p.regiony+p.Height)/dbin,/dev,'!C'+strjoin(['MIN ','MEAN','MAX ']+' '+string(mmm),'!C'),color=127
        endif
	if o.nimg gt 10 then begin
		wset,1
		tvscl,reform(imgs[*,p.Height/2,*],p.Width/dbin,o.nimg)
		wset,0
	endif

        o.filename=o.fnam+ctime
        widget_control,wd.FILENAME,set_value=o.filename
        outfile=o.outdir+o.filename+'.fits'
        xyouts,x0+100,y0+p.Height/dbin-30,string(lcount,form='(i5)')+'  '+outfile,/dev
        savefits_p,imgs,p,file=outfile
        lcount=lcount+1
        msec0=msec
        ev = widget_event(wd.OBS_STOP,/nowait)
        orca_idle    ;capture stop
      endwhile
      if o.ExTrig then orca_settrigmode,'Internal'
      print,'Obs. stop'
    end
    wd.ExTrig: begin
      widget_control, ev.id, get_value=value
      o.extrig=value
      if o.extrig then p.TrigMode='Start' else p.TrigMode='Internal'
      print,'ExTrigger=',o.extrig
    end
    wd.POLARITY: begin
      widget_control, ev.id, get_value=value
      o.polarity=value
      if o.polarity eq 0 then p.TrigPol='Negative' else p.TrigPol='Positive'
      print,'Polarity=',p.TrigPol
    end
    wd.DT: begin
      o.dt=float(gt_wdtxt(ev.id))
    end
    wd.OUTDIR: begin
      o.outdir=gt_wdtxt(ev.id)
      make_dir,o.outdir
    end
    wd.FNAM: begin
      o.fnam=gt_wdtxt(ev.id)
    end
    wd.FILENAME: begin
      o.filename=gt_wdtxt(ev.id)
    end
    wd.LOAD: begin
      file=dialog_pickfile(path=wd.outdir,title='select file')
      imgs=uint(rfits(file,head=fh))
      byteorder,imgs
      imgsize,imgs,nx,ny,nn
      o.nimg=nn
      widget_control,wd.NIMG,set_value=string(o.nimg,form='(i4)')
      RegionX=fits_keyval(fh,'X0',/fix)
      RegionY=fits_keyval(fh,'Y0',/fix)
      bin=fits_keyval(fh,'BIN',/fix)
      Width=nx
      Height=ny
      p=OrcaSetParam(bin=bin)
      p=OrcaSetParam(regionx=RegionX,regiony=RegionY,width=Width,height=Height)
      set_wdroi,wdp,p
      widget_control,wdp.BIN,set_value=string(p.bin,form='(i2)')
      widget_control,wd.NIMG,set_value=string(o.nimg,form='(i4)')
      ; help,p,/st
      dbin=2048./wdp.p.wx/p.bin
    end
    wd.Exit: begin
      WIDGET_CONTROL, /destroy, ev.top
      ;caio_exit
    end
    else:
  endcase

end

;************************************************************************
function obs_widget,base,o
  ;--------------------------------------------------------------
  wd={wd_obs_V01, $
    NIMG:   0l, $
    DT:   0l,   $
    OBS_START:  0l,   $
    OBS_STOP: 0l,   $
    ExTRIG:   0l, $
    POLARITY:   0l, $
    SNAP:   0l, $
    GET:    0l, $
    PROFS:    0l, $
    REV:    0l, $
    DXY:    0l, $
    OUTDIR:   0l, $
    FNAM:   0l, $
    FILENAME: 0l, $
    SAVE:   0l, $
    LOAD:   0l, $
    Exit:   0l  $
  }

  b1=widget_base(base, /column, /frame)
  dmy = widget_label(b1, value='>>> Obs. <<<')
  b11=widget_base(b1, /row)
  dmy = widget_label(b11, value='nimg=')
  wd.NIMG = widget_text(b11,value=string(o.nimg,form='(i4)'), xsize=5, uvalue='NIMG',/edit)
  dmy = widget_label(b11, value='   dt:')
  wd.DT = widget_text(b11,value=string(o.dt,form='(f5.1)'), xsize=5, uvalue='DT',/edit)
  dmy = widget_label(b11, value='sec')
  b12=widget_base(b1, /row)
  wd.SNAP=widget_button(b12, value="Snap", uvalue = "SNAP")
  wd.GET=widget_button(b12, value="Get", uvalue = "GET")
  wd.PROFS=widget_button(b12, value="Prof", uvalue = "PROFS")
  wd.REV=widget_button(b12, value="Rev", uvalue = "REV")
  wd.DXY=widget_button(b12, value="Dxy", uvalue = "DXY")
  b14=widget_base(b1, /row)
  wd_label = widget_label(b14,value='ExTrig:')
  setv=o.extrig
  wd.ExTrig  = cw_bgroup(b14,['Non','External'],/row, $
    uvalue="ExTrig",/no_release,set_value=setv,/exclusive,ysize=25,/frame)
  b14b=widget_base(b1, /row)
  wd_label = widget_label(b14b,value='Polarity:')
  setv=o.polarity
  wd.POLARITY  = cw_bgroup(b14b,['Neg.','Pos.'],/row, $
    uvalue="Polarity",/no_release,set_value=setv,/exclusive,ysize=25,/frame)
  b13=widget_base(b1, /row)
  dmy = widget_label(b13, value='Obs. ')
  wd.OBS_START=widget_button(b13, value="Start", uvalue = "PRV_START")
  wd.OBS_STOP=widget_button(b13, value="Stop", uvalue = "PRV_STOP")
  wd.SAVE=widget_button(b13, value="Save", uvalue = "SAVE")

  ;b3=widget_base(base, /column, /frame )
  b3=b1
  b31=widget_base(b3, /row )
  dmy = widget_label(b31, value='outdir: ')
  wd.OUTDIR=widget_text(b31,value=o.outdir, xsize=25, ysize=1,uvalue='outdir',/edit)
  b33=widget_base(b3, /row )
  dmy = widget_label(b33, value='filenam:')
  wd.FILENAME=widget_text(b33,value=o.filename, xsize=23, ysize=1,uvalue='filename',/edit)
  dmy = widget_label(b33, value='.fits')
  b32=widget_base(b3, /row )
  dmy = widget_label(b32, value='fnam: ')
  wd.FNAM=widget_text(b32,value=o.fnam, xsize=20, ysize=1,uvalue='fnam',/edit)
  ; b34=widget_base(b3, /row )
  wd.LOAD=widget_button(b32, value="Load", uvalue = "Load")
  b4=widget_base(base, /row )
  wd.Exit=widget_button(b4, value="Exit", uvalue = "Exit")

  return,wd
end

;************************************************************************
;  main
;--------------------------------------------------------------
common orcagui, wd, wdp, evid_p, o, p, img1, imgs
COMMON bridge,bridge
; wd  - obs widget structure
; wdp - camera widget structure
; o - obs control parameters
; p - camera control parameters

p=orcainit();/noDev)
p=OrcaSetParam(expo=0.003,bin=1)

;-----  prepare object array for parallel processing -----------
nCPU=!CPU.HW_NCPU
bridge=objarr(nCPU-1)
;for i=0,nCPU-2 do bridge[i]=IDL_IDLbridge()
for i=0,nCPU-2 do bridge[i]=obj_new('IDL_IDLBridge')

;settriggermode
;settriggerpolarity

o={orca_obs_v02, $  ; obs. control params
  nimg:     1,  $ ; # of image for 1 shot
  dt:     0., $ ; time step, sec
  extrig:     0,  $ ; 0: free, 1: extrn.trig.
  polarity:     0,  $ ; 0: negative, 1: positive
  date:     '',   $
  outdir:     '',   $
  fnam:     'orca', $
  filename:   ''  $
}

ccsds=get_systime(ctime=ctime)
o.date=strmid(ctime,0,8)
o.outdir='D:\data\'+o.date+'\'
make_dir,o.outdir

base = WIDGET_BASE(title='ORCA-GUI:  Ver.'+version(), /column)

wdp=orca_widget(base,p)
wd=obs_widget(base,o)


widget_control, base, /realize

window,xs=wdp.p.wx,ys=wdp.p.wy

XMANAGER, 'orcagui', base

orcafin

for i=0,n_elements(bridge)-1 do obj_destroy,bridge[i]

end
