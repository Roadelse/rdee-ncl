load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_inv_string.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

; some common functions


;**********************************************************************
; This function is used to print with time
;**********************************************************************
undef("logT")
procedure logT(S[1] : string)
begin
    now = systemfunc("date '+%Y/%m/%d %H:%M:%S'")
    print(now + " - " + S)
end


undef("assert")
procedure assert(L, hint)
; L - logical variable, length = 1
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
        print(hint)
        exit()
    end if
end



undef("addfile_crmo")  ; addfile, create. remove thd old one if exists
function addfile_crmo(filename)
begin
    if (fileexists(filename)) then
        system("rm -f " + filename)
    end if
    f = addfile(filename, "c")
    return f
end 


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

undef("checkEnv")
procedure checkEnv(val, env)
; check existence of env var, after sentence "val = getenv(env)"
begin
    if (ismissing(val)) then
        print("env " + env + " is not set, please check the env")
        exit()
    end if
end

undef("checkFileExist")
procedure checkFileExist(File)
; check existence of the file
begin
    if (.not.fileexists(File)) then
        print("file doesn't exist! -> " + File)
        exit()
    end if
end

undef("checkEfExist")
procedure checkEfExist(File, env)
; check file existence which is archived through genenv
begin
    checkEnv(File, env)
    checkFileExist(File)
end

undef("checkDim")
procedure checkDim(data, dims, vname)
begin
    if (any(dimsizes(data) .ne. dims)) then
        print("dimension error for " + vname)
        exit()
    end if
end


undef("testDimName")
function testDimName(data, dimNames, vname)
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

undef("checkDimName")
procedure checkDimName(data, dimNames, vname)
begin
    if (any(getVarDimNames(data) .ne. dimNames)) then
        print("dimension name error for " + vname)
        exit()
    end if
end


undef("checkENUM")
procedure checkENUM(vn, tar, avail)
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
        print("Error! " + vn + " should be one of " + str_join(avail, ", "))
        exit()
    end if
end


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

undef("readD")
function readD(name, RM)
begin
;    if (.not. fileexists("saveD/" + name + ".nc")) then
;        status = False
;        return -1
;    else
;        status = True
        f = addfile("saveD/" + name + ".nc", "r")
        if (RM .eq. "R") then
            res = (/f->$name$/)
            return res
        else
            return f->$name$
        end if
;    end if
end


undef("get1dR")
function get1dR(data)
begin

if (all(ismissing(data))) then
    print("<get1dR> argument-data contains all misisng values! fails!")
    exit()
end if

dt_1d = ndtooned(data)
dt_1d_real = dt_1d(ind(.not.ismissing(dt_1d)))

return dt_1d_real

end

undef("getPercentile")
function getPercentile(data, ps)
; ps - an array of values from 0 to 1, representing percentils
begin
dt1dR = get1dR(data)

qsort(dt1dR)

res = new (dimsizes(ps), typeof(dt1dR))
do i = 0, dimsizes(ps) - 1
    psT = ps(i)
    targetPos = toint(dimsizes(dt1dR) * 1.0 * psT - 1)
    ; print("totalSize = " + dimsizes(dt1dR) + ", targetPos = " + targetPos)
    res(i) = dt1dR(targetPos)
end do

return res

end

undef("ensureDirExist")
procedure ensureDirExist(dir)
begin
    if (.not. fileexists(dir))
        system("mkdir -p " + dir)
    end if
end
undef("ensureDirExists")
procedure ensureDirExists(dir)
begin
    if (.not. fileexists(dir))
        system("mkdir -p " + dir)
    end if
end


undef("getenv_secure")
function getenv_secure(envName, default)
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


undef("ll2xy_lam")
function ll2xy_lam(lon_deg, lat_deg, opt)
begin
    if (isatt(opt, "rearth")) then
        rearth = todouble(opt@rearth)
    else
        rearth = 6370000d
    end if
    if (.not. isatt(opt, "lambda0") .or. .not. isatt(opt, "phi0") .or. .not. isatt(opt, "phi1") .or. .not. isatt(opt, "phi2")) then
        print("opt requires attribues : lambda0, phi0, phi1, phi2")
        exit()
    else
        lambda0_deg = opt@lambda0
        phi0_deg = opt@phi0
        phi1_deg = opt@phi1
        phi2_deg = opt@phi2
    end if



    pi = get_pi("d")
    pi4 = pi / 4
    pi2 = pi / 2
    d2r = get_d2r("d")

    lambda0 = d2r * lambda0_deg
    phi0 = d2r * phi0_deg
    phi1 = d2r * phi1_deg
    phi2 = d2r * phi2_deg

    lambda = d2r * todouble(lon_deg)
    phi = d2r * todouble(lat_deg)

    n = log(cos(phi1) / cos(phi2)) / log(tan(pi4 + phi2/2) / tan(pi4 + phi1/2))
    F = rearth * cos(phi1) * (tan(pi4 + phi1/2)^n) / n
    rho = F / (tan(pi4 + phi/2)^n)
    rho0 = F / (tan(pi4 + phi0/2)^n)

    x = rho * sin(n * (lambda - lambda0))
    y = rho0 - rho * cos(n * (lambda - lambda0))


    return (/x, y/) 
end


undef("xy2ll_lam")
function xy2ll_lam(x, y, opt)
begin
    if (isatt(opt, "rearth")) then
        rearth = todouble(opt@rearth)
    else
        rearth = 6370000d
    end if
    if (.not. isatt(opt, "lambda0") .or. .not. isatt(opt, "phi0") .or. .not. isatt(opt, "phi1") .or. .not. isatt(opt, "phi2")) then
        print("opt requires attribues : lambda0, phi0, phi1, phi2")
        exit()
    else
        lambda0_deg = opt@lambda0
        phi0_deg = opt@phi0
        phi1_deg = opt@phi1
        phi2_deg = opt@phi2
    end if

    pi = get_pi("d")
    pi4 = pi / 4
    pi2 = pi / 2
    d2r = get_d2r("d")
    r2d = get_r2d("d")

    xd = todouble(x)
    yd = todouble(y)

    lambda0 = d2r * lambda0_deg
    phi0 = d2r * phi0_deg
    phi1 = d2r * phi1_deg
    phi2 = d2r * phi2_deg

    n = log(cos(phi1) / cos(phi2)) / log(tan(pi4 + phi2/2) / tan(pi4 + phi1/2))
    F = rearth * cos(phi1) * (tan(pi4 + phi1/2)^n) / n
    
    rho0 = F / (tan(pi4 + phi0/2)^n)
;    print(rho0)
    rho = sign_matlab(n) * sqrt(xd^2 + (rho0 - yd)^2)
