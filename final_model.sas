PROC IMPORT OUT= WORK.train
            DATAFILE= "H:\ownership\besttrain.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

PROC IMPORT OUT= WORK.valid
            DATAFILE= "H:\ownership\bestvalid.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;



ODS GRAPHICS ON;

PROC LOGISTIC DATA = train OUTEST = BETAS COVOUT PLOTS(MAXPOINTS=1000);
*CLASS SHIFT / PARAM =REF;
class shift (ref = "1") for_type (ref = "100") for_2003 (ref = "100") stdSIZ1  (ref = "1") SITECL (REF = "1")
agecl (ref = "1") slpcl (ref = "1") aspcl (ref = "0") sicl (ref = "1") elevcl (ref = "1")
urbcl (ref = "1") rdcl (ref = "1") dencl (ref = "1") aspcl2 (ref = "F");

MODEL SHIFT = for_2003 DISURBKM DISRDKM DISSMKM DEN_KM2 BALIVE1 SICND1 STDAGE1 STDSIZ1 SITECL aspcl2 /rsq link = glogit selection = backward slstay=0.1  DETAILS LACKFIT CTABLE EXPB outroc = ROCData pprob= 0.6;


*MODEL SHIFT = for_2003 DISURBKM DISRDKM DISSMKM DEN_KM2 ELEV1 SLOPE1 ASPECT1 BALIVE1 SICND1 STDAGE1 STDSIZ1 SITECL/rsq link = glogit selection = stepwise slentry = 0.2 slstay = 0.1 DETAILS LACKFIT CTABLE EXPB outroc = ROCData pprob= 0.6;
score data = valid out = out_valid outroc =vroc;
output out = out_train predprobs = (individual) ;
run;
