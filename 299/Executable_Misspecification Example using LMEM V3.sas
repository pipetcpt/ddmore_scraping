﻿dm 'clear log';
dm 'clear list';
libname cdrive "C:\Users\am00402567\Desktop\C-QT Modeling\Misspecification Example";
proc datasets kill; run;
options ls=130;
title;
ods listing;
ods html close;

proc format;
	value doselabel 1='Placebo' 2='100 mg' 3='500 mg' 4='750 mg' 5='1000 mg';
run; quit;

data concqt;
	set cdrive.concqt;
	dv = conc;
	index = 1;
proc sort; by sid dose nomtime; run; quit;

proc mixed data=concqt method=ml convf=1E-6;
	class sid nomtime trt(ref="0");
	model dqtcf = trt nomtime chgbase dv / ddfm=kr solution;
	random intercept dv / subject=sid type=simple;
run; quit;


* Linear model analyzed using Proc NLMIXED    NOTE:  CONC/10000;
proc nlmixed data=concqt;
	parms theta1=-3.7, theta2=8.1, theta3=-0.6, theta4=0.8, theta5=0.3, theta6=0.8, theta7=-0.9, theta8=-0.7, theta9=0.9, theta10=-0.3, theta11=0.1, theta12=0, std1=2.2, std2=0.001, sigma=5;
	bounds std1>0, std2>0, sigma > 0;
	intercept = theta1 + eta1;
	slope = theta12 + eta2;
	drugeffect = slope*dv;
	pred = intercept + theta2*trt + theta3*time1 + theta4*time2 + theta5*time3 + theta6*time4
		+ theta7*time5 + theta8*time6 + theta9*time7 + theta10*time8 + theta11*chgbase + drugeffect;
	residuals = pred - dqtcf;
	model dqtcf ~ normal(pred, sigma*sigma);
	random eta1 eta2  ~ normal([0,0], [std1*std1, 0, std2*std2]) subject=sid;
	estimate 'Variance(ETA1)' std1*std1;
	estimate 'Variance(ETA2)' std2*std2;
	estimate 'Residual Variance' sigma*sigma;
	estimate '87.4' theta2 + theta12*87.4 alpha=0.10;
	estimate '172.46' theta2 + theta12*172.46 alpha=0.10;
	estimate '462.45' theta2 + theta12*462.45 alpha=0.10;
	estimate '886.16' theta2 + theta12*886.16 alpha=0.10;
	estimate '1240.74' theta2 + theta12*1240.74 alpha=0.10;
	estimate '1727.56' theta2 + theta12*1727.56 alpha=0.10;
	estimate '2196.63' theta2 + theta12*2196.63 alpha=0.10;
	estimate '2595.18' theta2 + theta12*2595.18 alpha=0.10;
	estimate '3194.85' theta2 + theta12*3194.85 alpha=0.10;
	predict pred out=pred;
	predict residuals out=residuals;
	ods output parameterestimates=parms;
run; quit;

data residuals; set residuals; index = 1; proc sort; by index; run; quit;
proc means data=residuals std; var pred; output out=stdev std=sigma; run; quit;
data stdev; set stdev; index=1; proc sort; by index; run; quit;
data stdres(keep=residuals Standardized_Residuals);
	merge residuals stdev;
	by index;
	residuals = pred;
	Standardized_Residuals = pred/sigma;
	label Standardized_Residuals = "Standardized Residual";
	label residuals = "Residual";
run; quit;
proc univariate normal data=stdres; var residuals; run;

data merged;
	merge pred stdres;
run; quit;


*** Compute Deciles;
proc univariate data=concqt;
	var conc;
	output out=deciles pctlpre=deciles pctlpts=0 to 100 by 10;
run; quit;
data deciles; set deciles; index = 1; proc sort; by index; run; quit;