;    print(rho)
    ; rho = F / (tan(pi4 + phi/2)^n)
    if (xd .eq. 0) then
        theta = 0d
    else
        theta =  atan(xd / (rho0 - yd))
    end if

    lambda = lambda0 + theta / n
    phi = 2 * atan((F / rho)^(1/n)) - pi2

    lon_deg = r2d * lambda
    lat_deg = r2d * phi


    return (/lon_deg, lat_deg/)
end

undef("lon2timezone")
function lon2timezone(lon)
local res
begin
    if (lon .ge. 0) then
        res = toint((lon + 7.5) / 15.)
    else
        res = toint((lon - 7.5) / 15.)
    end if
    return res
end


undef("render_corner_latlon_from_dot")
function render_corner_latlon_from_dot(lat_dot, lon_dot, opt)
local nrowD, ncolD, nrowC, ncolC, r, c, lat_corners, lon_corner, res
begin
    nrowD = dimsizes(lat_dot(:, 0))
    ncolD = dimsizes(lat_dot(0, :))
    nrowC = nrowD - 1
    ncolC = ncolD - 1
    lat2d_corners = new ((/nrowC, ncolC, 4/), float)
    lon2d_corners = new ((/nrowC, ncolC, 4/), float)
    do r = 0, nrowC - 1
    do c = 0, ncolC - 1
        lat2d_corners(r, c, 0) = lat_dot(r, c)
        lat2d_corners(r, c, 1) = lat_dot(r + 1, c)
        lat2d_corners(r, c, 2) = lat_dot(r + 1, c + 1)
        lat2d_corners(r, c, 3) = lat_dot(r, c + 1)
        lon2d_corners(r, c, 0) = lon_dot(r, c)
        lon2d_corners(r, c, 1) = lon_dot(r + 1, c)
        lon2d_corners(r, c, 2) = lon_dot(r + 1, c + 1)
        lon2d_corners(r, c, 3) = lon_dot(r, c + 1)
    end do
    end do

    res = 1
    res@lat2d_corners = lat2d_corners
    res@lon2d_corners = lon2d_corners

    return res
end

undef("render_corner_latlon_in_rect_grids")
function render_corner_latlon_in_rect_grids(lat1d, lon1d, lat_bin, lon_bin)
local lat2d, lon2d, r, c, lat2d_corners, lon2d_corners, res
begin
    lat2d = new ((/dimsizes(lat1d), dimsizes(lon1d)/), float)
    lon2d = lat2d
    do r = 0, dimsizes(lat1d) - 1
        lat2d(r, :) = lat1d(r)
    end do
    do c = 0, dimsizes(lon1d) - 1
        lon2d(:, c) = lon1d(c)
    end do
    lat2d_corners = new ((/dimsizes(lat1d), dimsizes(lon1d), 4/), float)
    lon2d_corners = lat2d_corners
    do r = 0, dimsizes(lat1d) - 1
    do c = 0, dimsizes(lon1d) - 1
        lat2d_corners(r, c, 0) = lat2d(r, c) - lat_bin / 2 
        lat2d_corners(r, c, 1) = lat2d(r, c) + lat_bin / 2 
        lat2d_corners(r, c, 2) = lat2d(r, c) + lat_bin / 2 
        lat2d_corners(r, c, 3) = lat2d(r, c) - lat_bin / 2 

        lon2d_corners(r, c, 0) = lon2d(r, c) - lon_bin / 2
        lon2d_corners(r, c, 1) = lon2d(r, c) - lon_bin / 2
        lon2d_corners(r, c, 2) = lon2d(r, c) + lon_bin / 2
        lon2d_corners(r, c, 3) = lon2d(r, c) + lon_bin / 2
    end do
    end do

    res = 1
    res@lat2d = lat2d
    res@lon2d = lon2d
    res@lat2d_corners = lat2d_corners
    res@lon2d_corners = lon2d_corners

    return res

end

undef("getArea_rect_grids")
function getArea_rect_grids(ClatG, ClonG, latG_bin, lonG_bin, opt)
local ClatG2d, ClonG2d, r, c, area, nrowG, ncolG, BlatG, BlonG, rspn
begin
    if (dimsizes(dimsizes(ClatG)) .eq. 1) then
        ClatG2d = new ((/dimsizes(ClatG), dimsizes(ClonG)/), typeof(ClatG))
        ClonG2d = ClatG2d
        do r = 0, dimsizes(ClatG2d(:, 0)) - 1
            ClonG2d(r, :) = ClonG
        end do
        do c = 0, dimsizes(ClatG2d(0, :)) - 1
            ClatG2d(:, c) = ClatG
        end do
    else
        ClatG2d = ClatG
        ClonG2d = ClonG
    end if

    area = new (dimsizes(ClatG2d), typeof(ClatG2d))
    nrowG = dimsizes(ClatG2d(:, 0))
    ncolG = dimsizes(ClatG2d(0, :))
    BlatG = new ((/nrowG, ncolG, 4/), typeof(ClatG2d))    ; order? 
    BlonG = BlatG
    do r = 0, nrowG - 1
    do c = 0, ncolG - 1
        BlatG(r, c, 0) = ClatG2d(r, c) -  latG_bin / 2 
        BlatG(r, c, 1) = ClatG2d(r, c) +  latG_bin / 2 
        BlatG(r, c, 2) = ClatG2d(r, c) +  latG_bin / 2 
        BlatG(r, c, 3) = ClatG2d(r, c) -  latG_bin / 2 

        BlonG(r, c, 0) = ClonG2d(r, c) - lonG_bin / 2
        BlonG(r, c, 1) = ClonG2d(r, c) - lonG_bin / 2
        BlonG(r, c, 2) = ClonG2d(r, c) + lonG_bin / 2
        BlonG(r, c, 3) = ClonG2d(r, c) + lonG_bin / 2
    end do
    end do

    if (isatt(opt, "rspn")) then
        rspn = opt@r
    else
        rspn = 6.37122e06  ; m^2
    end if

    do r = 0, nrowG - 1
    do c = 0, ncolG - 1
        area(r, c) = area_poly_sphere(BlatG(r, c, :), BlonG(r, c, :), rspn)   ; m^2
    end do
    end do

    return area
end

