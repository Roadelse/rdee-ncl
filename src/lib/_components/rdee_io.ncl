
; Customized functions/procedures regarding I/O processing
; category : I/O



;**********************************************************************
; Print with time
;**********************************************************************
undef("logT")
procedure logT(S[1] : string)
begin
    now = systemfunc("date '+%Y/%m/%d %H:%M:%S'")
    print(now + " - " + S)
end



;**********************************************************************
; This function is used to batch-print variables
; each variable should be a single value!
;**********************************************************************
undef("print_kv")
procedure print_kv(ks, vs)
local S
begin
    S = ""
    if (dimsizes(dimsizes(ks)) .ne. 1 .or. dimsizes(dimsizes(vs)) .ne. 1) then
        print("ks must be 1-dimension string! vs must be 1-dimensional values")
        exit()
    end if

    if (dimsizes(ks) .ne. dimsizes(vs)) then
        print("ks and vs must have the same length!")
        exit()
    end if


    do i = 0, dimsizes(ks) - 1
        S = S + ks(i) + " = " + vs(i) + ", "
    end do
    S = str_get_cols(S, 0, -3)
    print("" + S)
end



;**********************************************************************
; <Deprecated> See saveD_v
; This function is used to save data quickly with a flag name
; coupled with <readD>
;**********************************************************************
undef("saveD")
procedure saveD(dt, name, RM)
begin
    if (.not.fileexists("saveD")) then
        system("mkdir saveD")
    end if
    setfileoption("nc", "FileStructure", "Advanced")
    setfileoption("nc", "Format",  "NetCDF4")
    f = addfile_crmo("saveD/" + name + ".nc")
    if (RM .eq. "R") then
        res = (/dt/)
        f->$name$ = res
    else
        f->$name$ = dt
    end if
end



;**********************************************************************
; <Deprecated> See readD_v
; This function is used to read data quickly with a flag name from file
; saved by <saveD>
; coupled with <readD>
;**********************************************************************
undef("readD")
function readD(name, RM)
begin
        f = addfile("saveD/" + name + ".nc", "r")
        if (RM .eq. "R") then
            res = (/f->$name$/)
            return res
        else
            return f->$name$
        end if
end



;**********************************************************************
; This function is used to save data quickly with a flag name
; coupled with <readD_v>
;**********************************************************************
undef("saveD_v")
procedure saveD_v(dt, fname, vname, RM)
; dt            : data
; fname, vname  : filename, variable name
; RM            : "R" means save raw data only, "M" means remaining meta info
begin
    if (.not.fileexists("saveD")) then
        system("mkdir saveD")
    end if
    setfileoption("nc", "FileStructure", "Advanced")
    setfileoption("nc", "Format",  "NetCDF4")
    f = addfile_wc("saveD/" + fname + ".nc")
    if (RM .eq. "R") then
        res = (/dt/)
        f->$vname$ = res
    else
        f->$vname$ = dt
    end if
end



;**********************************************************************
; This function is used to read data quickly with a flag name from file
; saved by <saveD>
; coupled with <readD>
;**********************************************************************
undef("readD_v")
function readD_v(fname, vname, RM)
; dt            : data
; fname, vname  : filename, variable name
; RM            : "R" means save raw data only, "M" means remaining meta info
begin
    f = addfile("saveD/" + fname + ".nc", "r")
    if (RM .eq. "R") then
        res = (/f->$vname$/)
        return res
    else
        return f->$vname$
    end if
end



