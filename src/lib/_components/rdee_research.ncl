
; Customized functions/procedures regarding research
; category : research



;**********************************************************************
; this function is used to calculate evaluation metrics
;**********************************************************************
undef("evaMetrics")
function evaMetrics(xs[*], ys[*])
; ys as obs
local lens, BIAS, ERROR, NMB, NME, FBIAS, FERROR, CORRCOEFF, p, res
begin
    if (dimsizes(xs) .ne. dimsizes(ys)) then
        print("Error! xs and ys in <evaMetrics> should have the same size!")
        exit()
    end if
    assert(num(ismissing(xs)) .eq. 0, "function <evaMetrics> : Error! plz remove missing values in <xs> before call this function !")
    assert(num(ismissing(ys)) .eq. 0, "function <evaMetrics> : Error! plz remove missing values in <ys> before call this function !")
    
    lens = dimsizes(ys)

    ; yfv = ys@_FillValue
    ; xfv = xs@_FillValue

    ys_n0_inds = ind(ys .ne. 0)
    xs2 = xs(ys_n0_inds)
    ys2 = ys(ys_n0_inds)

    xys_n0_ind = ind(xs + ys .ne. 0)
    xs3 = xs(xys_n0_ind)
    ys3 = ys(xys_n0_ind)
    lens3 = dimsizes(ys3)

    ; --- Mean Bias
    BIAS = sum(xs - ys) / lens
    ; --- Mean Error
    ERROR = sum(abs(xs - ys)) / lens
    ; --- Normalized Mean Bias(percent)
    NMB = sum(xs - ys) / sum(ys) * 100
    ; --- Normalized Mean Error (percent)
    NME = sum(abs(xs - ys)) / sum(ys) * 100
    ; --- Mean Fractional Bias (percent)
    FBIAS = sum((xs3 - ys3) / (xs3 + ys3)) / lens3 * 2 * 100
    ; --- Mean Fractional Error (percent)
    FERROR = sum(abs((xs3 - ys3) / (xs3 + ys3))) / lens3 * 2 * 100
    ; --- Correlation Coefficient(R)
    CORRCOEFF = sum((xs - avg(xs)) * (ys - avg(ys))) / sqrt(sum((xs - avg(xs))^2) * sum((ys - avg(ys))^2))
    p = rtest(CORRCOEFF, lens, 0)

    ; --- RMSE
    rmse = dim_rmsd(xs, ys)

    res = (/BIAS, NMB, NME, FBIAS, FERROR, CORRCOEFF, p, ERROR, rmse/)


    return res

end



;**********************************************************************
; DEPRECATED <NCL has its own functions!>
; this script is used to calculate left T,TD and RH given 2 of them
; ref : https://bmcnoldy.rsmas.miami.edu/Humidity.html
;**********************************************************************
undef("T_TD_RH")
procedure T_TD_RH(T, TD, RH, opt)
; units : T -> celsius degree, TD -> celsius degree, RH -> %
; Last update @ 2021-07-28 14:11:15
begin
    target = opt@target

    if (target .eq. "T") then
        T = 243.04*(((17.625*TD)/(243.04+TD))-log(RH/100))/(17.625+log(RH/100)-((17.625*TD)/(243.04+TD)))
    elseif (target .eq. "TD") then
        TD = 243.04*(log(RH/100)+((17.625*T)/(243.04+T)))/(17.625-log(RH/100)-((17.625*T)/(243.04+T)))
    elseif (target .eq. "RH") then
        RH = 100*(exp((17.625*TD)/(243.04+TD))/exp((17.625*T)/(243.04+T)))
    else
        print("procedure <T_TD_RH> : Error! target must be in (T, TD, RH)")
        exit()
    end if
end