undef("getArea_curv_grids")
function getArea_curv_grids(Blat, Blon, opt)
begin
    if (dimsizes(dimsizes(Blat)) .ne. 2 .or. dimsizes(dimsizes(Blon)) .ne. 2) then
        print("Blat and Blon should be 2-dimensional array!")
        exit()
    end if

    rows = dimsizes(Blat(:, 0)) - 1
    cols = dimsizes(Blat(0, :)) - 1

    area = new ((/rows, cols/), float)

    Blat_grid_corners = new ((/rows, cols, 4/), float)    ; order? 
    Blon_grid_corners = Blat_grid_corners
    do r = 0, rows - 1
    do c = 0, cols - 1
        Blat_grid_corners(r, c, 0) = Blat(r, c)
        Blat_grid_corners(r, c, 1) = Blat(r + 1, c)
        Blat_grid_corners(r, c, 2) = Blat(r + 1, c + 1)
        Blat_grid_corners(r, c, 3) = Blat(r, c + 1)

        Blon_grid_corners(r, c, 0) = Blon(r, c)
        Blon_grid_corners(r, c, 1) = Blon(r + 1, c)
        Blon_grid_corners(r, c, 2) = Blon(r + 1, c + 1)
        Blon_grid_corners(r, c, 3) = Blon(r, c + 1)
    end do
    end do

    if (isatt(opt, "rspn")) then
        rspn = opt@r
    else
        rspn = 6.37122e06  ; m^2
    end if

    do r = 0, rows - 1
    do c = 0, cols - 1
        area(r, c) = area_poly_sphere(Blat_grid_corners(r, c, :), Blon_grid_corners(r, c, :), rspn)   ; m^2
    end do
    end do

    return area
end

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

undef("assignDim")
procedure assignDim(data, dims)
begin
    ndim = dimsizes(dimsizes(data))
    if (ndim .ne. dimsizes(dims)) then
        print("the number of dimensions from data shoule be equal to dims!")
        exit()
    end if
    if (ndim .ge. 1) then
        data!0 = dims(0)
    end if
    if (ndim .ge. 2) then
        data!1 = dims(1)
    end if
    if (ndim .ge. 3) then
        data!2 = dims(2)
    end if
    if (ndim .ge. 4) then
        data!3 = dims(3)
    end if
    if (ndim .ge. 5) then
        data!4 = dims(4)
    end if
    if (ndim .ge. 6) then
        data!5 = dims(5)
    end if
    if (ndim .ge. 7) then
        data!6 = dims(6)
    end if
end

undef("assignLatLon")
procedure assignLatLon(data, lat, lon)
; this procedure is used to add lat/lon dimension and coordinate to a multiple-dimensional data
; @2020-12-22 14:30:37
begin
    ; ----- 2-dimensional lat/lon
    if (dimsizes(dimsizes(lat)) .eq. 2) then
        data@lat2d = lat
        data@lon2d = lon
        return
    end if

    ; ----- 1-dimensional lat/lon
    if (dimsizes(dimsizes(data)) .eq. 2) then
        data!0 = "lat"
        data!1 = "lon"
    elseif (dimsizes(dimsizes(data)) .eq. 3) then
        data!1 = "lat"
        data!2 = "lon"
    elseif (dimsizes(dimsizes(data)) .eq. 4) then
        data!2 = "lat"
        data!3 = "lon"
    elseif (dimsizes(dimsizes(data)) .eq. 5) then
        data!3 = "lat"
        data!4 = "lon"
    elseif (dimsizes(dimsizes(data)) .eq. 6) then
        data!4 = "lat"
        data!5 = "lon"
    elseif (dimsizes(dimsizes(data)) .eq. 7) then
        data!5 = "lat"
        data!6 = "lon"
    elseif (dimsizes(dimsizes(data)) .eq. 8) then
        data!6 = "lat"
        data!7 = "lon"
    else
        print("Error! function <assiagnLatLon> doesnt support data whose dimesion beyond 8")
        exit()
    end if
    data&lat = lat
    data&lon = lon
end

undef("getYYYY")
function getYYYY(date, opt)
begin
    dateStr = "" + date
    YYYY = str_get_cols(dateStr, 0, 3)
    if (opt .and. isatt(opt, "type") .and. opt@type .eq. "int") then
        return toint(YYYY)
    else
        return YYYY
    end if
end


undef("getMM")
function getMM(date, opt)
begin
    dateStr = "" + date
    MM = str_get_cols(dateStr, 4, 5)
    if (isatt(opt, "type") .and. opt@type .eq. "int") then
        return toint(MM)
    else
        return MM
    end if
end

undef("getDD")
function getDD(date, opt)
begin
    dateStr = "" + date
    DD = str_get_cols(dateStr, 6, 7)
    if (isatt(opt, "type") .and. opt@type .eq. "int") then
        return toint(DD)
    else
        return DD
    end if
end


undef("sub_getYMD")
procedure sub_getYMD(date, YYYY, MM, DD, opt)
; opt - cuurently not used
begin
    YYYY = getYYYY(date, opt)
    MM = getMM(date, opt)
    DD = getDD(date, opt)
end

undef("sub_nextMonth_YYYY_MM")
procedure sub_nextMonth_YYYY_MM(YYYY, MM)
begin
    MM = sprinti("%02i", toint(MM) + 1)
    if (MM .eq. "13") then
        MM = "01"
        YYYY = "" + (toint(YYYY) + 1)
    end if
end

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

undef("sub_lastMonth_YYYY_MM")
procedure sub_lastMonth_YYYY_MM(YYYY, MM)
begin
    MM = sprinti("%02i", toint(MM) - 1)
    if (MM .eq. "00") then
        MM = "12"
        YYYY = "" + (toint(YYYY) - 1)
    end if
end

undef("trimPic")
procedure trimPic(pic)
begin
    system("convert -trim " + pic + " " + pic)
end

undef("handle_scale_offset")
function handle_scale_offset(data)
begin
    return data * data@scale_factor + data@add_offset
end

undef("render_dh_series")
function render_dh_series(dh1, dh2)
; dh1, dh2 : string like YYYYMMDDHH
; return string series like YYYYMMDDHH
local t1, t2, format, t_series, dh_series
begin
    format = "%Y%N%D%H"
    t1 = cd_inv_string(dh1, format) ; units :       hours since 1800-01-01 00:00:00
    t2 = cd_inv_string(dh2, format) ; units :       hours since 1800-01-01 00:00:00
    t_series := todouble(ispan(toint(t1), toint(t2), 1))
    copy_VarMeta(t1, t_series)
    dh_series = cd_string(t_series, format)

    return dh_series
end

undef("render_ym_series")
function render_ym_series(ym1, ym2)
begin
    format = "%Y%N"
    format@units = "months since 1900-01-01 00:00:00"
    t1 = cd_inv_string(ym1, format) ; units :       hours since 1800-01-01 00:00:00
    t2 = cd_inv_string(ym2, format) ; units :       hours since 1800-01-01 00:00:00
    t_series := todouble(ispan(toint(t1), toint(t2), 1))
    copy_VarMeta(t1, t_series)
    ym_series = cd_string(t_series, format)

    return ym_series
end




