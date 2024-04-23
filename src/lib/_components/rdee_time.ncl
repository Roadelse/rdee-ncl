

; Customized functions/procedures which are commonly used in my work
; category : time processing



;**********************************************************************
; This function is used to get YYYY from times such as YYYYMMDD, 
; YYYYMM, YYYYJJJ
;**********************************************************************
undef("getYYYY")
function getYYYY(date, opt)
local dateStr, YYYY, type
begin
    dateStr = "" + date
    YYYY = str_get_cols(dateStr, 0, 3)

    if (isatt(opt, "type")) then
        type = opt@type
    else
        type = "str"
    end if

    if (type .eq. "int") then
        return toint(YYYY)
    elseif (type .eq. "str") then
        return YYYY
    else
        print("unknown type " + type)
        exit()
    end if
end



;**********************************************************************
; This function is used to get MM from times such as YYYYMMDD, 
; YYYYMM
;**********************************************************************
undef("getMM")
function getMM(date, opt)
local dateStr, MM, type
begin
    dateStr = "" + date
    MM = str_get_cols(dateStr, 4, 5)
    if (isatt(opt, "type")) then
        type = opt@type
    else
        type = "str"
    end if
    if (type .eq. "int") then
        return toint(MM)
    elseif (type .eq. "str") then
        return MM
    else
        print("unknown type " + type)
        exit()
    end if
end



;**********************************************************************
; This function is used to get DD from times such as YYYYMMDD, 
; YYYYMM, YYYYJJJ
;**********************************************************************
undef("getDD")
function getDD(date, opt)
local dateStr
begin
    dateStr = "" + date
    DD = str_get_cols(dateStr, 6, 7)
    if (isatt(opt, "type")) then
        type = opt@type
    else
        type = "str"
    end if
    if (type .eq. "int") then
        return toint(DD)
    elseif (type .eq. "str") then
        return DD
    else
        print("unknown type " + type)
        exit()
    end if
end



;**********************************************************************
; This function is used to get seasons from months
;**********************************************************************
undef("month2season")
function month2season(m, opt)
; m : str like 01, 02, 03, ...... 12 
;   or integer from 1 to 12
; opt ->
;   @outMode : int/integer, name, string
; ---------------------------------
; return spring, summer, fall, winter 
;     or 0, 1, 2, 3
;     or "0", "1", "2", "3"
local outMode, mI, seasons, names
begin
    if (.not. isatt(opt, "outMode")) then
        outMode = "int"
    else
        outMode = opt@outMode
    end if

    if (typeof(m) .eq. "string") then
        mI = toint(m)
    elseif (typeof(m) .eq. "integer") then
        mI = m
    else
        print("argument-m should only be integer or string! Error, now is " + typeof(m))
        exit()
    end if
    seasons = new (dimsizes(mI), integer)
    seasons = where(mI .ge. 3 .and. mI .le. 5, 0, seasons)
    seasons = where(mI .ge. 6 .and. mI .le. 8, 1, seasons)
    seasons = where(mI .ge. 9 .and. mI .le. 11, 2, seasons)
    seasons = where(mI .le. 2 .or. mI .ge. 12, 3, seasons)

    if (outMode .eq. "int" .or. outMode .eq. "integer") then
        return seasons
    elseif (outMode .eq. "string" .or. outMode .eq. "str") then
        return sprinti("%02d", seasons)
    elseif (outMode .eq. "name") then
        names = (/"spring", "summer", "fall", "winter"/)
        return names(seasons)
    else
        print("argument-opt@outMode should be one of int/integer, name and string! Error,  now is " + outMode)
        exit()
    end if

end



;**********************************************************************
; This function is used to get season from times such as YYYYMMDD, 
; YYYYMM, YYYYJJJ
;**********************************************************************
undef("getSeasons")
function getSeasons(date, opt)
local dateStr, ms, type, ss
begin
    dateStr = "" + date
    ms = getMM(dateStr, True)

    if (isatt(opt, "type")) then
        type = opt@type
    else
        type = "str"
    end if

    opt_m2s = True
    opt_m2s@outMode = type
    ss = month2season(ms, opt_m2s)

    return ss
end



;**********************************************************************
; this scirpt is used to calcultae days between 2 dats
;**********************************************************************
undef("calDays")
function calDays(ymd1, ymd2, opt)
; ymd1, ymd2    : yyyymmdd like string
; opt -
;      calendar : ncl calendar, such as 365 days, ...
local units, calendar, opt_cic, ti1, ti2, rst
begin
    units = "days since 0001-01-01 00:00:00"
    calendar = "standard"
    if (isatt(opt, "calendar")) then
        calendar = opt@calendar
    end if

    opt_cic = 1
    opt_cic@calendar = calendar

    ti1 = cd_inv_calendar(toint(getYYYY(ymd1, False)), toint(getMM(ymd1, False)), toint(getDD(ymd1, False)), 0, 0, 0, units, opt_cic)
    ti2 = cd_inv_calendar(toint(getYYYY(ymd2, False)), toint(getMM(ymd2, False)), toint(getDD(ymd2, False)), 0, 0, 0, units, opt_cic)

    rst = toint(ti2 - ti1) + 1

    return rst

