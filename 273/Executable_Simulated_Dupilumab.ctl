$SIZES LIM6=1000 
$PROBLEM ATOPIC DERMATITIS

$INPUT ID TIME CMT CP=DV  STU STUD MDV EVID NOM_DAY DOSE=AMT DTYP DVVSE PCMT DP DPKG DCH DBY TYPE WT LWT H HM HML

$DATA ..\SIMULATED_DUPILUMAB.CSV IGNORE=S
$SUBROUTINES  ADVAN13 TOL=9    
$MODEL COMP=(INJ) 
       COMP=(BLD) 
       COMP=(AUC)
       COMP=(PER)


$PK
  MU_1  = THETA(1)
  MU_2  = THETA(2)
  MU_3  = THETA(3)
  MU_4  = THETA(4)
  MU_5  = THETA(5)
  MU_6  = THETA(6)
  MU_7  = THETA(7)
  MU_8  = THETA(8)

  C1    = DEXP((LWT-4.317488)*0.75)
  V2    = DEXP((MU_1+ETA(1))*C1)
  KE    = DEXP(MU_2+ETA(2))
  VM    = DEXP(MU_3+ETA(3))
  KA    = DEXP(MU_4+ETA(4))
  BIO   = MU_5+ETA(5)

  K23   = MU_6+ETA(6)
  K32   = MU_7+ETA(7)
  KM    = MU_8+ETA(8)

  F1    = BIO
  S2    = V2    
  Q     = K23*V2
  V3    = Q/K32

$ERROR
  CALLFL=0
  IRE=66666
  SIG =66666
  IPRE=F
  SD1=THETA(9)
  SD2=0.03
  SIG=SQRT(F*F*SD1**2 + SD2**2)
  LOQ=0.078

  DUM=(LOQ-IPRE)/SIG
  CUMD  =PHI(DUM)

  IF (TYPE.EQ.2) THEN
    F_FLAG=1
    Y=CUMD
  ELSE
    F_FLAG=0
    Y  = IPRE*DEXP(ERR(1)*SD1) + ERR(2)*SD2
  ENDIF  

  IRE  = DV-IPRE          
  IF (SIG.LE.0.00001) THEN
    IWRE=66666
  ELSE
    IWRE=IRE/SIG      
  ENDIF

$DES
  DADT(1)=-KA*A(1)*DTYP                                                             
  DADT(2)=-A(2)*KE-K23*A(2)+K32*A(4)+KA*A(1)*DTYP-A(2)*VM/(KM+A(2)/V2)               
  DADT(3)= A(2)/V2                                                                 
  DADT(4)= K23*A(2)-K32*A(4)   

  A1=A(1)
  A2=A(2)/V2
  A3=A(3)
  A4=A(4)


$THETA (-7 1.09 4)          ; POPV2   
$THETA (-6 -2.99 1)         ; POPKE
$THETA (-5 0.112 5)         ; POPVM
$THETA (-6 -1.30 6)         ; POPKA  
$THETA (0.01,0.638,100)     ; POPBIO

$THETA (0.01,0.154,10)      ; POPK23   
$THETA (0.01,0.250,10)      ; POPK32
$THETA (0.01 FIXED)         ; POPKM 
$THETA (0.01,0.17,10)       ; POPSD1
  

$OMEGA DIAGONAL(1) 2.73E-02                           ;ETAV2
$OMEGA BLOCK(2)    2.13E-02                           ;ETAKE
                  -9.25E-03                           ;ETACORR
                   1.23E-02                           ;ETAVM
$OMEGA DIAGONAL(1) 1E-02                              ;ETAKA
$OMEGA DIAGONAL(4) 0 FIX                              ;ETABIO
                   0 FIX                              ;ETAK23
                   0 FIX                              ;ETAK32
                   0 FIX                              ;ETAKM

$SIGMA 1 FIX ; ERRSD1
$SIGMA 1 FIX ; ERRSD2

;1111111111111111111111111111111111111111111111111111111111111111111111111111111
$EST NOABORT PRINT=1 NSIG=3 SIGL=9 NBURN=3000 NITER=1500 
  CONSTRAIN=5 CINTERVAL=10 CTYPE=3 NOABORT
  METHOD=SAEM  POSTHOC INTERACTION
  LAPLACIAN DERCONT=1 GRD=TG(1-8):TS(9) 
  MSFO=DUPILUMAB.MSF
$EST NSIG=3 SIGL=9 NOABORT PRINT=1 
  METHOD=IMP EONLY=1 NITER=20 ISAMPLE=20000 MAPITER=0 POSTHOC INTERACTION
  NOABORT LAPLACIAN

$COV PRINT=R UNCONDITIONAL TOL=10 SIGL=10 SIGLO=10 

$TABLE ID STU STUD TIME NOM_DAY DTYP DOSE CP IPRE IWRE MDV EVID CMT PCMT DP DPKG DCH DBY
  A1 A2 A3 A4 TYPE WT
  NOHEADER APPEND NOPRINT FORMAT=S1PE17.9E2 FILE=DUPILUMAB.FIT

$TABLE  ID STU STUD  DTYP BIO V2 KE KA VM KM V3 Q K23 K32 
  FIRSTONLY NOAPPEND NOHEADER NOPRINT FORMAT=S1PE17.9E2
  FILE=DUPILUMAB.PAR 

$TABLE  ID STU AMT DTYP ETA1 ETA2 ETA3 ETA4
  FIRSTONLY NOAPPEND NOHEADER NOPRINT FORMAT=S1PE17.9E2
  FILE=DUPILUMAB.ETA 

;222222222222222222222222222222222222222222222222222222222222222222222222222222
$PROBLEM OUTPUT FOR PLOTS

$INPUT ID STU STUD TIME NOM_DAY DOSE=AMT DTYP RATE CP=DV DVVSE MDV EVID CMT PCMT 
       DP DPKG DCH DBY TYPE WT LWT H HM HML 

$DATA ..\SIMULATED_DUPILUMAB.CSV WIDE REWIND IGNORE S
$MSFI DMORE.MSF

$EST NSIG=3 SIGL=9 NOABORT PRINT=1 CONSTRAIN=5
  METHOD=SAEM NBURN=0 NITER=0 POSTHOC INTERACTION
  LAPLACIAN DERCONT=1 GRD=TG(1-8):TS(9) CTYPE=3 CINTERVAL=10 

$TABLE ID STU STUD TIME NOM_DAY DTYP DOSE CP IPRE IWRE MDV EVID CMT PCMT DP DPKG DCH DBY
  A1 A2 A3 A4 DP DPKG TYPE WT
  NOHEADER APPEND NOPRINT FORMAT=S1PE17.9E2 FILE=DUPILUMAB.fi



