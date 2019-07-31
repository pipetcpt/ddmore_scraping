


$PROBLEM Gompertz model. runEV2_105.    

$INPUT ID AGE NEUT PRE_TRE MAX_LEG AUC CMAX DBLOCK TIME DV DVID EVID 
AGE_CAT NEUT_CAT PRE_TR_C MAX_CAT AUC_CAT CMAX_CAT

$DATA ..\..\Data\event_data.csv
ACCEPT=(DVID.EQ.2,DVID.EQ.0)                                                        ; Select which DVID to accept

$SUBROUTINE ADVAN13 TRANS1 TOL=9

$MODEL NCOMPARTMENTS=1
       COMP=(CPT1)      	; TTE model			



$PK 

CENSORING = 2

IF (NEWIND.LE.1) SURVZ  = 1   		                ; Survival(0)=1 [we use this variable for storing survival function at start of observation interval for interval censored data]




;;;;;;;;;;;;;;;;;;;;; Start of TTE model ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Lam          = THETA(1)*EXP(ETA(1)) 		; NONMEM needs an eta, but it will be fixed to zero	

alpha        = THETA(2)		
			
Lam1   = Lam/1000				; rescale the parameters so NONMEM does not have to search tiny numbers
alpha1 = alpha/1000 

VAL          = EXP((THETA(3)/1000)*(AUC-3065.5))


$DES
DADT(1) = VAL*Lam1*exp(alpha1*T)  



$ERROR

CHAZ = A(1)				; cumulative hazard
SURV = EXP(-CHAZ)  			; probability of surviving to or beyond current time


HAZNOW = VAL*Lam1*exp(alpha1*TIME)  


                                                                  


;;;;;;;;;; Right censoring only ;;;;;;;;;;;;;;;;;

CS=0
IF (CENSORING.EQ.1.AND.DV.EQ.-1.AND.TIME.GT.0) CS=1                                  ; CS=1 for right censored events
IF (CENSORING.EQ.1.AND.TIME.GT.0) Y = (1 - CS)*HAZNOW*SURV + CS*SURV                 ; for right censored events the likelihood of event at this time or greater is the survival function
					                                             ; for non-censored events the likelihood of event at this time is (hazard function)*(survival function)
;;;;;;;;;; End ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;; Right + interval censoring ;;;;;;;;;;;;;;;;;;;;;;

IF (CENSORING.EQ.2.AND.DV.EQ.-1) Y=SURV

IF (CENSORING.EQ.2.AND.DV.EQ.2) SURVZ=SURV
	 
IF (CENSORING.EQ.2.AND.DV.NE.2) SURVZ=SURVZ

IF (CENSORING.EQ.2.AND.DV.EQ.3) Y=SURVZ-SURV

;;;;;;;;;; End ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
				
 




$THETA
(0,1)
(0,1)
(-1000,1,1000)


$OMEGA
0 FIX 
	

$EST MAXEVAL=9999 METHOD=COND LAPLACE NUMERICAL LIKE SLOW NOABORT NOTHETABOUNDTEST NSIG=3 SIGL=9 PRINT=5 MSFO=runEV2_105.txt

$COV PRINT=E 

$TABLE ID AGE NEUT PRE_TRE MAX_LEG AUC CMAX DBLOCK TIME DV DVID EVID
AGE_CAT NEUT_CAT PRE_TR_C MAX_CAT AUC_CAT CMAX_CAT
SURV CHAZ HAZNOW FORMAT=s1PE18.9 NOPRINT ONEHEADER FILE=runEV2_105.tab