undef("get_start_pos_for_continuous_values")
function get_start_pos_for_continuous_values(val)
begin
    if (dimsizes(dimsizes(val)) .ne. 1) then
        print("val must be 1-dimens1 data!")
        exit()
    end if
    res = new (dimsizes(val), integer)
    res = 0
    do i = 1, dimsizes(val) - 1
        if (val(i) .eq. val(i - 1)) then
            res(i) = res(i - 1)
        else
            res(i) = i
        end if
    end do
    return get_unique_values(res)
end

undef("get_start_pos_for_continuous_values_2")
function get_start_pos_for_continuous_values_2(val)
begin
    if (dimsizes(dimsizes(val)) .ne. 1) then
        print("val must be 1-dimens1 data!")
        exit()
    end if
    res = new (dimsizes(val) + 1, integer)
    res = 0
    do i = 1, dimsizes(val) - 1
        if (val(i) .eq. val(i - 1)) then
            res(i) = res(i - 1)
        else
            res(i) = i
        end if
    end do
    res(dimsizes(val)) = dimsizes(val)
    return get_unique_values(res)
end

undef("get_season_from_str")
function get_season_from_str(s, opt)
begin
    if (isatt(s, "calendar")) then
        times = cd_calendar(s, 0)
    else
        times = cd_calendar(cd_inv_string(s, opt@format), 0)
    end if
    months = times(:, 1)
    seasons = new (dimsizes(months), integer)
    seasons = where(months .ge. 3 .and. months .le. 5, 0, seasons)
    seasons = where(months .ge. 6 .and. months .le. 8, 1, seasons)
    seasons = where(months .ge. 9 .and. months .le. 11, 2, seasons)
    seasons = where(months .le. 2 .or. months .ge. 12, 3, seasons)

    return seasons

end

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
begin
    ; verbose = False
    ; if (isatt(opt, "verbose")) then
    ;     verbose = opt@verbose
    ; end if

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
    elseif (outMode .eq. "string") then
        return sprinti("%02d", seasons)
    elseif (outMode .eq. "name") then
        names = (/"spring", "summer", "fall", "winter"/)
        return names(seasons)
    else
        print("argument-opt@outMode should be one of int/integer, name and string! Error,  now is " + outMode)
        exit()
    end if

end

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


undef("dim_avg_m2s_n")
function dim_avg_m2s_n(data, idim, yms)
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

    ndims = dimsizes(dimsizes(data))

    if (idim .eq. 0 .and. ndims .eq. 3) then
        res = new ((/nyss, dimsizes(data(0, :, 0)), dimsizes(data(0, 0, :))/), typeof(data))
        do i = 0, nyss - 1
            res(i, :, :) = dim_avg_n(data(ind(yss .eq. (yssIQ(i))), :, :), idim)
        end do
        res@times = yss
    elseif (idim .eq. 0 .and. ndims .eq. 2) then
        res = new ((/nyss, dimsizes(data(0, :))/), typeof(data))
        do i = 0, nyss - 1
            res(i, :) = dim_avg_n(data(ind(yss .eq. (yssIQ(i))), :), idim)
        end do
        res@times = yss
    elseif (idim .eq. 1 .and. ndims .eq. 2) then
        res = new ((/dimsizes(data(:, 0)), nyss/), typeof(data))
        do i = 0, nyss - 1
            if (num(yss .eq. (yssIQ(i))) .eq. 1) then
                 res(:, i) = data(:, ind(yss .eq. (yssIQ(i))))
            else
                res(:, i) = dim_avg_n(data(:, ind(yss .eq. (yssIQ(i)))), idim)
            end if
        end do
        res@times = yss
    else
        print("function<dim_avg_m2s_n> currently doesn't support idim = " + idim + ", and ndims = " + ndims + ", plz update code!")
        exit()
    end if

    return res

end


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


undef("id2season")
function id2season(sid)
begin
    res = new (dimsizes(sid), string)
    res = where(sid .eq. 0, "spring", res)    
    res = where(sid .eq. 1, "summer", res)    
    res = where(sid .eq. 2, "fall", res)    
    res = where(sid .eq. 3, "winter", res)    

    return res

end

undef("dim_xxx_n")
function dim_xxx_n(data, idim, method)
begin
    if (method .eq. "avg") then
        res = dim_avg_n(data, idim)
    elseif (method .eq. "max") then
        res = dim_max_n(data, idim)
    elseif (method .eq. "min") then
        res = dim_min_n(data, idim)
    else
        print("unknown method - " + method)
        exit()
    end if

    return res

end


undef("hour2daily")
function hour2daily(data, opt)   ; dataH is a 3-d data
; data - source hourly data
; opt@
;   method = avg / max / min
begin
    nhours = dimsizes(data(:, 0, 0))
    ndays = nhours / 24
    ndim = dimsizes(dimsizes(data))
    if (isatt(opt, "method")) then
        method = opt@method
        if (method .ne. "avg" .and. method .ne. "max" .and. method .ne. "min") then
            print("method must be avg, max or min! Error , now is " + method)
            exit()
        end if
    else
        method = "avg"
    end if
    if (ndim .eq. 1) then
        res = new (ndays, float)
        do i = 0, ndays - 1
            res(i) = dim_xxx_n(data(i * 24 : i * 24 + 23), 0, method)
        end do
    elseif (ndim .eq. 2) then
        res = new ((/ndays, dimsizes(data(0, :))/), float)
        do i = 0, ndays - 1
            res(i, :) = dim_xxx_n(data(i * 24 : i * 24 + 23, :), 0, method)
        end do
    elseif (ndim .eq. 3) then
        res = new ((/ndays, dimsizes(data(0, :, 0)), dimsizes(data(0, 0, :))/), float)
        do i = 0, ndays - 1
            res(i, :, :) = dim_xxx_n(data(i * 24 : i * 24 + 23, :, :), 0, method)
        end do
    elseif (ndim .eq. 4) then
        res = new ((/ndays, dimsizes(data(0, :, 0, 0)), dimsizes(data(0, 0, :, 0)), dimsizes(data(0, 0, 0, :))/), float)
        do i = 0, ndays - 1
            res(i, :, :, :) = dim_xxx_n(data(i * 24 : i * 24 + 23, :, :, :), 0, method)
        end do
    elseif (ndim .eq. 5) then
        res = new ((/ndays, dimsizes(data(0, :, 0, 0, 0)), dimsizes(data(0, 0, :, 0, 0)), dimsizes(data(0, 0, 0, :, 0)), dimsizes(data(0, 0, 0, 0, :))/), float)
        do i = 0, ndays - 1
            res(i, :, :, :, :) = dim_xxx_n(data(i * 24 : i * 24 + 23, :, :, :, :), 0, method)
        end do
    elseif (ndim .eq. 6) then
        res = new ((/ndays, dimsizes(data(0, :, 0, 0, 0, 0)), dimsizes(data(0, 0, :, 0, 0, 0)), dimsizes(data(0, 0, 0, :, 0, 0)), dimsizes(data(0, 0, 0, 0, :, 0)), dimsizes(data(0, 0, 0, 0, 0, :))/), float)
        do i = 0, ndays - 1
            res(i, :, :, :, :, :) = dim_xxx_n(data(i * 24 : i * 24 + 23, :, :, :, :, :), 0, method)
        end do
    end if


