;+
; NAME       : m_mirr1.pro (function)
; PURPOSE :
; return normalized Mueller matrix for a mirror reflection
;positive Q-direction is in the plane of incidence
; CATEGORY :
;        idlpro/optic/ray/lib
; CALLING SEQUENCE :
;        mat = m_mirr(delta,X)
; INPUTS :
;       delta   --  
;       X       --
;       //delta,X are function of the incident angle,N=n+ik.
; OUTPUT :
; OPTIONAL INPUT PARAMETERS : 
; KEYWORD PARAMETERS :
; MODIFICATION HISTORY :
;        T.A. '09/08/24      ; Stenflo "Solar Magnetic Field", p320.
;
;*************************************************************************

function m_mirr1,tau,ro

tau	= float(tau)
ro	= float(ro)

mat	= 0.5*[ $
          	[ro^2+1.,  ro^2-1.,               0.,              0.],     $
	  	[ro^2-1.,  ro^2+1.,               0.,              0.],     $
      	 	[0.,            0.,  -2.*ro*cos(tau),  2.*ro*sin(tau)],     $
  	  	[0.,            0.,  -2.*ro*sin(tau), -2.*ro*cos(tau)]      $
    		]     

return,mat

end