data set1;
	merge concqt deciles;
	by index;
	decile = 1;
	if conc > deciles10 and conc <= deciles20 then decile = 2;
	if conc > deciles20 and conc <= deciles30 then decile = 3;
	if conc > deciles30 and conc <= deciles40 then decile = 4;
	if conc > deciles40 and conc <= deciles50 then decile = 5;
	if conc > deciles50 and conc <= deciles60 then decile = 6;
	if conc > deciles60 and conc <= deciles70 then decile = 7;
	if conc > deciles70 and conc <= deciles80 then decile = 8;
	if conc > deciles80 and conc <= deciles90 then decile = 9;
	if conc > deciles90 and conc <= deciles100 then decile = 10;
proc sort; by decile; run; quit;



*** Code to make Decile Plot;

proc transpose data=parms out=parmst; var estimate; id parameter; run; quit;
data parmst; set parmst; index = 1; proc sort; by index; run; quit;

proc transpose data=parms out=parmset prefix=se_; var standarderror; id parameter; run; quit;
data parmset; set parmset; index = 1; proc sort; by index; run; quit;

proc means data=set1 alpha=0.10 mean std stderr clm n noprint;
	var dqtcf conc;
	by decile;
	output out=mean mean=obsmean meanconc p5=obsp5 p95=obsp95 lclm=obslowerclm uclm=obsupperclm;
run; quit;
proc print; run;

data sim;
	merge parmst parmset deciles;
	do simconc = 0 to 4000 by 100;
		do sim = 1 to 1000;
			theta2a = theta2 + rannor(2345232)*se_theta2;
			theta12a = theta12 + rannor(2345213)*se_theta12;
			preddqtcf = theta2a + theta12a*simconc;
			decile = 1;
			if simconc > deciles10 and simconc <= deciles20 then decile = 2;
			if simconc > deciles20 and simconc <= deciles30 then decile = 3;
			if simconc > deciles30 and simconc <= deciles40 then decile = 4;
			if simconc > deciles40 and simconc <= deciles50 then decile = 5;
			if simconc > deciles50 and simconc <= deciles60 then decile = 6;
			if simconc > deciles60 and simconc <= deciles70 then decile = 7;
			if simconc > deciles70 and simconc <= deciles80 then decile = 8;
			if simconc > deciles80 and simconc <= deciles90 then decile = 9;
			if simconc > deciles90 then decile = 10;
			output;
		end;
	end;
	label preddqtcf = "Predicted Value for Mean";
proc sort; by decile; run; quit;

proc means data=sim noprint alpha=0.10;
	var preddqtcf simconc;
	by decile;
	output out=simpercentiles mean=predmean simconc p5=predp5 pred2p5 p95=predp95 pred2p95;
run; quit;
data simpercentiles;
	set simpercentiles;
	label predmean = "Predicted Mean";
	label simconc = "Simulated Mean Concentration";
	label predp5 = "5th Percentile of Mean Prediction";
	label predp95 = "95th Percentile of Mean Prediction";
proc print label; run;

data decileplot;
	merge mean simpercentiles;
	by decile;
run; quit;
data decileplot;
	set decileplot;
	label predmean = "Predicted Mean";
	label simconc = "Simulated Mean Concentration";
	label predp5 = "5th Percentile of Mean Prediction";
	label predp95 = "95th Percentile of Mean Prediction";
 	label obsp5 = "Observed 5th Percentile";	
	label obsp95 = "Observed 95th Percentile";	
	label lclm = "Observed Lower 90% CI";	
	label uclm = "Observed Upper 90% CI"; run; quit;
proc print label; run;
		