return res

end

undef("hour2daily_tct")
function hour2daily_tct(dataR, opt)   ; time coord transform
; first dimension must be hour!
begin
    tc_src = opt@tc_src
    tc_dst = opt@tc_dst
    handleMissing = opt@handleMissing  ; misisng or nextday
    if (handleMissing .ne. "missing" .and. handleMissing .ne. "nextday") then
        print("unknown handleMissing attribute! only support missing or nextday!")
        exit()
    end if
    if (isatt(opt, "method")) then
        method = opt@method
        if (method .ne. "avg" .and. method .ne. "max" .and. method .ne. "min") then
            print("method must be avg, max or min! Error , now is " + method)
            exit()
        end if
    else
        method = "avg"
    end if    
    if (tc_src .eq. tc_dst) then
        return hour2daily(dataR, opt)
    end if
    if (tc_src .eq. 0 .and. tc_dst .gt. 0) then
        dims = dimsizes(dataR)
        nhours = dims(0)
        if (nhours % 24 .ne. 0) then
            print("就算是真的你也不可以乱slice!")
            exit()
        end if
        ndays = nhours / 24
        ndim = dimsizes(dimsizes(dataR))
        data = new (dimsizes(dataR), typeof(dataR))
        tcD = tc_dst - tc_src        

        if (ndim .eq. 1) then
            data(tcD:) = dataR(:nhours - 1 - tcD)
            if (handleMissing .eq. "nextday") then
                data(:tcD - 1) = data(24 : 24 + tcD - 1)
            end if
            res = new (ndays, float)
            do i = 0, ndays - 1
                res(i) = dim_xxx_n(data(i * 24 : i * 24 + 23), 0, method)
            end do
        elseif (ndim .eq. 2) then
            data(tcD:, :) = dataR(:nhours - 1 - tcD, :)
            if (handleMissing .eq. "nextday") then
                data(:tcD - 1, :) = data(24 : 24 + tcD - 1, :)
            end if
            res = new ((/ndays, dimsizes(data(0, :))/), float)
            do i = 0, ndays - 1
                res(i, :) = dim_xxx_n(data(i * 24 : i * 24 + 23, :), 0, method)
            end do
        elseif (ndim .eq. 3) then
            data(tcD:, :, :) = dataR(:nhours - 1 - tcD, :, :)
            if (handleMissing .eq. "nextday") then
                data(:tcD - 1, :, :) = data(24 : 24 + tcD - 1, :, :)
            end if
            res = new ((/ndays, dimsizes(data(0, :, 0)), dimsizes(data(0, 0, :))/), float)
            do i = 0, ndays - 1
                res(i, :, :) = dim_xxx_n(data(i * 24 : i * 24 + 23, :, :), 0, method)
            end do
        elseif (ndim .eq. 4) then
            data(tcD:, :, :, :) = dataR(:nhours - 1 - tcD, :, :, :)
            if (handleMissing .eq. "nextday") then
                data(:tcD - 1, :, :, :) = data(24 : 24 + tcD - 1, :, :, :)
            end if
            res = new ((/ndays, dimsizes(data(0, :, 0, 0)), dimsizes(data(0, 0, :, 0)), dimsizes(data(0, 0, 0, :))/), float)
            do i = 0, ndays - 1
                res(i, :, :, :) = dim_xxx_n(data(i * 24 : i * 24 + 23, :, :, :), 0, method)
            end do
        elseif (ndim .eq. 5) then
            data(tcD:, :, :, :, :) = dataR(:nhours - 1 - tcD, :, :, :, :)
            if (handleMissing .eq. "nextday") then
                data(:tcD - 1, :, :, :, :) = data(24 : 24 + tcD - 1, :, :, :, :)
            end if
            res = new ((/ndays, dimsizes(data(0, :, 0, 0, 0)), dimsizes(data(0, 0, :, 0, 0)), dimsizes(data(0, 0, 0, :, 0)), dimsizes(data(0, 0, 0, 0, :))/), float)
            do i = 0, ndays - 1
                res(i, :, :, :, :) = dim_xxx_n(data(i * 24 : i * 24 + 23, :, :, :, :), 0, method)
            end do
        elseif (ndim .eq. 6) then
            data(tcD:, :, :, :, :, :) = dataR(:nhours - 1 - tcD, :, :, :, :, :)
            if (handleMissing .eq. "nextday") then
                data(:tcD - 1, :, :, :, :, :) = data(24 : 24 + tcD - 1, :, :, :, :, :)
            end if
            res = new ((/ndays, dimsizes(data(0, :, 0, 0, 0, 0)), dimsizes(data(0, 0, :, 0, 0, 0)), dimsizes(data(0, 0, 0, :, 0, 0)), dimsizes(data(0, 0, 0, 0, :, 0)), dimsizes(data(0, 0, 0, 0, 0, :))/), float)
            do i = 0, ndays - 1
                res(i, :, :, :, :, :) = dim_xxx_n(data(i * 24 : i * 24 + 23, :, :, :, :, :), 0, method)
            end do
        end if
    else
        print("only support tc_src=0 and tc_dst>0 by now! plz add code!")
        exit()
    end if
    
    return res

end


