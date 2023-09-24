/*Importing the file*/
FILENAME REFFILE '/home/u62978370/sasuser.v94/Guided_assignment/projectDemog.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.Demog;
	GETNAMES=YES;
RUN;

/*Creating age Dataset*/
Data Demog_age;
set Demog;
format DOB1 date9.;
DOB = compress(cat(MONTH,'/',DAY,'/',YEAR));
DOB1= input(DOB, MMDDYY10.);
age = (DIAGDT - DOB1)/365.25;
output;
trt=2;
output;
run;

proc sort data=demog_age;
by trt;
run;

proc means data= demog_age noprint;
var age;
by trt;
output out=demog_age_1;
run;

Data Demog_age_2;
length Value $10.;
set demog_age_1;
ord = 1;
if _STAT_ = "N" then do; subord = 1; Value = strip(put(age,8.0));end;
if _STAT_ = "MIN" then do; subord = 4;  Value = strip(put(age,8.1));end;
if _STAT_ = "MAX" then do; subord = 5;  Value = strip(put(age,8.1));end;
if _STAT_ = "MEAN" then do; subord = 2;  Value = strip(put(age,8.1));end;
if _STAT_ = "STD" then do; subord = 3;  Value = strip(put(age,8.2));end;
rename _STAT_ =stat;
drop _TYPE_ _FREQ_ age;
run;

/*Creating age group dataset*/
proc format;
value agegrp
low-18 = '<=18 years'
18-65='18-65 years'
65-high='>65 years'
;
run;

data Demog_ageG;
	set Demog_age;
	ageG=put(age,agegrp.);
run;

proc freq data=demog_ageg noprint ;
table trt*ageG / outpct out = Demog_ageG_1;
run;

data Demog_ageG_2;
	set Demog_ageG_1;
	value = cat(count, ' (', strip(put(round(pct_row,.1),8.1)),'%)');
	ord =2;
	if ageG = '<=18 years' then subord=1;
	else if ageG = '18-65 years' then subord=2;
	else if ageG = '>65 years' then subord=3;	
rename ageG= stat;
drop count percent pct_col pct_row;
run;

/*creating gender dataset*/
data Demog_gender;
set Demog_age;
length sex $30.;
if GENDER = 1 then SEX='MALE';
else if GENDER = 2 then SEX ="FEMALE";
run;

proc freq data=Demog_gender noprint;
table trt*SEX /outpct out=Demog_gender_1;
run;

data Demog_gender_2;
set Demog_gender_1;
ord = 3;
if sex ="MALE" then subord =1;
else if sex = "FEMALE" then subord =2;
Value = Compress(cat(COUNT,"(",strip(Put(round(PCT_ROW, .1),9.1)),"%)"));
rename sex =stat;
drop COUNT PERCENT PCT_ROW PCT_COL;
run;

/*creating RACE dataset*/
Data Demog_race;
set demog_age;
Length RACE_C $15.;
if RACE = 1 then RACE_C ="WHITE";
else if RACE = 2 then RACE_C ="BLACK";
else if RACE = 3 then RACE_C ="HISPANIC";
else if RACE = 4 then RACE_C ="ASIAN";
else if RACE = 5 then RACE_C ="OTHER";
run;

proc freq data=demog_race noprint;
table trt*RACE_C /outpct out=demog_race_1;
run;

data demog_race_2;
set demog_race_1;
Value = Compress(cat(COUNT,"(",strip(Put(round(PCT_ROW, .1),9.1)),"%)"));
ord = 4;
if RACE_C ="WHITE" then subord =4;
else if RACE_C = "BLACK" then subord =2;
else if RACE_C = "HISPANIC" then subord =3;
else if RACE_C = "ASIAN" then subord =1;
else if RACE_C = "OTHER" then subord =5;
rename RACE_C =stat;
drop COUNT PERCENT PCT_ROW PCT_COL;
run;

/*stacking all data*/
Data allDemog;
set demog_age_2 Demog_ageG_2 Demog_gender_2 demog_race_2;
run;

/*Transposing Data*/
proc sort data=alldemog;
by ord subord stat ;
run;

proc transpose data= alldemog out= T_alldemog prefix=_;
var Value;
id trt;
by ord subord stat;
run;
proc sql noprint;
select count(*) into :Placebo from demog_age where trt = 0;
select count(*) into :Active from demog_age where trt = 1; 
select count(*) into :Total from demog_age where trt = 2;  
quit;
run;

Data final_demog;
length stat $30.;
	set T_alldemog;
	by ord subord;
	output;
	if first.ord then do;
		if ord = 1 then stat="Age (Years)";
		if ord = 2 then stat="Age Group";
		if ord = 3 then stat="Gender";
		if ord = 4 then stat="Race";
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
/* Creating report */
Title 'Table 1.1';
Title2 'Demographic and Baseline Characteristics by Treatment Group';
Title3 'Randomized Population';
footnote 'Note : Percentages are based on the number of non-missing values in each treatment group';
proc report data= final_demog split="|";
column ord subord stat _0 _1 _2;
define ord/ noprint order;
define subord/ noprint order;
define stat/ display width=50 "";
define _0/ display width=30 "Placebo | (N=&Placebo)";
define _1/ display width=30 "Active Treatment | (N=&Active)";
define _2/ display width=30 "ALL Patient | (N=&Total)";
run;
  


