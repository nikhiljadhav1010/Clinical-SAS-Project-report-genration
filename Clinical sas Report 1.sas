/*Importing excel data*/
FILENAME REFFILE '/home/u62978370/sasuser.v94/Guided_assignment/demog.xls';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLS
	OUT=WORK.Demog;
	GETNAMES=YES;
RUN;

/* Creating age dataset*/
data Demog1;
set Demog;
format DOB1 date9.;
DOB = compress(cat(MONTH, '/', DAY, '/', YEAR));
DOB1 = input(DOB, MMDDYY10.);
age = (DIAGDT - DOB1) / 365;
output;
trt = 2;
output;
run;

proc sort data= demog1;
by trt;
run;
proc means data=Demog1;
var age;
by trt;
output out = agestatics;
run;

data agestatics1;
set agestatics;
length Value $10.;
ord = 1;
if _STAT_='N' then do; subord =1; Value = strip(put(age, 8.0));end;
else if _STAT_='MIN' then do; subord =4; Value = strip(put(age, 8.1));end;
else if _STAT_='MAX' then do; subord =5; Value = strip(put(age, 8.1));end;
else if _STAT_='MEAN' then do; subord =2; Value = strip(put(age, 8.1));end;
else if _STAT_='STD' then do; subord =3; Value = strip(put(age, 8.2));end;

rename _STAT_ = stat;
drop _TYPE_ _FREQ_ age;
run;


/*Creating gender dataset*/
proc format;
value genfor
1 ="Male"
2= 'Female';
run;

data Demog2;
set Demog1;
sex = put(GENDER, genfor.);
run;

proc freq data=demog2 noprint;
table trt*sex /outpct out = genderstats;
run;

Data genderstats1;
set genderstats;
ord = 2;
if sex = 'Male' then subord = 1;
else subord = 2;
Value = (cat(COUNT, "(", strip(put(round(PCT_ROW, .1),8.1)),"%)"));
rename sex = stat;
drop COUNT PERCENT PCT_ROW PCT_COL;
run;

/* Creating Race dataset*/ 
proc format;
value racFor
1 ="White"
2 = "Black"
3 = "Hispanic"
4 = "Asian"
5 = "Other"
;
run;

data Demog3;
set Demog1;
Race_C = put(RACE, racFor.);
run;

proc freq data= demog3 noprint;
table trt*Race_C/ outpct out=Racestatics;
run;

Data Racestatics1;
set Racestatics;
ord = 3;
if Race_C="Asian" then subord = 1;
else if Race_C="Black" then subord = 2;
else if Race_C="Hispanic" then subord = 3;
else if Race_C="White" then subord = 4;
else if Race_C="Other" then subord = 5;
Value = (cat(COUNT, "(", strip(put(round(PCT_ROW, .1),8.1)),"%)"));
rename Race_C= stat;
drop COUNT PERCENT PCT_ROW PCT_COL;
run;

/*stacking all data together*/
Data all_stat;
set agestatics1 genderstats1 Racestatics1;
run;

proc sort data= all_stat;
by ord subord stat;
run;

/*Transposing Data*/
proc transpose data=all_stat out=T_all_stat prefix=_;
var Value;
id TRT; 
by ord subord stat;
run;

proc sql noprint;
select  count(*) into :Placebo from demog1 where trt = 0;
select  count(*) into :Active from demog1 where trt = 1;
select  count(*) into :Total from demog1 where trt = 2;
quit;

data final;
length stat $30;
	set T_all_stat;
	by ord subord;
	output;
	if first.ord then do;
		if ord = 1 then stat='Age (years)';
		if ord = 2 then stat='Gender';
		if ord = 3 then stat='Race';
		subord=0;
		_0="";
		_1="";
		_2="";
		output;
		end;
run;

proc sort;
by ord subord;
run;

%put Placebo=&Placebo;
%put Active=&Active;
%put Total=&Total;

/*creating report*/ 
Title 'Table 1.1';
Title2 'Demographic and Baseline Characteristics by Treatment Group';
Title3 'Randomized Population';
footnote 'Note : Percentages are based on the number of non-missing values in each treatment group';
proc report data= final split ='|';
columns ord subord stat _0 _1 _2;
define ord/ noprint order;
define subord/ noprint order;
define stat/ display width= 50 "";
define _0/ display width= 30 "Placebo| (N=&Placebo)" ;
define _1/ display width=30 "Active Treatment| (N=&Active)";
define _2/ display width= 30 "All Patient| (N=&Total)";
run;