undef("hour2MDA8_tct")
function hour2MDA8_tct(dataR, opt)  ; time coordinate transformation
; >>>>> parameter requirements
;   data :  hours x ... x ... x ...
;   opt  : set tc attributes
; >>>>> notes
;   Thie function DO take time-coord into consideration
local dataDims, hours, days, res, movAvgs, d, h
begin
    tc_src = opt@tc_src
    tc_dst = opt@tc_dst
    handleMissing = opt@handleMissing  ; misisng or nextday
    if (tc_src .eq. tc_dst) then
        return hour2MDA8(dataR, 0)
    end if
    if (handleMissing .ne. "missing" .and. handleMissing .ne. "nextday") then
        print("unknown handleMissing attribute! only support missing or nextday!")
        exit()
    end if

    if (tc_src .eq. 0 .and. tc_dst .gt. 0) then
        dims = dimsizes(dataR)
        nhours = dims(0)
        if (nhours % 24 .ne. 0) then
            print("就算是真的你也不可以乱slice!")
            exit()
        end if
        ndays = nhours / 24
        ndim = dimsizes(dimsizes(dataR))
        dataDims = dimsizes(dataR)
        data = new (dimsizes(dataR), typeof(dataR))
        tcD = tc_dst - tc_src  


        if (ndim .eq. 3) then
            data(tcD:, :, :) = dataR(:nhours - 1 - tcD, :, :)
            if (handleMissing .eq. "nextday") then
                data(:tcD - 1, :, :) = data(24 : 24 + tcD - 1, :, :)
            end if

            res = new ((/ndays, dataDims(1), dataDims(2)/), typeof(data))
            do d = 0, ndays - 1
                movAvgs = new ((/17, dataDims(1), dataDims(2)/), typeof(data))
                do h = 0, 16
                    movAvgs(h, :, :) = dim_avg_n(data(d * 24 + h : d * 24 + h + 7, :, :), 0)
                end do
                res(d, :, :) = dim_max_n(movAvgs, 0)
            end do
        elseif (ndim .eq. 2) then
            data(tcD:, :) = dataR(:nhours - 1 - tcD, :)
            if (handleMissing .eq. "nextday") then
                data(:tcD - 1, :) = data(24 : 24 + tcD - 1, :)
            end if
            res = new ((/ndays, dataDims(1)/), typeof(data))
            do d = 0, ndays - 1
                movAvgs = new ((/17, dataDims(1)/), typeof(data))
                do h = 0, 16
                    movAvgs(h, :) = dim_avg_n(data(d * 24 + h : d * 24 + h + 7, :), 0)
                end do
                res(d, :) = dim_max_n(movAvgs, 0)
            end do
        elseif (ndim .eq. 1) then
            data(tcD:) = dataR(:nhours - 1 - tcD)
            if (handleMissing .eq. "nextday") then
                data(:tcD - 1) = data(24 : 24 + tcD - 1)
            end if
            res = new (ndays, typeof(data))
            do d = 0, ndays - 1
                movAvgs = new (17, typeof(data))
                do h = 0, 16
                    if (.not. all(ismissing(data(d * 24 + h : d * 24 + h + 7)))) then
                        movAvgs(h) = avg(data(d * 24 + h : d * 24 + h + 7))
                    end if
                end do
                res(d) = max(movAvgs)
            end do  
        elseif (ndim .eq. 4) then
            data(tcD:, :, :, :) = dataR(:nhours - 1 - tcD, :, :, :)
            if (handleMissing .eq. "nextday") then
                data(:tcD - 1, :, :, :) = data(24 : 24 + tcD - 1, :, :, :)
            end if
            res = new ((/ndays, dataDims(1), dataDims(2), dataDims(3)/), typeof(data))
            do d = 0, ndays - 1
                movAvgs = new ((/17, dataDims(1), dataDims(2), dataDims(3)/), typeof(data))
                do h = 0, 16
                    movAvgs(h, :, :, :) = dim_avg_n(data(d * 24 + h : d * 24 + h + 7, :, :, :), 0)
                end do
                res(d, :, :, :) = dim_max_n(movAvgs, 0)
            end do

        else
            print("function <hour2MDA8> supports 1/2/3/4 dimensional data only by now! Error for " + dimsizes(dataDims))
            exit()
        end if
    end if

    return res
end



undef("hour2MDA8")
function hour2MDA8(data, opt)
; >>>>> parameter requirements
;   data :  hours x rows x cols
;   opt  : not used currectly
; >>>>> notes
;   Thie function doesn't take time-coord into consideration
local dataDims, hours, days, res, movAvgs, d, h
begin
    dataDims = dimsizes(data)
    idim = 0
    if (isatt(opt, "idim"))
        idim = opt@idim
    end if
    hours = dataDims(idim)
    if (hours % 24 .ne. 0) then
        print("Function<hour2MDA8> requires first dimension of data divisible by 24")
        exit()
    end if
    days = hours / 24
    
    if (idim .eq. 0 .and. dimsizes(dataDims) .eq. 3) then

        res = new ((/days, dataDims(1), dataDims(2)/), typeof(data))
        do d = 0, days - 1
            movAvgs = new ((/17, dataDims(1), dataDims(2)/), typeof(data))
            do h = 0, 16
                movAvgs(h, :, :) = dim_avg_n(data(d * 24 + h : d * 24 + h + 7, :, :), 0)
            end do
            res(d, :, :) = dim_max_n(movAvgs, 0)
        end do
    elseif (idim .eq. 0 .and. dimsizes(dataDims) .eq. 2) then
        res = new ((/days, dataDims(1)/), typeof(data))
        do d = 0, days - 1
            movAvgs = new ((/17, dataDims(1)/), typeof(data))
            do h = 0, 16
                movAvgs(h, :) = dim_avg_n(data(d * 24 + h : d * 24 + h + 7, :), 0)
            end do
            res(d, :) = dim_max_n(movAvgs, 0)
        end do
    elseif (idim .eq. 0 .and. dimsizes(dataDims) .eq. 1) then
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
    elseif (idim .eq. 0 .and. dimsizes(dataDims) .eq. 4) then
        res = new ((/days, dataDims(1), dataDims(2), dataDims(3)/), typeof(data))
        do d = 0, days - 1
            movAvgs = new ((/17, dataDims(1), dataDims(2), dataDims(3)/), typeof(data))
            do h = 0, 16
                movAvgs(h, :, :, :) = dim_avg_n(data(d * 24 + h : d * 24 + h + 7, :, :, :), 0)
            end do
            res(d, :, :, :) = dim_max_n(movAvgs, 0)
        end do
    elseif (idim .eq. 1 .and. dimsizes(dataDims) .eq. 2) then
        res = new ((/dataDims(0), days/), typeof(data))
        do d = 0, days - 1
            movAvgs = new ((/17, dataDims(0)/), typeof(data))
            do h = 0, 16
                movAvgs(h, :) = dim_avg_n(data(:, d * 24 + h : d * 24 + h + 7), 1)
            end do
            res(:, d) = dim_max_n(movAvgs, 0)
        end do

    else
        print("function <hour2MDA8> supports 1/2/3/4 dimensional data only by now! Error for " + dimsizes(dataDims))
        exit()
    end if

    return res
end



undef("mmul")
function mmul(x)
local res, i
begin
    if (dimsizes(dimsizes(x)) .ne. 1) then
        print("<function> mmul only supports 1-dimensional data! Error")
        exit()
    end if
    res = 1.
    do i = 0, dimsizes(x) - 1
        res = res * x(i)
    end do

    return res
end