end



;**********************************************************************
; This procedure is used to get YYYY, MM and DD from times such as 
; YYYYMMDD, YYYYMM, YYYYJJJ
;**********************************************************************
undef("sub_getYMD")
procedure sub_getYMD(date, YYYY, MM, DD, opt)
; opt - cuurently not used
begin
    YYYY = getYYYY(date, opt)
    MM = getMM(date, opt)
    DD = getDD(date, opt)
end



;**********************************************************************
; This procedure is used to get YYYY, MM and DD from times such as 
; YYYYMMDD, YYYYMM, YYYYJJJ
;**********************************************************************
undef("getYMD")
function getYMD(timeSI, opt)  ; str or int
; opt - cuurently not used
local timeS, YYYYMMDD
begin
    timeS = "" + timeSI
    YYYYMMDD = str_get_cols(timeS, 0, 7)
    return YYYYMMDD
end



;**********************************************************************
; This procedure is used to get YYYY and MM in next month from current
; YYYY and MM
;**********************************************************************
undef("sub_nextMonth_YYYY_MM")
procedure sub_nextMonth_YYYY_MM(YYYY, MM)
begin
    MM = sprinti("%02i", toint(MM) + 1)
    if (MM .eq. "13") then
        MM = "01"
        YYYY = "" + (toint(YYYY) + 1)
    end if
end



;**********************************************************************
; This procedure is used to get YYYY, MM and DD in next month from 
; current YYYY, MM and DD
;**********************************************************************
undef("sub_nextDay_YYYY_MM_DD")
procedure sub_nextDay_YYYY_MM_DD(YYYY, MM, DD, opt)
local dateStr, dateStr_nextDay
begin
    dateStr = "" + YYYY + MM + DD
    dateStr_nextDay = systemfunc("date -d '" + dateStr + " + 1 days' +%Y%m%d")
    sub_getYMD(dateStr_nextDay, YYYY, MM, DD, 0)
    if (isatt(opt, "no_leap") .and. opt@no_leap .and. MM + DD .eq. "0229") then
        MM = "03"
        DD = "01"
    end if 
end



;**********************************************************************
; This procedure is used to get YYYY and MM in last month from current
; YYYY and MM
;**********************************************************************
undef("sub_lastMonth_YYYY_MM")
procedure sub_lastMonth_YYYY_MM(YYYY, MM)
begin
    MM = sprinti("%02i", toint(MM) - 1)
    if (MM .eq. "00") then
        MM = "12"
        YYYY = "" + (toint(YYYY) - 1)
    end if
end



;**********************************************************************
; This function is used to render time series  (yyyymmddhh)
; with format of "%Y%N%D%H"
;**********************************************************************
undef("render_dh_series")
function render_dh_series(dh1, dh2)
; dh1, dh2 : string like YYYYMMDDHH
; return string series like YYYYMMDDHH
; --------------------------------------
; NOTES:
;    result will contains @_FillValue as missing, which may trigger hidden error if it acts as coordinate
;    See ncl.lang_rec/101
local t1, t2, format, t_series, dh_series
begin
    format = "%Y%N%D%H"
    t1 = cd_inv_string("" + dh1, format) ; units :       hours since 1800-01-01 00:00:00
    t2 = cd_inv_string("" + dh2, format) ; units :       hours since 1800-01-01 00:00:00
    t_series := todouble(ispan(toint(t1), toint(t2), 1))
    copy_VarMeta(t1, t_series)
    dh_series = cd_string(t_series, format)  ; will have @_FillValue : missing

    return dh_series
end



;**********************************************************************
; This function is used to render month series  (yyyymm)
; with format of "%Y%N"
;**********************************************************************
undef("render_ym_series")
function render_ym_series(ym1, ym2)
local t1, t2, format, t_series, ym_series
begin
    format = "%Y%N"
    format@units = "months since 1900-01-01 00:00:00"
    t1 = cd_inv_string("" + ym1, format) ; units :       hours since 1800-01-01 00:00:00
    t2 = cd_inv_string("" + ym2, format) ; units :       hours since 1800-01-01 00:00:00
    t_series := todouble(ispan(toint(t1), toint(t2), 1))
    copy_VarMeta(t1, t_series)
    ym_series = cd_string(t_series, format)

    return ym_series
end



