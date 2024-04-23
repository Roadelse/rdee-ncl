
; begin

file_src = getenv("NCFILE_SRC")
file_dst = getenv("NCFILE_DST")

if (.not.fileexists(file_dst)) then
    system("cp " + file_src + " " + file_dst)
else
    f_src = addfile(file_src, "r")
    f_src_varnames = getfilevarnames(f_src)
    f_dst = addfile(file_dst, "w")
    do i_v = 0, dimsizes(f_src_varnames) - 1
        vn = f_src_varnames(i_v)
	print("merge variable : " + vn)
        f_dst->$vn$ = f_src->$vn$
    end do
end if


; end