undef("multiply_right")
function multiply_right(x, y) ; may be slower for larger array!
local ndx, ndy, res
begin
    
    ndx = dimsizes(dimsizes(x))
    ndy = dimsizes(dimsizes(y))
    ; print((/ndx, ndy/))
    if (ndx .eq. ndy) then
        return x * y
    elseif (ndx .lt. ndy) then
        res = multiply_right(y, x)
        return res
    else ; ndx > ndy
        if (mmul(dimsizes(x)) .gt. 4e8) then
            print("Note: this function <multiply_right> may be slower for larger array compared to loop!")
        end if

        corrDim = ispan(ndx-ndy, ndx-1, 1)
        res = x * conform_dims(dimsizes(x), y, corrDim)
        return res
    end if
end


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

undef("wrfTimes2str")
function wrfTimes2str(wrfTimes, format)
begin
    ; wrfTimes - YYYY-MM-DD_HH:MM:SS
    format_wrfTimes = "%Y-%N-%D_%H:%M:%S"
    dt_gre = cd_inv_string(wrfTimes, format_wrfTimes)
    timeStr = cd_string(dt_gre, format)

    return timeStr

end


undef("simplify_YJHMS")
function simplify_YJHMS(dt)
begin
    format = "%Y%J%H%M%S"
    format@units = "seconds since 2010-01-01 00:00:00"
    gre_back = cd_inv_string(dt, format)
    gre_back_plus_minor = gre_back + 0.01
    copy_VarMeta(gre_back, gre_back_plus_minor)
    return cd_string(gre_back_plus_minor, format)
end


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

undef("buildTFLAG")
function buildTFLAG(init, step, nstep)
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


undef("add_gang_in_date")
function add_gang_in_date(dateStr)
begin
    if (typeof(dateStr) .ne. "string") then
        print("function <add_gang_in_date> only support date string by now!")
        exit()
    end if
    if (strlen(dateStr) .eq. 8) then
        YYYY = str_get_cols(dateStr, 0, 3)
        MM = str_get_cols(dateStr, 4, 5)
        DD = str_get_cols(dateStr, 6, 7)
        return YYYY + "-" + MM + "-" + DD
    elseif (strlen(dateStr) .eq. 7) then
        YYYY = str_get_cols(dateStr, 0, 3)
        JJJ = str_get_cols(dateStr, 4, 6)
        return YYYY + "-" + JJJ
    else
        print("only support YYYYMMDD or YYYYJJJ now!")
        exit()
    end if

    return ""

end

undef("add_gang_in_time")
function add_gang_in_time(timeStr)
begin
    if (typeof(dateStr) .ne. "string") then
        print("function <add_gang_in_date> only support date string by now!")
        exit()
    end if
    if (strlen(dateStr) .eq. 8) then
        YYYY = str_get_cols(dateStr, 0, 3)
        MM = str_get_cols(dateStr, 4, 5)
        DD = str_get_cols(dateStr, 6, 7)
        return YYYY + "-" + MM + "-" + DD
    elseif (strlen(dateStr) .eq. 7) then
        YYYY = str_get_cols(dateStr, 0, 3)
        JJJ = str_get_cols(dateStr, 4, 6)
        return YYYY + "-" + JJJ
    elseif (strlen(dateStr) .eq. 6) then
        YYYY = str_get_cols(dateStr, 0, 3)
        MM = str_get_cols(dateStr, 4, 5)
        return YYYY + "-" + MM
    else
        print("only support YYYYMMDD or YYYYJJJ or YYYYMM now!")
        exit()
    end if

    return ""

end

undef("dim_avg_label_n_Wrap")
function dim_avg_label_n_Wrap(data, label, idim)
; NOTE : this function would not merge the discontinuous same labels!
local dims, ndim, label_sps2, res, i
begin
    dims = dimsizes(data)
    ndim = dimsizes(dims)
    if (dimsizes(label) .ne. dims(idim)) then
        print("function <avg_label> size of label should be equal to size of ndim of data")
        exit()
    end if
    label_sps2 = get_start_pos_for_continuous_values_2(label)
    dims2 = dims
    dims2(idim) = dimsizes(label_sps2) - 1
    res = new (dims2, typeof(data))
    do i = 0, dims2(idim) - 1
        if (ndim .eq. 1 .and. idim .eq. 0) then
            res(i) = dim_avg_n_Wrap(data(label_sps2(i) : label_sps2(i + 1) - 1), idim)
        elseif (ndim .eq. 2 .and. idim .eq. 0) then
            res(i, :) = dim_avg_n_Wrap(data(label_sps2(i) : label_sps2(i + 1) - 1, :), idim)
        elseif (ndim .eq. 3 .and. idim .eq. 0) then
            res(i, :, :) = dim_avg_n_Wrap(data(label_sps2(i) : label_sps2(i + 1) - 1, :, :), idim)
        elseif (ndim .eq. 4 .and. idim .eq. 0) then
            res(i, :, :, :) = dim_avg_n_Wrap(data(label_sps2(i) : label_sps2(i + 1) - 1, :, :, :), idim)
        elseif (ndim .eq. 5 .and. idim .eq. 0) then
            res(i, :, :, :, :) = dim_avg_n_Wrap(data(label_sps2(i) : label_sps2(i + 1) - 1, :, :, :, :), idim)
        elseif (ndim .eq. 2 .and. idim .eq. 1) then
            res(:, i) = dim_avg_n_Wrap(data(:, label_sps2(i) : label_sps2(i + 1) - 1), idim)
        elseif (ndim .eq. 2 .and. idim .eq. 1) then
            res(:, i) = dim_avg_n_Wrap(data(:, label_sps2(i) : label_sps2(i + 1) - 1), idim)
        else
            print("plz update function <avg_label> to support the combination of ndim and idim")
            exit()
        end if
    end do

    return res
end

undef("dim_avg_label_n")
function dim_avg_label_n(data, label, idim)
; NOTE : this function would not merge the discontinuous same labels!
local dims, ndim, label_sps2, res, i
begin
    dims = dimsizes(data)
    ndim = dimsizes(dims)
    if (dimsizes(label) .ne. dims(idim)) then
        print("function <avg_label> size of label should be equal to size of ndim of data")
        exit()
    end if
    label_sps2 = get_start_pos_for_continuous_values_2(label)
    dims2 = dims
    dims2(idim) = dimsizes(label_sps2) - 1
    res = new (dims2, typeof(data))
    do i = 0, dims2(idim) - 1
        if (ndim .eq. 1 .and. idim .eq. 0) then
            res(i) = dim_avg_n(data(label_sps2(i) : label_sps2(i + 1) - 1), idim)
        elseif (ndim .eq. 2 .and. idim .eq. 0) then
            res(i, :) = dim_avg_n(data(label_sps2(i) : label_sps2(i + 1) - 1, :), idim)
        elseif (ndim .eq. 3 .and. idim .eq. 0) then
            res(i, :, :) = dim_avg_n(data(label_sps2(i) : label_sps2(i + 1) - 1, :, :), idim)
        elseif (ndim .eq. 4 .and. idim .eq. 0) then
            res(i, :, :, :) = dim_avg_n(data(label_sps2(i) : label_sps2(i + 1) - 1, :, :, :), idim)
        elseif (ndim .eq. 5 .and. idim .eq. 0) then
            res(i, :, :, :, :) = dim_avg_n(data(label_sps2(i) : label_sps2(i + 1) - 1, :, :, :, :), idim)
        elseif (ndim .eq. 2 .and. idim .eq. 1) then
            res(:, i) = dim_avg_n(data(:, label_sps2(i) : label_sps2(i + 1) - 1), idim)
        else
            print("plz update function <avg_label> to support the combination of ndim and idim")
            exit()
        end if
    end do

    return res