;**********************************************************************
; This function is used to render date series (yyyymmdd)
; with format of "%Y%N%D"
;**********************************************************************
undef("render_ymd_series")
function render_ymd_series(ymd1[1] : string, ymd2[1] : string)
local t1, t2, format, t_series, ym_series
begin
    format = "%Y%N%D"
    format@units = "days since 2000-01-01 00:00:00"
    t1 = cd_inv_string("" + ymd1, format) ; units :       hours since 1800-01-01 00:00:00
    t2 = cd_inv_string("" + ymd2, format) ; units :       hours since 1800-01-01 00:00:00
    t_series := todouble(ispan(toint(t1), toint(t2), 1))
    copy_VarMeta(t1, t_series)
    ymd_series = cd_string(t_series, format)

    return ymd_series
end



;**********************************************************************
; This function is used to render date series with no leap 
; with format of "%Y%N%D"
;**********************************************************************
undef("render_ymd_series_noLeap")
function render_ymd_series_noLeap(ymd1[1] : string, ymd2[1] : string)
local t1, t2, format, t_series, ym_series
begin
    format = "%Y%N%D"
    format@units = "days since 2000-01-01 00:00:00"
    t1 = cd_inv_string("" + ymd1, format) ; units :       hours since 1800-01-01 00:00:00
    t2 = cd_inv_string("" + ymd2, format) ; units :       hours since 1800-01-01 00:00:00
    t_series := todouble(ispan(toint(t1), toint(t2), 1))
    copy_VarMeta(t1, t_series)
    ymd_series = cd_string(t_series, format)

    do i = 0, dimsizes(ymd_series) - 1
        if (str_get_cols(ymd_series(i), 4, 7) .ne. "0229") then
            if (.not. isvar("nlInds")) then
                nlInds = i
            else
                nlInds := array_append_record(nlInds, i, 0)
            end if
        end if
    end do

    ymd_series := ymd_series(nlInds)

    return ymd_series
end



;**********************************************************************
; This function is used to get season series from time series string
;**********************************************************************
undef("get_season_series")
function get_season_series(s, opt)
; opt@
;     format : format of s, such as %Y%N%D
begin
    if (isatt(s, "calendar")) then
        times = cd_calendar(s, 0)
    else
        times = cd_calendar(cd_inv_string(s, opt@format), 0)
    end if
    months = toint(times(:, 1))
    opt_m2s = 1
    opt_m2s@outMode = "int"

    seasons = month2season(months, opt_m2s)

    return seasons

end



;**********************************************************************
; a proxy for dim_xxx_m2s_n
; This function is used to calculate seasonal mean data from monthly data
;**********************************************************************
undef("dim_avg_m2s_n")
function dim_avg_m2s_n(data, idim, yms)
begin
    return dim_xxx_m2s_n(data, idim, yms, "avg")
end



;**********************************************************************
; This function is used to calculate seasonal mean data from monthly data
;**********************************************************************
undef("dim_xxx_m2s_n")
function dim_xxx_m2s_n(data, idim, yms, method)
local ys, ms, opt_m2s, ss, yss, yssI, yssIQ, nyss, ndims, res, yssQU
begin
    ys = str_get_cols(yms, 0, 3) ; YYYYMM to YYYY
    ms = str_get_cols(yms, 4, 5)

    opt_m2s = 1
    ; opt_m2s@outMode = "name"
    ss = month2season(ms, opt_m2s)

    yss = ys + ss

    yssI = toint(yss)

    yssIQ = yssI
    qsort(yssIQ)

    nyss = dimsizes(get_unique_values(yss))

    yssQU = "" + get_unique_values(yssIQ)

    ndims = dimsizes(dimsizes(data))

    res = dim_xxx_cate_n(data, yss, yssQU, idim, method)

    res@times = yssQU

    return res

end



;**********************************************************************
; This function is used to shift a time-str-series
;**********************************************************************
undef("shiftTimeStr")
function shiftTimeStr(timeStr, shift, unit, opt)
; time : YYYYMMDDHH
; shift : an array contains values, such as (/1, 2, 3/)
; unit : corresponding unit for each value in shift
begin
    time = cd_calendar(cd_inv_string(timeStr, opt@format), 0)
    gre_unit = "hours after 2000-01-01 00:00:00"
    do i = 0, dimsizes(shift) - 1
        s = shift(i)
        u = unit(i)
        if (u .eq. "hour") then
            time(:, 3) = time(:, 3) + s
        elseif (u .eq. "day") then
            time(:, 2) = time(:, 2) + s
        elseif (u .eq. "month") then
            time(:, 1) = time(:, 1) + s
        elseif (u .eq. "year") then
            time(:, 0) = time(:, 0) + s
        else
            print("unkonwn unit " + u + "!")
            exit()
        end if
        time = cd_calendar(cd_inv_calendar(time(:, 0), time(:, 1), time(:, 2), time(:, 3), time(:, 4), time(:, 5), gre_unit, 0), 0)
    end do
    res = cd_string(cd_inv_calendar(time(:, 0), time(:, 1), time(:, 2), time(:, 3), time(:, 4), time(:, 5), gre_unit, 0), opt@format)

    return res