;**********************************************************************
; This function is used to calculate a index defined by a threshold and 
; selected continuous days (such as heat wave)
;**********************************************************************
undef("calCBTSI") 
function calCBTSI(arr, arr_ts, idim[1]:integer, ndays[1]:integer, op)  ; index for continuous elemenarr beyond threshold 
local dims, ndims, res, i, tb, tb2, res2
begin
    dims = dimsizes(arr)
    ndims = dimsizes(dims)

    ; assert(ndims .eq. 1 .or. ndims .eq. 3 .or. ndims .eq. 2, "function <calHW> currently only recognize 1-d or 2-d or 3-d data!")
    ; assert(ndims .eq. 3, "function <calHW> currently only recognize 3-d data!")

    res = new (dims, integer)
    res = 0

    if (ndims .eq. 3 .and. idim .eq. 0) then
        if (num(.not.ismissing(arr_ts)) .eq. 1) then
            tb = where(lop(arr, arr_ts, op), 1, 0)
        elseif (dimsizes(dimsizes(arr_ts)) .eq. 2) then
            tb = where(lop(arr, conform_dims(dims, arr_ts, (/1, 2/)), op), 1, 0) ; temp binary , 1 / 0 
        else
            print("function<calCBTSI> : Error! unkonwn arr_ts shape")
            exit()
        end if 
        tb2 = tb
        do i = 1, ndays - 1
            tb2 = tb2 + shiftArray(tb, idim, i, 0)
        end do
        do i = ndays - 1, dims(idim) - 1
            res(i - ndays + 1 : i, :, :) = res(i - ndays + 1 : i, :, :) + conform_dims((/ndays, dims(1), dims(2)/), where(tb2(i, :, :) .eq. ndays, 1, 0), (/1, 2/))
        end do
    elseif (ndims .eq. 1 .and. idim .eq. 0) then
        tb = where(lop(arr, arr_ts, op), 1, 0) ; temp binary , 1 / 0
        tb2 = tb
        do i = 1, ndays - 1
            tb2 = tb2 + shiftArray(tb, idim, i, 0)
        end do 
        ; print(tb2) ; # for debug
        do i = ndays - 1, dims(idim) - 1
            res(i - ndays + 1 : i) = res(i - ndays + 1 : i) + where(tb2(i) .eq. ndays, 1, 0)
        end do
    else
        print("function <calCBarrI> : unkonwn ndims = " + ndims + " and idim = " + idim + ", Error!")
        exit()
    end if

    res2 = where(res .gt. 0, 1, 0)

    return res2
end



;**********************************************************************
; Convert ug/m3 to ppbv unit (for several gas air pollutant such as O3)
;**********************************************************************
undef("MEE_ugm3_to_ppbv")
function MEE_ugm3_to_ppbv(var[1] : string, data, idim[1] : integer, times[*] : string)
begin
    index_nso = ind(times .lt. "201809")
    index_nsn = ind(times .ge. "201809")

    if (var .eq. "O3" .or. var .eq. "O3_MDA8") then
        M = 48
    elseif (var .eq. "PM25") then
        return data
    elseif (var .eq. "SO2") then
        M = 64
    elseif (var .eq. "NO2") then
        M = 46
    else
        print("function <MEEugm3_to_ppbv> : Error, unsupport var " + var)
        exit()
    end if


    res = data

    dims = dimsizes(data)
    ndims = dimsizes(dims)

    ; assert(idim .eq. 0, "function <MEEugm3_to_ppbv> : Error, now only support idim = 0, now is " + idim)

    if (ndims .eq. 3 .and. idim .eq. 0) then
        if (.not.all(ismissing(index_nso))) then
            res(index_nso, :, :) = data(index_nso, :, :) * 22.4 / M
        end if
        if (.not.all(ismissing(index_nsn))) then
            res(index_nsn, :, :) = data(index_nsn, :, :) * 24.5 / M
        end if
    elseif (ndims .eq. 2 .and. idim .eq. 1) then
        if (.not.all(ismissing(index_nso))) then
            res(:, index_nso) = data(:, index_nso) * 22.4 / M
        end if
        if (.not.all(ismissing(index_nsn))) then
            res(:, index_nsn) = data(:, index_nsn) * 24.5 / M
        end if
    else
        print("function <MEEugm3_to_ppbv> : Error, unsupport ndims " + ndims)
        exit()
    end if

    return res

end



;**********************************************************************
; Convert O3 ppbv to ug/m3 (in standard condition defined in CNMEE)
;**********************************************************************
undef("O3_ppbv2ugm3")
function O3_ppbv2ugm3(mxr, tFlag) ; 
; tFlag : 0 - before 201809, 1 - after 201809
begin
    M = 64
    if (tFlag .eq. 0) then
        rst = mxr * M / 22.4
    else
        rst = mxr * M / 24.45
    end if    

    return rst

end



;**********************************************************************
; A wrapper function for t-test
;**********************************************************************
undef("ttest_wrapper")
function ttest_wrapper(xs, ys, threshold)
; return ->
;       a logical value which means if/not has significant difference
begin
    ; ------ first, get the valid array
    nValid_X = num(.not.ismissing(xs))
    nValid_Y = num(.not.ismissing(ys))
    if (nValid_X .lt. 2 .or. nValid_Y .lt. 2) then
        return -1
    end if

    xs_1dR = get1dR(xs)
    ys_1dR = get1dR(ys)

    aveX    = avg(xs_1dR)
    aveY    = avg(ys_1dR)
    varX    = variance(xs_1dR)
    varY    = variance(ys_1dR)
    sX      = dimsizes(xs_1dR)
    sY      = dimsizes(ys_1dR)
    diffXY  = aveX - aveY
    iflag   = True
    tval_opt= False
    prob = ttest(aveX,varX,sX, aveY,varY,sY, iflag, tval_opt) 

    if (prob .lt. threshold) then
        ; print("diff : " + diffXY + ", sig diff!")
        return 1
    else 
        ; print("diff : " + diffXY + ", NO sig diff")
        return 0
    end if
    
