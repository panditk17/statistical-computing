PROC IMPORT OUT= WORK.LOGISTIC 
            DATAFILE= "H:\ownership\bothdata.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;



data logistic;
set logistic;
if shift = "4"  then delete;
run;


proc sort data=logistic;
by for_2003;
run;

proc freq data =logistic;
table for_2003 * shift;
run;
 
proc freq data =logistic;
table for_type * shift;
run;

DATA LOGISTIC;
SET LOGISTIC;
DISURBKM = DIS_URB/1000;
DISRDKM = DIS_RD/1000;
DISSMKM = DIS_SM/1000;
RUN;


ODS GRAPHICS ON;

proc sort data = logistic;
by shift;
run;

*%let K=4;
*%let rate=%sysevalf((&K-1)/&K);

*generate sample with replicates;

proc surveyselect data=logistic out = cv 
method = srs n = (133 49 29)outall reps = 1;
strata shift;
run;

data train;
set cv;
if selected = 0 then output ;
run;

data valid;
set cv;
if selected = 1 then output ;
run;


PROC EXPORT DATA= WORK.TRAIN
            OUTFILE= "h:\ownership\TRAIN1.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

PROC EXPORT DATA= WORK.VALID
            OUTFILE= "h:\ownership\VALID1.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;




PROC LOGISTIC DATA = train OUTEST = BETAS COVOUT PLOTS(MAXPOINTS=1000);
*CLASS SHIFT / PARAM =REF;
class shift (ref = "1") for_type (ref = "100") for_2003 (ref = "100") stdSIZ1  (ref = "1") SITECL (REF = "1")
agecl (ref = "1") slpcl (ref = "1") aspcl (ref = "0") sicl (ref = "1") elevcl (ref = "1")
urbcl (ref = "1") rdcl (ref = "1") dencl (ref = "1") aspcl2 (ref = "F");

MODEL SHIFT = for_2003 DISURBKM DISRDKM DISSMKM DEN_KM2 BALIVE1 SICND1 STDAGE1 STDSIZ1 SITECL aspcl2 /rsq link = glogit selection = backward slstay=0.05  DETAILS LACKFIT CTABLE EXPB outroc = ROCData pprob= 0.6;


*MODEL SHIFT = for_2003 DISURBKM DISRDKM DISSMKM DEN_KM2 ELEV1 SLOPE1 ASPECT1 BALIVE1 SICND1 STDAGE1 STDSIZ1 SITECL/rsq link = glogit selection = stepwise slentry = 0.2 slstay = 0.1 DETAILS LACKFIT CTABLE EXPB outroc = ROCData pprob= 0.6;
score data = valid out = out_valid outroc =vroc;
output out = out_train predprobs = (individual) ;
run;
