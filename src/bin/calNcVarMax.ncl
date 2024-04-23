
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
    if (typeof(dtT) .eq. "string") then
        continue
    end if
    maxV := max(dtT)
    print("max value: " + varName + " -> " + maxV)
end do

else
    dtT = f->$var$
    maxV = avg(dtT)
    print("max value: " + var + " -> " + maxV)
end if


end