end



;**********************************************************************
; This function is used to calculate season name from integer
;**********************************************************************
undef("id2season")
function id2season(sid)
begin
    res = new (dimsizes(sid), string)
    res = where(sid .eq. 0, "spring", res)    
    res = where(sid .eq. 1, "summer", res)    
    res = where(sid .eq. 2, "fall", res)    
    res = where(sid .eq. 3, "winter", res)    
    res = where(sid .eq. 4, "year", res)    

    return res

end



;**********************************************************************
; This function is used to simplify time-str with 60 seconds
;**********************************************************************
undef("simplify_YJHMS")
function simplify_YJHMS(dt)
local format, gre_back, gre_back_plus_minor
begin
    format = "%Y%J%H%M%S"
    format@units = "seconds since 2010-01-01 00:00:00"
    gre_back = cd_inv_string(dt, format)
    gre_back_plus_minor = gre_back + 0.01
    copy_VarMeta(gre_back, gre_back_plus_minor)
    return cd_string(gre_back_plus_minor, format)
end



;**********************************************************************
; This function is used to add "-" in time-str
;**********************************************************************
undef("add_gang_in_time")
function add_gang_in_time(timeStr)
begin
    if (typeof(timeStr) .ne. "string") then
        print("function <add_gang_in_date> only support date string by now!")
        exit()
    end if
    if (strlen(timeStr) .eq. 8) then
        YYYY = str_get_cols(timeStr, 0, 3)
        MM = str_get_cols(timeStr, 4, 5)
        DD = str_get_cols(timeStr, 6, 7)
        return YYYY + "-" + MM + "-" + DD
    elseif (strlen(timeStr) .eq. 7) then
        YYYY = str_get_cols(timeStr, 0, 3)
        JJJ = str_get_cols(timeStr, 4, 6)
        return YYYY + "-" + JJJ
    elseif (strlen(timeStr) .eq. 6) then
        YYYY = str_get_cols(timeStr, 0, 3)
        MM = str_get_cols(timeStr, 4, 5)
        return YYYY + "-" + MM
    else
        print("only support YYYYMMDD or YYYYJJJ or YYYYMM now!")
        exit()
    end if

    return ""

end



;**********************************************************************
; This function is used to transform time-resolution with time-coord 
; remained
;**********************************************************************
undef("transform_time_reso_rtc")
function transform_time_reso_rtc(data, idim, time, opt) ; remain time-coord
; opt@
;     time_reso_dst (necessary) : target time resolution, support daily, monthly, seasonal, annual, MDA8 and period
;     time_fmt_src  (necessary) : source time format, such as %Y%N%D
;     method        (optional)  : method during dimension reduction, default is avg
begin
    assert(isatt(opt, "time_reso_dst"), "function <transform_time_reso_rtc> : Error! param-opt must contain attribue-time_reso_dst")
    assert(isatt(opt, "time_fmt_src"), "function <transform_time_reso_rtc> : Error! param-opt must contain attribue-time_fmt_src")
    time_reso_dst = opt@time_reso_dst
    time_fmt_src = opt@time_fmt_src
    greTime = cd_inv_string(time, time_fmt_src)

    if (time_reso_dst .eq. "MDA8") then
        opt_h2m = 1
        res = hour2MDA8(data, idim, opt_h2m)
        return res
    end if

    method = "avg"
    if (isatt(opt, "method")) then
        method = opt@method
    end if

    if (time_reso_dst .eq. "period") then
        res = dim_xxx_n(data, idim, method)
        res@times = "period"
        return res
    end if

    if (time_reso_dst .eq. "daily") then
        time_dst = cd_string(greTime, "%Y%N%D")
        res = dim_xxx_label_n(data, time_dst, idim, method)
        res@times = res@labels
        delete(res@labels)
        return res
    elseif (time_reso_dst .eq. "monthly") then
        time_dst = cd_string(greTime, "%Y%N")
        ; print(time_dst(:750))
        res = dim_xxx_label_n(data, time_dst, idim, method)
        ; print(res(0, :))
        ; print(data(:720, 1))
        res@times = res@labels
        delete(res@labels)
        return res
    elseif (time_reso_dst .eq. "annual") then
        time_dst = cd_string(greTime, "%Y")
        res = dim_xxx_label_n(data, time_dst, idim, method)
        res@times = res@labels
        delete(res@labels)
        return res
    elseif (time_reso_dst .eq. "seasonal") then
        ; print("this feature <seasonal> is currently paused")  ; The issue is about how to handle winter? if we want Jan, Feb and Dec, then <dim_avg_label_n> cannot realizes this goal 
        ; exit()
        time_dst = cd_string(greTime, "%Y%N")
        resM = dim_xxx_label_n(data, time_dst, idim, method)
        res = dim_xxx_m2s_n(resM, idim, resM@labels, method)
        return res
    elseif (time_reso_dst .eq. "Omonthly") then
        time_dst = cd_string(greTime, "%Y%N")
        resM = dim_xxx_label_n(data, time_dst, idim, method)
        yms = resM@labels
        mms = getMM(yms, False)
        mmsU = get_unique_values(mms)
        res = dim_xxx_cate_n(resM, mms, mmsU, 0, method)
        res@times = mmsU
        return res
    elseif (time_reso_dst .eq. "Oseasonal") then
        time_dst = cd_string(greTime, "%Y%N")
        resM = dim_xxx_label_n(data, time_dst, idim, method)
        resS = dim_xxx_m2s_n(resM, idim, resM@labels, method)
        yss = resS@times ; '20151'
        ss = str_get_cols(yss, 4, 4)
        ssU = get_unique_values(ss)
        assert(dimsizes(ssU) .eq. 4, "function <transform_time_reso_rtc> : unexpected ssU size " + dimsizes(ssU))
        res = dim_xxx_cate_n(resS, ss, ssU, 0, method)
        res@times = ssU
        return res
    else
        print("function <transform_time_reso_rtc> : unknwon time_reso_dst : " + time_reso_dst)
        exit()
    end if
    
