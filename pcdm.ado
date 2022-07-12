version 1.0 /* authors: Daniel HOMOCIANU & Dinu AIRINEI, 05/22/2022 */
*Ex1.: pcdm C033 *
*Ex2.: pcdm C033 C031 C034 C036 C037 C038 C039 if S003==840
*Ex3.: pcdm C033 * if S003==840, minacc(0.15) minn(1000) maxp(0.001)
program define pcdm
syntax varlist [if] [, minacc(real 0) minn(real 1) maxp(real 0.05)]
local datetime = "`c(current_date)' `c(current_time)'"
di "PCDM STARTED AT: `datetime'"
local k : word count `varlist' 
 if `k'<2  {
   di as error " Error: Provide at least 2 variables!" 
   exit
 }
local y : word 1 of `varlist'
local xvarlist: list varlist -y
local npred=`k'-1
di "Outcome(y) Input(x) Correl.Coef.(CC) Abs.Val.CC(ACC) No.Obs.(Nobs) Signif.(p)"
local macc=0
local mn=1
local mp=0.05
if !missing("`minacc'") {
if `minacc'>=0 & `minacc'<=1 {
 local macc=`minacc'
 }
 else {
  di as err "Error: parameter minacc(min.ACC) must be >=0 and <=1!"
  exit
 } 
}
if !missing("`minn'") {
 if `minn'>=1 {
 local mn=`minn'
}
else {
 di as err "Error: parameter minn(min.Nobs.) must be an integer >=1!"
 exit
} 
}
if !missing("`maxp'") {
 if `maxp'>=0 & `maxp'<=0.05 {
  local mp=`maxp'
 }
 else {
  di as err "Error: parameter maxp(max.p) must be >=0 and <=0.05!"
  exit
 } 
}
local k=0
forvalues i = 1(1) `npred' {
local k =`k' + 1
local x : word `i' of `xvarlist'
capture pwcorr `y' `x' `if', sig
if _rc==0 {
 matrix crlv=vec(r(C))
 local CC=crlv[2,1]
 local ACC=abs(`CC')
 local Nobs = r(N)
 local p = r(sig)[2,1]
  if `ACC'>=`macc' & `p'<=`mp' & `Nobs'>=`mn' di "`y' `x' `CC' `ACC' `Nobs' `p'"
 }
local perc=int(`k'/`npred'*100)
window manage maintitle "Step `k' of `npred' (`perc'% done)!" 
}
window manage maintitle "Stata"
local datetime = "`c(current_date)' `c(current_time)'"
di "PCDM FINISHED AT: `datetime'"
end