end



;**********************************************************************
; calculate AQI based on CN standard
;**********************************************************************
undef("calAQI_spec")
function calAQI_spec(conc[*]:numeric, spec, timeReso)
begin
    if ((str_upper(spec) .eq. "PM25" .or. str_upper(spec) .eq. "PM2.5") .and. timeReso .eq. "24avg") then
        IAQIs = (/0, 50, 100, 150, 200, 300, 400, 500/)
        concs = (/0, 35, 75, 115, 150, 250, 350, 500/)
        rst = new (dimsizes(conc), float)
        do i = 0, dimsizes(conc) - 1
            rst(i) = linint1(concs, IAQIs, False, conc(i), 0)
        end do
        return rst
    elseif ((str_upper(spec) .eq. "O3" .or. str_upper(spec) .eq. "OZONE") .and. str_upper(timeReso) .eq. "MDA8") then

        IAQIs = (/0, 50, 100, 150, 200, 300/)
        concs = (/0, 100, 160, 215, 265, 800/) ; ug/m3
        rst = new (dimsizes(conc), float)
        do i = 0, dimsizes(conc) - 1
            rst(i) = linint1(concs, IAQIs, False, conc(i), 0)
        end do
        return rst
    else
        print("function<calAQI_spec> : Error!unknown spec and timeReso!")
        exit()
    end if

end



;**********************************************************************
; This function is used to convert ioapi TFLAG to gregorian calendar
;**********************************************************************
undef("dt_ioapi2gre")
function dt_ioapi2gre(dt)
local datetime, format, gre
begin
    if (dimsizes(dimsizes(dt)) .eq. 1) then
        datetime = dt(0) + sprinti("%06d", dt(1))
    else
        datetime = dt(:, 0) + sprinti("%06d", dt(:, 1))
    end if
    format = "%Y%J%H%M%S"
    format@units = "seconds since 2010-01-01 00:00:00"
    gre = cd_inv_string(datetime, format)

    return gre
end



;**********************************************************************
; This function is used to convert ioapi TFLAG to time-str
;**********************************************************************
undef("dt_ioapi2str")
function dt_ioapi2str(dt, format_res)
local datetime, format, gre
begin
    if (dimsizes(dimsizes(dt)) .eq. 1) then
        datetime = dt(0) + sprinti("%06d", dt(1))
    else
        datetime = dt(:, 0) + sprinti("%06d", dt(:, 1))
    end if
    format = "%Y%J%H%M%S"
    format@units = "seconds since 2010-01-01 00:00:00"
    gre = cd_inv_string(datetime, format)
    res = cd_string(gre, format_res)
    return res
end



;**********************************************************************
; This function is used to convert wrf-times to time-str
;**********************************************************************
undef("wrfTimes2str")
function wrfTimes2str(wrfTimes, format)
local format_wrfTimes, dt_gre, timeStr
begin
    ; wrfTimes - YYYY-MM-DD_HH:MM:SS
    format_wrfTimes = "%Y-%N-%D_%H:%M:%S"
    dt_gre = cd_inv_string(wrfTimes, format_wrfTimes)
    timeStr = cd_string(dt_gre, format)

    return timeStr

end



;**********************************************************************
; This function is used to convert gregorian calendar to ioapi TFLAG
;**********************************************************************
undef("gre2dt_ioapi")
function gre2dt_ioapi(gre)
local datetime, yyyyjjj, hhmmss
begin
    datetime = simplify_YJHMS(cd_string(gre, "%Y%J%H%M%S"))
    yyyyjjj = toint(str_get_cols(datetime, 0, 6))
    hhmmss = toint(str_get_cols(datetime, 7, 12))
    dt = new ((/dimsizes(yyyyjjj), 2/), integer)
    dt(:, 0) = yyyyjjj
    dt(:, 1) = hhmmss

    return dt

end



;**********************************************************************
; This function is used to build ioapi-TFLAG
;**********************************************************************
undef("buildTFLAG")
function buildTFLAG(init, step, nstep)
local dateG_series, format, init_gre, i
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