/***

ods graphics on/ reset width=6 in border=off reset=index;
ods html style=statistical image_dpi=300;
	proc sort data=merged; by doselabel dqtcf; run; quit;
	proc sgplot data=merged;
		series x=dqtcf y=dqtcf / lineattrs=(color=black);
		loess x=dqtcf y=pred / nomarkers alpha=0.1 clm;
		scatter x=dqtcf y=pred / group=doselabel name="doses";
		format doselabel doselabel.;
		keylegend "doses" / across=1 location=inside position=nw  title="Dose";
		yaxis label="Predicted Change from Baseline QTcF Interval (msec)";
	run; quit;
	proc univariate data=merged normal;
		title "";
		var Standardized_Residuals;
		histogram Standardized_Residuals / normal kernel;
		qqplot Standardized_Residuals / normal(mu=est sigma=est color=red l=2);
	run; quit;
	proc sgplot data=merged;
		loess x=conc y=Standardized_Residuals / nomarkers alpha=0.1 clm smooth=0.6;;
		scatter x=conc y=Standardized_Residuals / group=doselabel name="doses";
		refline -2/ lineattrs=(pattern=2);
		refline 2/ lineattrs=(pattern=2);
		refline 0 / lineattrs=(pattern=1);
		format doselabel doselabel.;
		keylegend "doses" / across=5 location=inside position=ne  title="Dose";
		yaxis label="Standardized Residuals";
	run; quit;	
	proc sgplot data=merged;
		loess x=chgbase y=Standardized_Residuals / nomarkers alpha=0.1 clm;
		scatter x=chgbase y=Standardized_Residuals / group=doselabel name="doses";
		refline -2/ lineattrs=(pattern=2);
		refline 2/ lineattrs=(pattern=2);
		refline 0 / lineattrs=(pattern=1);
		format doselabel doselabel.;
		keylegend "doses" / across=5 location=inside position=ne  title="Dose";
		yaxis label="Standardized Residuals";
	run; quit;	
	proc sgplot data=merged;
		vbox Standardized_Residuals / category=timestr;
		refline -2/ lineattrs=(pattern=2);
		refline 2/ lineattrs=(pattern=2);
		refline 0 / lineattrs=(pattern=1);
		format doselabel doselabel.;
		keylegend "doses" / across=5 location=inside position=ne  title="Dose";
		yaxis label="Standardized Residuals";
	run; quit;	
	proc sgplot data=merged;
		series x=nomtime y=Standardized_Residuals / group=sid lineattrs=(color=lightgray);
		loess x=nomtime y=Standardized_Residuals / nomarkers alpha=0.1 clm;
		scatter x=nomtime y=Standardized_Residuals / group=dose;
		refline -2/ lineattrs=(pattern=2);
		refline 2/ lineattrs=(pattern=2);
		refline 0 / lineattrs=(pattern=1);
		format doselabel doselabel.;
		keylegend "doses" / across=5 location=inside position=ne  title="Dose";
		yaxis label="Standardized Residuals";
	run; quit;
	proc sgplot data=merged;
		vbox Standardized_Residuals / category=trtstr  name="doses";
		refline -2/ lineattrs=(pattern=2);
		refline 2/ lineattrs=(pattern=2);
		refline 0 / lineattrs=(pattern=1);
		yaxis label="Standardized Residuals";
	run; quit;	
*/
ods graphics on/ reset width=6 in border=off reset=index;
ods html style=statistical image_dpi =200;
	proc sort data=decileplot; by meanconc; run; quit;
	proc sgplot data=decileplot noautolegend;
		band x=simconc lower=predp5 upper=predp95  / fillattrs=(color="verylightblue");
		scatter x=meanconc y=obsmean / yerrorlower=obslowerclm yerrorupper=obsupperclm markerattrs=(color=blue symbol=circlefilled size=10) errorbarattrs=(color=blue thickness=2);
		scatter x=meanconc y=obsmean / yerrorlower=obsp5 yerrorupper=obsp95 markerattrs=(color=blue symbol=circlefilled size=10) errorbarattrs=(color=blue thickness=2 pattern=2);
		series x=simconc y=predmean / lineattrs=(color=black thickness=3);
		yaxis label="Change from Baseline QTcF Interval (msec)" grid;
		xaxis label="Drug Concentration";
	run; quit;
ods html close;