end


undef("setGrid")
function setGrid(n, opt)
; auto-calculate the number of panels for each row
; the last row account for flexible adjustment
local x, k, remainder, res
begin
    ; if (isatt(opt, "manual") .and. opt@manual .ne. "") then
    ;     rspec = toint(str_split(opt@manual, ","))
    ;     return rspec
    ; else

    x = toint(sqrt(n))
    do k = x, x * x  ; nline * nline can be replaced by a reasonably big number
        if (x * (k + 1) .gt. n) then
            break 
        end if
    end do
    remainder = n - x * k
    if (remainder .ne. 0) then
        res = new (x + 1, integer)
        res(: x - 1) = k
        res(x) = remainder
    else
        res = new (x, integer)
        res(:) = k
    end if
    return res

    ; end if   
end

undef("initArray")
function initArray(dims, typeTemplate)  ; initialize array filled with _FillValue by default
begin
    type = typeof(typeTemplate)
    res = new (dims, type)
    res@_FillValue = default_fillvalue(type)
    return res
end

undef("get_obs_db_data")
function get_obs_db_data(db, var, code, dh1, dh2, opt)
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
        data_mda8 = hour2MDA8(data, 0)
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
        data_mda8 = hour2MDA8(data, 0)
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
        data_mda8 = hour2MDA8(data, 0)

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


undef("transform_time_reso_rtc")
function transform_time_reso_rtc(data, idim, time, opt) ; remain time-coord
begin
    tr_dst = opt@time_reso_dst
    tfmt_src = opt@time_format
    greTime = cd_inv_string(time, tfmt_src)

    if (tr_dst .eq. "MDA8") then
        opt_h2m = 1
        opt_h2m@idim = idim
        res = hour2MDA8(data, opt_h2m)
        return res
    end if

    if (tr_dst .eq. "daily") then
        time_dst = cd_string(greTime, "%Y%N%D")
    elseif (tr_dst .eq. "monthly") then
        time_dst = cd_string(greTime, "%Y%N")
    elseif (tr_dst .eq. "annual") then
        time_dst = cd_string(greTime, "%Y")
    elseif (tr_dst .eq. "seasonal") then
        ; print("this feature <seasonal> is currently paused")  ; The issue is about how to handle winter? if we want Jan, Feb and Dec, then <dim_avg_label_n> cannot realizes this goal 
        ; exit()
        time_dst = cd_string(greTime, "%Y%N")
        resM = dim_avg_label_n(data, time_dst, idim)
        res = dim_avg_m2s_n(resM, idim, time_dst)
        return res
    end if
    res = dim_avg_label_n(data, time_dst, idim)
    return res
end





; *********************************************************
; this function is used to operate two logical array
; currently support operator : +/-
; *********************************************************
undef("opLArray")
function opLArray(left, right, op)
local res
begin
    if (any(dimsizes(left) .ne. dimsizes(right))) then
        print("left and right array should have the same dimsize!")
        exit()
    end if
    if (op .eq. "+") then
        res = left
        res = where(right, True, res)
    elseif (op .eq. "-") then
        res = left
        res = where(right, False, res)
    else
        print("op only support + or - by now!")
        exit()
    end if
    return res
end


; *********************************************************
; this function is used to operate two 0/1 array
; currently support operator : +/-
; *********************************************************
undef("opBArray")
function opBArray(left, right, op)
begin
    if (any(left .ne. 0 .and. left .ne. 1)) then
        print("function <opBArray> requires param-left being 0 or 1")
        exit()
    end if
    if (any(right .ne. 0 .and. right .ne. 1)) then
        print("function <opBArray> requires param-right being 0 or 1")
        exit()
    end if
    if (op .eq. "+") then
        res = where((left + right) .gt. 0, 1, 0)
    elseif (op .eq. "-") then
        res = where((left - right) .gt. 0, 1, 0)
    elseif (op .eq. "*") then
        res = where((left + right) .eq. 2, 1, 0)
    else
        print("in function <opBArray>, param-op only support + or - by now!")
        exit()
    end if
    return res


end


;**********************************************************************
; this function is used to calculate metrics
;**********************************************************************
undef("evaMetrics")
function evaMetrics(xs, ys)
; ys as obs
begin
if (dimsizes(xs) .ne. dimsizes(ys)) then
    print("Error! xs and ys in <evaMetrics> should have the same size!")
    exit()
end if
lens = dimsizes(xs)
; --- Mean Bias
BIAS = sum(xs - ys) / lens
; --- Mean Error
ERROR = sum(abs(xs - ys)) / lens
; --- Normalized Mean Bias(percent)
NMB = sum(xs - ys) / sum(ys) * 100
; --- Normalized Mean Error (percent)
NME = sum(abs(xs - ys)) / sum(ys) * 100
; --- Mean Fractional Bias (percent)
FBIAS = sum((xs - ys) / (xs + ys)) / lens * 2 * 100
; --- Mean Fractional Error (percent)
FERROR = sum(abs((xs - ys) / (xs + ys))) / lens * 2 * 100
; --- Correlation Coefficient(R2)
CORRCOEFF = sum((xs - avg(xs)) * (ys - avg(ys))) / sqrt(sum((xs - avg(xs))^2) * sum((ys - avg(ys))^2))
p = rtest(CORRCOEFF, lens, 0)

res = (/BIAS, NMB, NME, FBIAS, FERROR, CORRCOEFF, p, ERROR/)

return res

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
        mdT = mds(i)
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
; this function is used to slice and remain dimensions even the length 
; of slice is 1
;**********************************************************************
undef("slice_rmd")
function slice_rmd(data, index, idim)
begin
    dims = dimsizes(data)
    ndim = dimsizes(dims)

    if (ndim .eq. 3 .and. idim .eq. 0) then
        if (dimsizes(index) .gt. 1) then
            res = data(index, :, :)
        else
            res = data(index : index, :, :)
        end if
    else
        print("unsupported ndim " + ndim + ", and idim " + idim + ", please add code!")
        exit()
    end if

    return res
end