end



;**********************************************************************
; this function is used to resolve month definitions
; such as "201501-201503,201609,201612-201702,201712"
;**********************************************************************
undef("resolveMonths")
function resolveMonths(monthDef)
local mds, res, mdT, ym1, ym2, ymp, res2, yms
begin
    mds = str_split(monthDef, ",")
    res = (/""/)
    do i = 0, dimsizes(mds) - 1
        mdT := mds(i)
        if (str_match_bool(mdT, "-")) then
            ymp = str_split(mdT, "-") ; yyyymm pair
            ym1 = ymp(0)
            ym2 = ymp(1)
            yms := render_ym_series(ym1, ym2)
            res := array_append_record(res, yms, 0)
        else
            res := array_append_record(res, mdT, 0)
        end if
    end do

    res2 = res(1:)

    return res2
end



;**********************************************************************
; Similar with above but for yyyymmdd
;**********************************************************************
undef("resolveDates")
function resolveDates(dateDef)
begin
    ymds = str_split(dateDef, ",")
    res = (/""/)
    do i = 0, dimsizes(ymds) - 1
        ymdT = ymds(i)
        if (str_match_bool(ymdT, "-")) then
            ymdp = str_split(ymdT, "-")
            ymd1 = ymdp(0)
            ymd2 = ymdp(1)
            yms := render_ymd_series(ymd1, ymd2)
            res := array_append_record(res, yms, 0)
        else
            res := array_append_record(res, ymdT, 0)
        end if
    end do
    res2 = res(1:)
    return res2
end




;**********************************************************************
; An superior version of resolveMonths
; this function is used to resolve yms definitions, as a pro version from resolveMonths
; such as "201501-201503,201609,201612-201702,201712"
; or, "2015-2019|06,2017-2015|08,2015_2017_2016|12,201501-201503,2018|12_01_04, 
;     "2017-2015_2019|12"
;**********************************************************************
undef("resolveYMS")
function resolveYMS(ymsDef, opt)
local mds, res, mdT, ym1, ym2, ymp, res2, yms
begin
    ; ~~~~~~~~~~~~~~~~~~~~~~~ check attr
    sort = False
    if (isatt(opt, "sort")) then
        sort = opt@sort
    end if

    ; ~~~~~~~~~~~~~~~~~~~~~~~ main body
    yms_list = str_split(ymsDef, ",")
    res = (/""/)
    do i = 0, dimsizes(yms_list) - 1
        ymDT := yms_list(i) 
        if (str_match_bool(ymDT, "|")) then
            vl_pair = str_split(ymDT, "|") ; vertical line
            yyyys := splitIntsDef(vl_pair(0), "-", "_")
            mms := splitIntsDef(vl_pair(1), "-", "_")
            do j = 0, dimsizes(mms) - 1
                res := array_append_record(res, sprinti("%04d", yyyys) + sprinti("%02d", mms(j)), 0)
            end do
        elseif (str_match_bool(ymDT, "-")) then
            ymp = str_split(ymDT, "-") ; yyyymm pair
            ym1 = ymp(0)
            ym2 = ymp(1)
            yms := render_ym_series(ym1, ym2)
            res := array_append_record(res, yms, 0)
        else
            res := array_append_record(res, ymDT, 0)
        end if
    end do

    res2 = res(1:)

    if (sort) then
        sqsort(res2)
    end if

    return res2
