$PROBLEM    RIF Run71 newinits
$INPUT      ID OCNO=DROP OCC=DROP OCC OCCO=DROP DAY=DROP TIME TAD=DROP
            DV MDV AMT EVID AGE SEX=DROP WT HT BMI=DROP RACE=DROP
            SMOK=DROP ALC=DROP PKG=DROP HIV=DROP HB=DROP HCT=DROP RBC=DROP
            MCV=DROP WBC=DROP AP=DROP ALT=DROP AST=DROP CRT=DROP
            TBIL=DROP UREA=DROP INHP=DROP PZAP=DROP FDC DS=DROP
            LOC CLCR=DROP FORM=DROP BEQ=DROP DOSE
$DATA       rif_1cpt.csv IGNORE=#
$SUBROUTINE ADVAN6 TRANS1 TOL=4
$MODEL      NCOMP=2 COMP=(DEPOT,DEFDOSE) COMP=(CENTRAL)
$PK

"FIRST
"        COMMON/PRCOMG/  IDUM1,IDUM2,IMAX,IDUM4,IDUM5
"INTEGER IDUM1,IDUM2,IMAX,IDUM4,IDUM5
"IMAX=10000000

;;; MTTFDC-DEFINITION START
IF(FDC.EQ.1) MTTFDC = 0  ; Most common
IF(FDC.EQ.0) MTTFDC = THETA(8)
;;; MTTFDC-DEFINITION END

;;; MTT-RELATION START
MTTCOV=(1+MTTFDC)
;;; MTT-RELATION END

;;; CLLOC-DEFINITION START
IF(FDC.EQ.1) CLLOC = 0  ; Most common
IF(FDC.EQ.0) CLLOC = THETA(9)
;;; CLLOC-DEFINITION END

;;; CL-RELATION START
CLCOV=(1+CLLOC)
;;; MTT-RELATION END

IF(AMT.GT.0)PD=AMT
IF(AMT.GT.0)TDOS=TIME
TAD = TIME-TDOS

IOVCL = ETA(5)
IOVMT = ETA(11)
IF (OCC.EQ.2) THEN
  IOVCL = ETA(6)
  IOVMT = ETA(12)
ENDIF
IF (OCC.EQ.3) THEN
  IOVCL = ETA(7)
  IOVMT = ETA(13)
ENDIF
IF (OCC.EQ.4) THEN 
  IOVCL = ETA(8)
  IOVMT = ETA(14)
ENDIF
IF (OCC.EQ.5) THEN 
  IOVCL = ETA(9)
  IOVMT = ETA(15)
ENDIF
IF (OCC.EQ.6) THEN
  IOVCL = ETA(10)
  IOVMT = ETA(16)
ENDIF

IIVCL = ETA(1)
IIVMT = ETA(4)

TVCL     = CLCOV*THETA(1)                         ; CL
CL       = TVCL*EXP(IOVCL + IIVCL)          ; CL

TVV2   = THETA(2)                       ; V2
V2     = TVV2*EXP(ETA(2))                             ; V2

K     = CL/V2

;TVKA  = K + THETA(3)                    ; KA
TVKA  = THETA(3)                         ; KA
KA    = TVKA * EXP(ETA(3))              ; KA

S2=V2

F1    = 0

TVMTT = MTTCOV*(THETA(6))  ;
MTT     = TVMTT*EXP(IOVMT + IIVMT)         ; MTT

TVNN    = THETA(7)                     ; NN
NN      = TVNN*EXP(ETA(17))            ; NN

KTR   = (NN+1)/MTT

L     = LOG(2.5066)+(NN+.5)*LOG(NN)-NN+LOG(1+1/(12*NN))

$DES


X=.00001

IF(T.GE.TDOS)THEN
  DADT(1)=EXP(LOG(PD+X)+LOG(KTR+X)+NN*LOG(KTR*(T-TDOS)+X)-KTR*(T-TDOS)-L)-KA*A(1)
ELSE
  DADT(1)=EXP(LOG(PD+X)+LOG(KTR+X)+NN*LOG(KTR*T+X)-KTR*T-L)-KA*A(1)
ENDIF
DADT(2)=KA*A(1)-K*A(2)

$ERROR

 (ONLY OBSERVATIONS)

AA1 = A(1)
AA2 = A(2)

CP = A(2)/V2

IPRED = F
W     = SQRT(THETA(4)**2+THETA(5)**2*F*F)
IRES  = DV-IPRED
IWRES = IRES/W
Y     = IPRED+W*EPS(1)

;TMAX=DLOG(KA/K)/(KA-K)
;AUC=AMT/CL
;CB=EXP(-K*TMAX)-EXP(-KA*TMAX)
;CC=AMT*KA
;CD=V2*(KA-K)
;CMAX=(CC/CD)*CB

;$MSFI run66.msf
$THETA  (0, 19.2)       ;            1 CL
$THETA  (0, 53.2, 100)       ;            2 V2
$THETA  (0, 1.15)       ;            3 KA
$THETA  (0, 0.0923)       ;       4 ADD err
$THETA  (0, 0.222)       ;       5 CCV err
$THETA  (0, 0.424)       ;           6 MTT
$THETA  (1, 7.13, 80)       ;            7 NN
$THETA (-1, 1.04, 5)       ; 8 MTTFDC1
$THETA (-1, 0.236, 5)       ; 9 CLLOC

$OMEGA  BLOCK(2) 0.279  ; 1 IIV CL/F
 0.217 0.188  ;   2 IIV V2
$OMEGA  0.439  ;   3 IIV KA
$OMEGA  0.361  ;  4 IIV MTT
$OMEGA  BLOCK(1) 0.0508  ;   5 IOV CL
$OMEGA  BLOCK(1) SAME

$OMEGA  BLOCK(1) SAME

$OMEGA  BLOCK(1) SAME

$OMEGA  BLOCK(1) SAME

$OMEGA  BLOCK(1) SAME

$OMEGA  BLOCK(1) 0.461  ; 11 IOV MTT
$OMEGA  BLOCK(1) SAME

$OMEGA  BLOCK(1) SAME

$OMEGA  BLOCK(1) SAME

$OMEGA  BLOCK(1) SAME

$OMEGA  BLOCK(1) SAME
$OMEGA 2.44 ; 17 NN

$SIGMA  1.000000  FIX
$ESTIMATION METHOD=1 INTER PRINT=3 MAXEVAL=9999 SIGDIG=3
            MSFO=run72.msf
$COVARIANCE PRINT=E MATRIX=S
$TABLE      ID TIME IPRED IWRES ETA1 ETA2 ETA3 ETA4 ETA5 ETA11 ETA17 
            AA1 AA2 CP NOPRINT ONEHEADER FILE=sdtab72
$TABLE      ID CL V2 KA K NOPRINT ONEHEADER FILE=patab72

$TABLE ID WT AGE DOSE
      NOPRINT ONEHEADER FILE=cotab72
$TABLE ID LOC FDC
       NOPRINT ONEHEADER FILE=catab72
;$TABLE ID TMAX CMAX AUC
;       NOPRINT ONEHEADER FILE=run72.fit

