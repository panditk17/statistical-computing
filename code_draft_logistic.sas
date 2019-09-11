PROC IMPORT OUT= WORK.all
            DATAFILE= "H:\ownership\new_change_data_industrial_forest.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;



ODS GRAPHICS ON;

PROC LOGISTIC DATA = all OUTEST = BETAS COVOUT PLOTS(MAXPOINTS=1000);
*CLASS SHIFT / PARAM =REF;
class ind2ins (ref = "1") for_2003 (ref = "100") stdSIZ1  (ref = "1") ;


MODEL ind2ins = for_2003 DISURBKM DISRDKM DISSMKM DEN_KM2 ELEV1 SLOPE1 BALIVE1 SICND1 STDAGE1 STDSIZ1 tempmin tempmax pptinch /rsq link = glogit selection = forward slstay=0.15  DETAILS LACKFIT CTABLE EXPB outroc = ROCData pprob= 0.6;


*MODEL SHIFT = for_2003 DISURBKM DISRDKM DISSMKM DEN_KM2 ELEV1 SLOPE1 ASPECT1 BALIVE1 SICND1 STDAGE1 STDSIZ1 SITECL/rsq link = glogit selection = stepwise slentry = 0.2 slstay = 0.1 DETAILS LACKFIT CTABLE EXPB outroc = ROCData pprob= 0.6;
score data = all out = out_valid outroc =vroc;
output out = out_train predprobs = (individual) ;
run;


proc delete data = outstats_valid;
run;

%macro one ;
*(start = 0.5, stop = 0.7, step = 0.05);
%let x = 0.58;
%let xstop = 0.58;
%let xstep = 0.01;

%do %until (%sysevalf(&x gt &xstop));
%put x = &x;


%let y= 0.58;
%let ystop = 0.58;
%let ystep = 0.01;
%do %until (%sysevalf(&y gt &ystop));
%put y = &y;


data out_valid;
set out_valid;
if p_1 LT &x and p_2 GT (&y * (1-p_1)) then class1 = 2;
if p_1 LT &x and p_2 LE (&y * (1-p_1)) then class1 = 3;
else if p_1 GE &x then class1 = 1; 
run;


data out_valid;
set out_valid;
if shift = class1 then correct = 1;
else if shift NE class1 then correct = 0;
run;

data out_valid;
set out_valid;
if shift = "1" and class1 ="1" then cor_1 = 1;
else cor_1 = 0;
run;

data out_valid;
set out_valid;
if shift = "2" and class1 ="2" then cor_2 = 1;
else cor_2 = 0;
run;

data out_valid;
set out_valid;
if shift = "3" and class1 ="3" then cor_3 = 1;
else cor_3 = 0;
run;



data out_valid;
set out_valid;
ref_1 = 0;
ref_2 = 0;
ref_3 = 0;
if shift = "1" then ref_1 = 1;
if shift = "2" then ref_2 = 1;
if shift = "3" then ref_3 = 1;
run;

data out_valid;
set out_valid;
cls_1 = 0;
cls_2 = 0;
cls_3 = 0;
if class1 = "1" then cls_1 = 1;
if class1 = "2" then cls_2 = 1;
if class1 = "3" then cls_3 = 1;
run;


proc means data = out_valid sum; 
var correct cor_1 cor_2 cor_3 ref_1 ref_2 ref_3 cls_1 cls_2 cls_3;
output out = summary_valid sum(cor_1 cor_2 cor_3 ref_1 ref_2 ref_3 cls_1 cls_2 cls_3) = sumcor1 sumcor2 sumcor3 sumref1 sumref2 sumref3 sumcls1 sumcls2 sumcls3;
run;


data summary_valid;
set summary_valid;
omer1 = sumcor1/sumcls1;
omer2 = sumcor2/sumcls2;
omer3 = sumcor3/sumcls3;

totcor = sumcor1+sumcor2+sumcor3;
totall = sumcls1 + sumcls2 + sumcls3;

multi = sumref1*sumcls1 + sumref2*sumcls2 + sumref3*sumcls3;

overacc = totcor/totall;

kappa = ((totall * totcor) - (multi))/((totall*totall) - multi);

randacc = ((sumref1*sumref1) + (sumref2*sumref2) + (sumref3*sumref3))/(totall*totall);

increase = (overacc - randacc)/randacc;


x = &x;
y = &y;
run;


proc append base = outstats_valid data = summary_valid;
run;

%let y = %sysevalf(&y + &ystep);

%end;

%let x = %sysevalf(&x + &xstep);

%end;
%mend;
%one ();



*proc sort data = out_valid;
*by k;
*run;

*data kout;
*set out_valid (obs =1);
*run;

*proc print data = kout;
*run;





PROC EXPORT DATA= WORK.out_valid
            OUTFILE= "h:\ownership\valpred_2.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;


PROC EXPORT DATA= WORK.summary_valid
            OUTFILE= "h:\ownership\summary_2.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;


proc sort data= outstats_valid;
by descending kappa;
run;

PROC EXPORT DATA= WORK.outstats_valid
            OUTFILE= "h:\ownership\output_2.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;


*PROC EXPORT DATA= WORK.outstats_train
            OUTFILE= "h:\ownership\output_train1.csv" 
            DBMS=CSV REPLACE;
 *    PUTNAMES=YES;
* RUN;