end



;**********************************************************************
; this function is used to transform time-coordinate for hourly data
;**********************************************************************
undef("dim_shiftTC_n")
function dim_shiftTC_n(data, dim_hour, opt)
; opt@
;     mode : explicit, nextday, usemiss
;     tc_src, tc_dst : time coordinate, necessary
local tc_src, tc_dst, tcD, mode, dims, ndims, dataN
begin
    assert(isatt(opt, "tc_src"), "Error! opt@tc_src is necessary") 
    assert(isatt(opt, "tc_dst"), "Error! opt@tc_dst is necessary") 
    assert(isatt(opt, "mode"), "Error! opt@mode is necessary") 


    tc_src = opt@tc_src
    tc_dst = opt@tc_dst
    assert(typeof(tc_src) .eq. "integer", "Error! opt@tc_src should be integer!")
    assert(typeof(tc_dst) .eq. "integer", "Error! opt@tc_dst should be integer!")

    tcD = tc_dst - tc_src
    assert(tcD .ge. 0, "This functon currently only supports conditions that tcD >= 0, plz update function since your tcD is < 0")
    if (tcD .eq. 0) then
        return data
    end if

    mode = opt@mode ; explicit, nextday, usemiss
    assert(typeof(mode) .eq. "string", "Error! opt@mode should be string!")
    if (mode .eq. "explicit") then
        missData = opt@missData
    end if

    dims = dimsizes(data)
    ndims = dimsizes(dimsizes(data))

    ; --- debug
    ; printVarSummary(data)
    ; printVarSummary(dims)
    
    assert(dims(dim_hour) % 24 .eq. 0, "(dim_shiftTC_n) data must contains the whole days' hourly data, that is, must be exactly divided by 24! now is " + dims(dim_hour))


    dataN = new (dims, typeof(data)); data new

    if (ndims .eq. 3 .and. dim_hour .eq. 0) then
        dataN(tcD : dims(dim_hour) - 1, :, :) = data( : dims(dim_hour) - 1 - tcD, :, :)
        ; write_matrix(dim_avg_n(dataN, 0), "2f6.2", False)
        if (mode .eq. "nextday") then
            ; write_matrix(dim_avg_n(data, 0), "2f6.2", False)
            dataN(: tcD - 1, :, :) = data(23 - tcD + 1 : 23, :, :)
            ; write_matrix(dim_avg_n(dataN, 0), "2f6.2", False)
        elseif (mode .eq. "explicit") then
            dataN(: tcD - 1, :, :) = (/missData/)
        end if
    elseif (ndims .eq. 4 .and. dim_hour .eq. 0) then
        dataN(tcD : dims(dim_hour) - 1, :, :, :) = data( : dims(dim_hour) - 1 - tcD, :, :, :)
        if (mode .eq. "nextday") then
            dataN(: tcD - 1, :, :, :) = data(23 - tcD + 1 : 23, :, :, :)
        elseif (mode .eq. "explicit") then
            dataN(: tcD - 1, :, :, :) = (/missData/)
        end if
    elseif (ndims .eq. 2 .and. dim_hour .eq. 1) then
        dataN(:, tcD : dims(dim_hour) - 1) = data(:,  : dims(dim_hour) - 1 - tcD)
        if (mode .eq. "nextday") then
            dataN(:, : tcD - 1) = data(:, 23 - tcD + 1 : 23)
        elseif (mode .eq. "explicit") then
            dataN(:, : tcD - 1) = (/missData/)
        end if
    elseif (ndims .eq. 1) then
        dataN(tcD : dims(dim_hour) - 1) = data( : dims(dim_hour) - 1 - tcD)
        ; write_matrix(dim_avg_n(dataN, 0), "2f6.2", False)
        if (mode .eq. "nextday") then
            ; write_matrix(dim_avg_n(data, 0), "2f6.2", False)
            dataN(: tcD - 1) = data(23 - tcD + 1 : 23)
            ; write_matrix(dim_avg_n(dataN, 0), "2f6.2", False)
        elseif (mode .eq. "explicit") then
            dataN(: tcD - 1) = (/missData/)
        end if

    else
        print("function <dim_shiftTC_n> : unknown combination for <dim_hour> and <ndims> : " + dim_hour + " and " + ndims + ", plz update code!")
        exit()
    end if

    ; copy_VarMeta(data, dataN)
    if (iscoord(dataN, "time_hourly") .and. iscoord(dataN, "code")) then
        delete(dataN&time_hourly)  ; automatically set coord is not good! see ncl.lang_rec/101 102
        delete(dataN&code)
        dataN&code = data&code
        dataN&time_hourly = data&time_hourly
    end if

    dataN@time_coordinate = tc_dst
    dataN@time_coordinate_description = "transformed from " + tc_src + " through mode <" + mode + ">"

    return dataN

