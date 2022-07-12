*! version 1.1  12July2022
*Authors: Daniel HOMOCIANU & Dinu AIRINEI
*Ex1.: pcdm4mp C033   *Ex2.: pcdm4mp C033, xcpu(4)   *Ex3.: pcdm4mp wq727_, xcpu(8) disk("C")
program define pcdm4mp
 version 16.0 
 syntax varlist [, xcpu(real 2) disk(string)]
 local datetime = "`c(current_date)' `c(current_time)'"
 di "PCDM4MP STARTED AT: `datetime'"
 local k : word count `varlist' 
 if `k'<1  {
    di as error " Error: Provide the target variable!" 
    exit
 }
 if `k'>1  {
    di " Warning: For MP tasks only the 1st variable (target) will be considered!" 
 }
 local Y : word 1 of `varlist'
 ***get the path of the current dataset and its no.of vars.***
 local dataset="`c(filename)'"
 local dsetnvars=`c(k)'+150
 if `dsetnvars' < 2048 {
  local dsetnvars=2048
 }
 if `dsetnvars' > 120000 {
  di as error " Error: The dataset is too large (>120000 vars.)!" 
  exit
 }
 if missing("`dataset'") {
  di as error " Error: First you must open a dataset!"
  exit
 }
 ***check the CPU config.***
 local nproc : env NUMBER_OF_PROCESSORS
 local xc=2
 if !missing("`xcpu'") { 
  if `xcpu'>=2 & `xcpu'<=`nproc' {
   local xc=int(`xcpu')
  }
  else {
    di as error " Error: Provide at least 2 logical CPU cores (but no more than `nproc') for MP tasks!"
    exit
  }
 }
 local dsk="C"
 if !missing("`disk'") { 
  if "`disk'"<="z" | "`disk'"<="Z" {
   local dsk="`disk'"
  }
  else {
   di as error " Error: Provide a valid disk letter!"
   exit
  }
 }
 di "pcdm4mp will save temporary results at `dsk':\StataMPtasks and also below!"
 ***Generating the "main_do_file.do" MP template***
 local smpt_path="`dsk':\StataMPtasks\"
 shell rd "`smpt_path'" /s /q
 qui mkdir "`smpt_path'"
 local full_do_path="`smpt_path'\main_do_file.do"
 local q_subdir="queue"
 qui mkdir `"`smpt_path'/`q_subdir'"'
 local queue_path="`smpt_path'\`q_subdir'"
 local l_subdir="logs"
 qui mkdir `"`smpt_path'/`l_subdir'"'
 local logs_path="`smpt_path'\`l_subdir'"
 qui file open mydofile using `"`full_do_path'"', write replace
 file write mydofile "clear all" _n
 file write mydofile "log using "
 file write mydofile `"""'
 file write mydofile "`logs_path'\log"
 file write mydofile "`"
 file write mydofile  "1"
 file write mydofile "'"
 file write mydofile ".txt"
 file write mydofile `"""'
 file write mydofile ", text" _n
 file write mydofile "set maxvar `dsetnvars'" _n
 file write mydofile "use `Y' "
 file write mydofile "`"
 file write mydofile "2"
 file write mydofile "'"
 file write mydofile "* using "
 file write mydofile `"""'
 file write mydofile "`dataset'"
 file write mydofile `"""' _n
 file write mydofile "pcdm "
 file write mydofile "`Y' "
 file write mydofile "`"
 file write mydofile "2"
 file write mydofile "'"
 file write mydofile "* " _n
 file write mydofile "log close"
 qui file close mydofile
 ***Finding the Stata dir.***
 local _sys="`c(sysdir_stata)'"
 local exec : dir "`_sys'" files "Stata*.exe" , respect
  foreach exe in  `exec' {
    if inlist("`exe'","Stata.exe","Stata-64.exe","StataMP.exe","StataMP-64.exe","StataSE.exe","StataSE-64.exe") {
        local curr_st_exe  `exe'
	continue, break
   } 
 } 
 local st_path="`_sys'"+"`curr_st_exe'"
 capture confirm file `"`_sys'`curr_st_exe'"'
 if _rc !=0 {
  di as error "Stata's sys dir and executable NOT found!"
  exit
 }
 else {
  di "!!!Stata's sys dir and executable found: `st_path' !!!"
 }
 ***Creating and configuring .do files***
 clear all
 set maxvar `dsetnvars'
 use `dataset'
 local k=0
 foreach letter in `c(alpha)' & `c(ALPHA)' {
  if "`letter'"<="z" | "`letter'"<="Z" {
   capture ds `letter'*
   if !_rc {
     local k =`k' + 1
     if `k'<10 {
      qui file open mydofile using `queue_path'\job0`k'.do, write replace
      qui file write mydofile `"do "`dsk':\StataMPtasks\main_do_file.do" 0`k' `letter'"'
     }
     if `k'>=10 {
      qui file open mydofile using `queue_path'\job`k'.do, write replace
      qui file write mydofile `"do "`dsk':\StataMPtasks\main_do_file.do" `k' `letter'"'
     }
     file close mydofile
   }
  }
 }
 ***Allocating .do tasks to CPU using qsub v.13.1 (06/10/2015), created by Adrian Sayers.***
 *ssc install qsub, replace
 if `xc'>`k' {
  local xc=`k'
 }
 qsub , jobdir(`queue_path') maxproc(`xc') statadir(`st_path') deletelogs
 ***Printing logs for all .do tasks in the main session's console***
 local mylogs : dir "`logs_path'" files "*.txt"
 local k=0
 foreach entry in `mylogs' {
    local k =`k' + 1
    if `k'<10 {
    type "`logs_path'\log0`k'.txt"
    }
    if `k'>=10 {
    type "`logs_path'\log`k'.txt"
    }
 }
 local datetime = "`c(current_date)' `c(current_time)'"
 di "PCDM4MP FINISHED AT: `datetime'"
end