;**********************************************************************
; <Deprecated> invalid function!
; This function is used to obtain data from my database for obs
; support flexible time-coordinate and time-resolution
; !!! this function is not recommended to use due to its low efficiency
;**********************************************************************
undef("get_obs_db_data")
function get_obs_db_data(db, var, code, dh1, dh2, opt)
; ***** UPDATE
;   2021-07-11          add check for dh-range out of database
local method, tc_src, tc_dst, opt_sts, date1, date2, hour1, hour2, data, data_str, res, pos, i, sps
begin

    method = opt@method
    tc_src = opt@tc_src
    tc_dst = opt@tc_dst

    opt_sts = True
    opt_sts@format = "%Y%N%D%H"
    dh1_src = shiftTimeStr(dh1, tc_src - tc_dst, "hour", opt_sts)
    dh2_src = shiftTimeStr(dh2, tc_src - tc_dst, "hour", opt_sts)

    src_date1 = str_get_cols(dh1_src, 0, 7)
    src_date2 = str_get_cols(dh2_src, 0, 7)
    src_hour1 = str_get_cols(dh1_src, 8, 9)
    src_hour2 = str_get_cols(dh2_src, 8, 9)

    date1 = str_get_cols(dh1, 0, 7)
    date2 = str_get_cols(dh2, 0, 7)
    hour1 = str_get_cols(dh1, 8, 9)
    hour2 = str_get_cols(dh2, 8, 9)

    dh_series = render_dh_series(dh1, dh2)

    if (var .eq. "O3_MDA8") then
        vnf = "O3"; varname final
    else
        vnf = var
    end if

    exec_str = "sqlite3 " + db + " 'select " + vnf + " from " + str_get_dq() + code + str_get_dq() + " where printf(" + str_get_dq() + "%s%02d" + str_get_dq() + ", date, hour) >= " + str_get_dq() + src_date1 + src_hour1 + str_get_dq() + " and printf(" + str_get_dq() + "%s%02d" + str_get_dq() + ", date, hour) <= " + str_get_dq() + src_date2 + src_hour2 + str_get_dq() + "'"
    data_str = systemfunc(exec_str)
    ; print(exec_str)
    data_str@_FillValue = ""
    data = tofloat(data_str)

    assert(dimsizes(data) .eq. dimsizes(dh_series), "function <get_obs_db_data> : time range out of database! from " + dh1 + " to " + dh2)  ; # added in 2021-07-11

    res = True
    if (method .eq. "hourly") then
        res@data = data
        res@time = dh_series

    elseif (method .eq. "average" .and. var .eq. "O3_MDA8") then
        if (hour1 .ne. "00" .or. hour2 .ne. "23") then
            print("mda8 need complete days, e.g., from 0 to 23")
            exit()
        end if
        ymd_series = str_get_cols(dh_series, 0, 7)
        data_mda8 = hour2MDA8(data, 0, 0)
        res@data = avg(data_mda8)
        res@time = "average"

    elseif (method .eq. "average") then
        if (.not. all(ismissing(data))) then
            res@data = avg(data)
        else 
            res@data = initArray(1, data)
        end if
        res@time = "average"

    elseif (method .eq. "daily" .and. var .eq. "O3_MDA8") then
        if (hour1 .ne. "00" .or. hour2 .ne. "23") then
            print("mda8 need complete days, e.g., from 0 to 23")
            exit()
        end if
        ymd_series = str_get_cols(dh_series, 0, 7)
        data_mda8 = hour2MDA8(data, 0, 0)
        res@data = data_mda8
        res@time = get_unique_values(ymd_series)

    elseif (method .eq. "daily") then
        ymd_series = str_get_cols(dh_series, 0, 7)
        if (hour1 .ne. "00" .or. hour2 .ne. "23") then
            print("method <daily> need complete days, e.g., from 0 to 23")
            exit() 
        end if
        nhours = dimsizes(dh_series) + (23 - toint(hour2)) + toint(hour1)
        ndays = nhours / 24

        data_daily = dim_avg_label_n(data, ymd_series, 0)

        res@data = data_daily
        res@time = get_unique_values(ymd_series)

    elseif (method .eq. "monthly" .and. var .eq. "O3_MDA8") then
        if (hour1 .ne. "00" .or. hour2 .ne. "23") then
            print("mda8 need complete days, e.g., from 0 to 23")
            exit()
        end if
        ymd_series = str_get_cols(dh_series, 0, 7)
        data_mda8 = hour2MDA8(data, 0, 0)

        ym_series = str_get_cols(get_unique_values(ymd_series), 0, 5)
        data_monthly_mda8 = dim_avg_label_n(data_mda8, ym_series, 0)

        res@data = data_monthly_mda8
        res@time = get_unique_values(ym_series)

    elseif (method .eq. "monthly") then
        if (hour1 .ne. "00" .or. hour2 .ne. "23") then
            print("method <daily> need complete days, e.g., from 0 to 23")
            exit()
        end if
        ym_series = str_get_cols(dh_series, 0, 5)
    
        nmonths = dimsizes(get_unique_values(ym_series))
        data_monthly = dim_avg_label_n(data, ym_series, 0)

        res@data = data_monthly
        res@time = get_unique_values(ym_series)

    elseif (method .eq. "seasonal" .and. var .eq. "O3_MDA8") then
        print("plz add code!")
        exit()

    elseif (method .eq. "seasonal") then
        if (hour1 .ne. "00" .or. hour2 .ne. "23") then
            print("method <daily> need complete days, e.g., from 0 to 23")
            exit()
        end if
        opt = 1
        opt@format = "%Y%N%D%H"
        season_series = get_season_from_str(dh_series, opt) ; integer
        year_series = str_get_cols(dh_series, 0, 3)         ; string
        year_season_series = year_series + id2season(season_series)
        nseasons = dimsizes(get_unique_values(season_series))

        data_seasonal = dim_avg_label_n(data, season_series, 0)

        res@data = data_seasonal
        res@time = get_unique_values(year_season_series)

    elseif (method .eq. "annual") then
        print("plz add code!")
        exit()

    elseif (method .eq. "annual") then
        if (hour1 .ne. "00" .or. hour2 .ne. "23") then
            print("method <daily> need complete days, e.g., from 0 to 23")
            exit()
        end if
        year_series = str_get_cols(dh_series, 0, 3)
        data_annual = dim_avg_label_n(data, year_series, 0)

        res@data = data_annual
        res@time = get_unique_values(year_series)

    end if

    return res

end