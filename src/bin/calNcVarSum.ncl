
begin
; this script is to cal average value of all variables in given files

File = getenv("FILE")
var = getenv("VAR")

print("file = " + File + ", var = " + var)

f = addfile(File, "r")

varList = getfilevarnames(f)

if (var .eq. "all" .or. var .eq. "ALL") then
do i = 0, dimsizes(varList) - 1
    varName = varList(i)
    dtT := f->$varName$
    if (.not. isnumeric(dtT)) then
        continue
    end if
    sumV := sum(dtT)
    print("sum value: " + varName + " -> " + sumV)
end do

else
    dtT = f->$var$
    sumV = sum(dtT)
    print("mean value: " + var + " -> " + sumV)
end if


end