end



;**********************************************************************
; This function is used to calculate daily data from hourly data
; several processing methods are available, such as avg, max, ... ...
;**********************************************************************
undef("hour2daily")
function hour2daily(data, dim_hour, opt)   ; dataH is a 3-d data
; data - source hourly data
; dim_hour - which dimension represents hour
; opt@
;   method = avg / max / min / sum
local dims, nhours, ndays, ndim, method, res, i
begin
    ; >>>>> basic property
    dims = dimsizes(data)
    nhours = dims(dim_hour)
    ndays = nhours / 24
    ndim = dimsizes(dims)

    ; >>>>> get opt@method
    if (isatt(opt, "method")) then
        method = opt@method
        if (method .ne. "avg" .and. method .ne. "max" .and. method .ne. "min" .and. method .ne. "sum") then
            print("method must be one of (avg, max, min, sum)! Error, now is " + method)
            exit()
        end if
    else
        method = "avg"
    end if

    dims2 = dims
    dims2(dim_hour) = ndays

    res = new (dims2, "float")

    do i = 0, ndays - 1
        dataDT := tofloat(dim_xxx_n(slice_rmd(data, ispan(i * 24, i * 24 + 23, 1), dim_hour), dim_hour, method))  ; data day temp
        assignValue(res, dataDT, dim_hour, i)
    end do

    return res

end

;**********************************************************************
; this function is used to calculate MMA6 from monthly data
;**********************************************************************
undef("month2MMA6")
function month2MMA6(data, dim_month, opt)
; >>>>> parameter requirements
;   data :  months x rows x cols
;   opt  : not used currectly
; >>>>> notes
;   Thie function doesn't take time-coord into consideration
local dataDims, ndim, months, years, res, y, m
begin
    dataDims = dimsizes(data)
    ndim = dimsizes(dataDims)
    months = dataDims(dim_month)
    assert(months % 12 .eq. 0, "function <month2MMA6> : Error! requires months divisible by 12 (Jan. to Dec.)")
    years = months / 12

    if (dim_month .eq. 0 .and. ndim .eq. 3) then
        res = new ((/years, dataDims(1), dataDims(2)/), typeof(data))
        do y = 0, years - 1
            movAvgs = new ((/7, dataDims(1), dataDims(2)/), typeof(data))
            do m = 0, 6
                movAvgs(m, :, :) = dim_avg_n(data(y * 12 + m : y * 12 + m + 5, :, :), 0)
            end do
            res(y, :, :) = dim_max_n(movAvgs, 0)
        end do
    else
        print("function <month2MMA6> : Unsupported dim_month or ndim! Error")
        exit()
    end if

    return res
end



;**********************************************************************
; This function is used to calculate MDA8 data from hourly data
;**********************************************************************
undef("hour2MDA8")
function hour2MDA8(data, dim_hour, opt)
; >>>>> parameter requirements
;   data :  hours x rows x cols
;   opt  : not used currectly
; >>>>> notes
;   Thie function doesn't take time-coord into consideration
local dataDims, hours, days, res, movAvgs, d, h
begin
    dataDims = dimsizes(data)
    ndim = dimsizes(dataDims)
    hours = dataDims(dim_hour)
    assert(hours % 24 .eq. 0, "Function<hour2MDA8> requires first dimension of data divisible by 24")
    days = hours / 24
    
    if (dim_hour .eq. 0 .and. ndim .eq. 3) then

        res = new ((/days, dataDims(1), dataDims(2)/), typeof(data))
        do d = 0, days - 1
            movAvgs = new ((/17, dataDims(1), dataDims(2)/), typeof(data))
            do h = 0, 16
                movAvgs(h, :, :) = dim_avg_n(data(d * 24 + h : d * 24 + h + 7, :, :), 0)
            end do
            res(d, :, :) = dim_max_n(movAvgs, 0)
        end do
    elseif (dim_hour .eq. 0 .and. ndim .eq. 2) then
        res = new ((/days, dataDims(1)/), typeof(data))
        do d = 0, days - 1
            movAvgs = new ((/17, dataDims(1)/), typeof(data))
            do h = 0, 16
                movAvgs(h, :) = dim_avg_n(data(d * 24 + h : d * 24 + h + 7, :), 0)
            end do
            res(d, :) = dim_max_n(movAvgs, 0)
        end do
    elseif (dim_hour .eq. 0 .and. ndim .eq. 1) then
        res = new (days, typeof(data))
        do d = 0, days - 1
            movAvgs = new (17, typeof(data))
            do h = 0, 16
                if (.not. all(ismissing(data(d * 24 + h : d * 24 + h + 7)))) then
                    movAvgs(h) = avg(data(d * 24 + h : d * 24 + h + 7))
                end if
            end do
            res(d) = max(movAvgs)
        end do  
    elseif (dim_hour .eq. 0 .and. ndim .eq. 4) then
        res = new ((/days, dataDims(1), dataDims(2), dataDims(3)/), typeof(data))
        do d = 0, days - 1
            movAvgs = new ((/17, dataDims(1), dataDims(2), dataDims(3)/), typeof(data))
            do h = 0, 16
                movAvgs(h, :, :, :) = dim_avg_n(data(d * 24 + h : d * 24 + h + 7, :, :, :), 0)
            end do
            res(d, :, :, :) = dim_max_n(movAvgs, 0)
        end do
    elseif (dim_hour .eq. 1 .and. ndim .eq. 2) then
        res = new ((/dataDims(0), days/), typeof(data))
        do d = 0, days - 1
            movAvgs = new ((/17, dataDims(0)/), typeof(data))
            do h = 0, 16
                movAvgs(h, :) = dim_avg_n(data(:, d * 24 + h : d * 24 + h + 7), 1)
            end do
            res(:, d) = dim_max_n(movAvgs, 0)
        end do

    else
        print("unsupported combination of <ndim> and <dim_hour>, which are " + ndim + " and " + dim_hour + ", plz update code!")
        exit()
    end if

    return res
