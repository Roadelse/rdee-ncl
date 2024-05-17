load "$NCL_C4"


undef("create_ioapi_nc")
procedure create_ioapi_nc(template, opt) ; only support FTYPE=1 and VGTYP=7 by now
local incf
begin
    setfileoption("nc","Format","NetCDF4Classic")
    setfileoption("nc","CompressionLevel",1)
    incf = addfile_crmo(opt@file)
    incf@IOAPI_VERSION = "ioapi-3.2: $Id: init3.F90 98 2018-04-05 14:35:07Z coats $                       "
    incf@EXEC_ID = "ncl                                                                            "
    if (isatt(template, "FTYPE")) then
        incf@FTYPE = template@FTYPE
    else
        incf@FTYPE = 1
    end if

    now = systemfunc("date +%Y%m%d%H%M%S")
    cwdate = toint(str_get_cols(now, 0, 7))
    cwtime = toint(str_get_cols(now, 8, 13))
    incf@CDATE = cwdate
    incf@CTIME = cwtime
    incf@WDATE = cwdate
    incf@WTIME = cwtime

    incf@TSTEP = 10000 ; 1 hour
    incf@NTHIK = 1
    if (isatt(template, "NCOLS")) then
        ; incf@NCOLS = template@NCOLS
        ; incf@NROWS = template@NROWS
        incf@GDTYP = template@GDTYP
        incf@P_ALP = template@P_ALP
        incf@P_BET = template@P_BET
        incf@P_GAM = template@P_GAM
        incf@XCENT = template@XCENT
        incf@YCENT = template@YCENT
        ; incf@XORIG = template@XORIG
        ; incf@YORIG = template@YORIG
        incf@XCELL = template@XCELL
        incf@YCELL = template@YCELL
        incf@VGTYP = template@VGTYP
        incf@VGTOP = template@VGTOP
        ; incf@NLAYS = template@NLAYS
        ; incf@NVARS = template@NVARS
        incf@VGLVLS = template@VGLVLS
    else
        ; incf@NCOLS = opt@cols
        ; incf@NROWS = opt@rows
        incf@GDTYP = 2
        incf@P_ALP = opt@lat1
        incf@P_BET = opt@lat2
        incf@P_GAM = opt@lon1
        incf@XCENT = opt@lon0
        incf@YCENT = opt@lat0
        ; incf@XORIG = opt@XORIG
        ; incf@YORIG = opt@YORIG
        incf@XCELL = opt@DX
        incf@YCELL = opt@DY
        incf@VGTYP = 7 ; 
        incf@VGTOP = 5000.
        incf@VGLVLS = incf@VGLVLS
        ; incf@NALYS
        ; incf@NVARS
    end if

    incf@VGTYP = 7 ; 
    incf@VGTOP = 5000.
    incf@GDNAM = opt@GDNAM
    incf@UPNAM = ""
    ; incf@VAR-LIST
    incf@FILEDESC = ""
    incf@HISTORY = ""
end

undef("set_ioapi_var")
procedure set_ioapi_var(varname, data, template, opt)
begin
    incf = addfile(opt@file, "w")
    data!0 = "TSTEP"
    data!1 = "LAY"
    data!2 = "ROW"
    data!3 = "COL"
    if (.not. isatt(incf, "NLAYS")) then
        incf@NLAYS = dimsizes(data(0, :, 0, 0))
        incf@NROWS = dimsizes(data(0, 0, :, 0))
        incf@NCOLS = dimsizes(data(0, 0, 0, :))
        incf@NSTEPS = dimsizes(data(:, 0, 0, 0))
    end if

    if (isatt(template, "long_name") .and. isatt(template, "units") .and. isatt(template, "var_desc")) then
        copy_VarAtts(template, data)
    elseif ((.not. isatt(data, "units")) .and. (.not. isatt(opt, "units"))) then
            print("ioapi netcdf variable need attributes!")
            exit()
    end if
    incf->$varname$ = data
end

undef("buildDate")
function buildDate(init, step, nstep)
begin
    dateG_series = new (nstep, double)
    format = "%Y%J%H%M%S"
    format@units = "seconds since 2010-01-01 00:00:00"
    init_gre = cd_inv_string(init, format)
    dateG_series(0) = init_gre
    do i = 1, nstep - 1
        dateG_series(i) = dateG_series(i - 1 ) + step
    end do


    return gre2dt_ioapi(dateG_series)

end


undef("render_ioapi_TVG")
procedure render_ioapi_TVG(opt)   ; time info / var-list / grid info
local TFLAG, incf, vars, attrName, varList, blanks, rspace
begin
    incf = addfile(opt@file, "w")

    ; ===== render VAR-LIST
    vars = getfilevarnames(incf)
    attrName = "VAR-LIST"
    varList = ""
    do i_v = 0, dimsizes(vars) - 1
        numSpace = 16 - strlen(vars(i_v))
        rspace = str_sub_str(sprinti("%0" + numSpace + "d", 0), "0", " ")
        varList = varList + vars(i_v) + rspace
    end do
    incf@$attrName$ = varList

    ; ===== render TFLAG
    TFLAG_1s = toint(buildDate(opt@SDH_YJHMS, 3600, incf@NSTEPS))
    TFLAG = new ((/incf@NSTEPS, dimsizes(vars), 2/), integer)
    do i = 0, dimsizes(vars) - 1
        TFLAG(:, i, :) = TFLAG_1s
    end do
    TFLAG!0 = "TSTEP"
    TFLAG!1 = "VAR"
    TFLAG!2 = "DATE-TIME"
    TFLAG@units = "<YYYYDDD,HHMMSS>"
    TFLAG@long_name = "TFLAG"
    TFLAG@var_desc = "Timestep-valid flags:  (1) YYYYDDD or (2) HHMMSS"
    incf->TFLAG = TFLAG

    ; ===== render STIME and SDATE
    incf@SDATE = toint(str_get_cols(opt@SDH_YJHMS, 0, 6))
    incf@STIME = toint(str_get_cols(opt@SDH_YJHMS, 7, 12))

    ; ===== render X/Y ORIG and others
    incf@XORIG = todouble(opt@XORIG)
    incf@YORIG = todouble(opt@YORIG)

    incf@NVARS = dimsizes(vars)
    ; delete(incf@NSTEPS)

end
