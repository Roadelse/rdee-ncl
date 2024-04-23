
; this script contains customized functions/procedures, extending basic ncl grammar
; category : base



;**********************************************************************
; Implementation of "assert" from python
;**********************************************************************
undef("assert")
procedure assert(L, hint)
; L - logical variable, True or False, length = 1
; hint - string, sentence to be shown if L == False
begin
    if (typeof(L) .ne. "logical") then
        print("<assert> need logical arg-L, now is " + typeof(L))
        exit()
    end if
    if (dimsizes(L) .gt. 1) then
        print("<assert> need 1-length arg-L, now is " + dimsizes(L))
        exit()
    end if
    if (.not. L) then
        print("<assert> " + hint)
        exit()
    end if
end



;**********************************************************************
; Ensure existence of target directory. If not, just create it
;**********************************************************************
undef("ensureDirExists")
procedure ensureDirExists(dir)
begin
    if (.not. fileexists(dir))
        system("mkdir -p " + dir)
    end if
end



;**********************************************************************
; Create a file and remove the previous one if existed
; extend function <addfile>
;**********************************************************************
undef("addfile_crmo")  ; addfile, create. remove thd old one if exists
function addfile_crmo(filename)
local filename_fixEscape, f
begin
    filename_fixEscape = str_sub_str(filename, "&", "\&")
    if (fileexists(filename)) then
        system("rm -f " + filename_fixEscape)
    end if
    ensureDirExists(systemfunc("dirname " + filename_fixEscape))
    f = addfile(filename, "c")
    return f
end 



;**********************************************************************
; Create a file or open it with w-authority if existed
; extend function <addfile>
;**********************************************************************
undef("addfile_wc")  ; addfile, open. create if it doesn't exist
function addfile_wc(filename)
begin
    if (fileexists(filename)) then
        f = addfile(filename, "w")
    else
        f = addfile(filename, "c")
    end if
    return f
end



;**********************************************************************
; Check dimensions of data
;**********************************************************************
undef("checkDim")
procedure checkDim(data, dims, vname)
; dims : suggested dimension sizes
; vname : variable name
begin
    if (any(dimsizes(data) .ne. dims)) then
        print("dimension error for " + vname)
        exit()
    end if
end



;**********************************************************************
; test dimension names of data (return True/False)
;**********************************************************************
undef("testDimName")
function testDimName(data, dimNames, vname)
; dimNames : suggested dimension names
; vname : variable name
local dataDNs
begin
    dataDNs = getVarDimNames(data)
    if (dimsizes(dataDNs) .ne. dimsizes(dimNames)) then
        return False
    end if
    if (any(dataDNs .ne. dimNames)) then
        return False
    end if
    return True
end



;**********************************************************************
; check dimension names of data
;**********************************************************************
undef("checkDimName")
procedure checkDimName(data, dimNames, vname)
; dimNames : suggested dimension names
; vname : variable name
begin
    if (any(getVarDimNames(data) .ne. dimNames)) then
        print("dimension name error for " + vname)
        exit()
    end if
end



;**********************************************************************
; Check an enum variables
;**********************************************************************
undef("checkENUM")
procedure checkENUM(tar, avail, vname)
; tar - target value
; avail - available values
; vname - variable name
begin
    flag = False
    if (typeof(tar) .ne. typeof(avail)) then
        print("<checkENUM> tar and avail should have the same type!")
        flag = False
    end if
    do i = 0, dimsizes(avail) - 1
        if (avail(i) .eq. tar) then
            flag = True
            break
        end if
    end do
    if (.not. flag) then
        print("Error! " + vname + " should be one of " + str_join(avail, ", "))
        exit()
    end if
end



;**********************************************************************
; Implementation of os.getenv from python 
;**********************************************************************
undef("getenv_secure")
function getenv_secure(envName, default)
local res
begin
    res = getenv(envName)
    if (ismissing(res)) then
        if (default .eq. "EXITTT") then
            print("no env " + envName + "! Error")
            exit()
        end if
        return default
    else
        return res
    end if
end



;**********************************************************************
; delete attribute if existed
;**********************************************************************
undef("deleteAtt_secure")
procedure deleteAtt_secure(var, atts)
; atts - attributes, array is ok
local i, att
begin
    do i = 0, dimsizes(atts) - 1
        att = atts(i)
        if (isatt(var, att)) then
            delete(var@$att$)
        end if
    end do
end 