end



;**********************************************************************
; This function is similar to hour2daily, except for supporting 
; transformation of time-coordinate
;**********************************************************************
undef("hour2daily_tct")
function hour2daily_tct(dataR, dim_hour, opt)   ; time coord transform
local dataTTC, res
begin
    dataTTC = dim_shiftTC_n(dataR, dim_hour, opt) ; data with transformed time-coordinate

    res = hour2daily(dataTTC, dim_hour, opt)

    return res
end



;**********************************************************************
; This function is similar to hour2MDA8, except for supporting 
; transformation of time-coordinate
;**********************************************************************
undef("hour2MDA8_tct")
function hour2MDA8_tct(dataR, dim_hour, opt)   ; time coord transform
local dataTTC, res
begin
    dataTTC = dim_shiftTC_n(dataR, dim_hour, opt) ; data with transformed time-coordinate

    res = hour2MDA8(dataTTC, dim_hour, opt)

    return res
end



;**********************************************************************
; This function is used to render day index according to year, season 
; and month, ... ...
;**********************************************************************
undef("render_di")
function render_di(ymdS[1] : string, ymdE[1] : string, years, seasons, months[*] : string)
; ymdS, ymdE : date range
; years, seasons, months : constraints
;    years : integer or string, or "ALL"
;    seasons : integer, 0 - 3 : spring - winter, or "ALL"
;    months : string, 01, 02, ... ... 12, or "ALL"
; example1 : 
;     render_di("20210501", 20210630, "ALL", (/0, 1/), "06")
local ymd_series, optG, ys, ms, ss, years_str, seasons_int, months_ren, res, i, yearPass, monthPass, seasonPass, di
begin
    ymd_series = render_ymd_series(ymdS, ymdE)
    optG = True
    ys = getYYYY(ymd_series, optG) ; "2015", "2016", ... ...
    ms = getMM(ymd_series, optG)   ; "01", "02", ... "12"
    optG@type = "int"
    ss = getSeasons(ymd_series, optG)  ; 0, 1, 2, 3

    years_str = "" + years
    if (typeof(seasons) .eq. "string" .and. seasons(0) .eq. "ALL") then
        seasons_int = (/0, 1, 2, 3/)
    else
        seasons_int = toint(seasons)
    end if

    if (months(0) .eq. "ALL") then
        months_ren = (/"01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"/)
    else
        months_ren = months
    end if

    assert(all(strlen(months_ren) .eq. 2), "function <render_di> requires param-months to be like '01', '02', '03' ... ...")

    res = new (dimsizes(ymd_series), integer)
    res = 0

    do i = 0, dimsizes(ymd_series) - 1
        yearPass = 0
        seasonPass = 0
        monthPass = 0
        ; --- handle yearPass
        if (years_str(0) .eq. "ALL" .or. in(years_str, ys(i))) then
            yearPass = 1
        end if
        ; --- handle seasonPass
        if (in(seasons_int, ss(i))) then
            seasonPass = 1
        end if
        ; --- handle monthPass
        if (in(months_ren, ms(i))) then
            monthPass = 1
        end if

        res(i) = yearPass * seasonPass * monthPass
    end do

    di = ind(res .eq. 1)

    return di

end