
; Customized functions/procedures regarding geophysical processing
; category : geophysical processing



;**********************************************************************
; Convert lat/lon to x/y in LambertConformal projection
; based on https://mathworld.wolfram.com/LambertConformalConicProjection.html
;**********************************************************************
undef("ll2xy_lam")
function ll2xy_lam(lon_deg, lat_deg, opt)
; lon_deg, lat_deg : longitude and latitude in degrees
; opt -
;   @rearth     : radius of earth
;   @lambda0    : reference longitude
;   @phi0       : reference latitude
;   @phi1       : standard parallels
;   @phi2       : standard parallels
local rearth, lambda0_deg, phi0_deg, phi1_deg, phi2_deg, pi, pi4, pi2, d2r, lambda0, phi0, phi1, phi2, lambda, phi, n, F, rho, rho0, x, y
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



;**********************************************************************
; This function is used to convert x/y to lat/lon in LambertConformal
; projections
; based on https://mathworld.wolfram.com/LambertConformalConicProjection.html
;**********************************************************************
undef("xy2ll_lam")
function xy2ll_lam(x, y, opt)
; x, y : coordinates in LCC projection (usually meters)
; opt -
;   @rearth     : radius of earth
;   @lambda0    : reference longitude
;   @phi0       : reference latitude
;   @phi1       : standard parallels
;   @phi2       : standard parallels
local rearth, lambda0_deg, phi0_deg, phi1_deg, phi2_deg, pi, pi4, pi2, d2r, r2d, xd, yd, lambda0, phi0, phi1, phi2, n, F, rho0, rho, theta, lambda, phi, lon_deg, lat_deg
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



;**********************************************************************
; Calculate time zone from longitude
;**********************************************************************
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



;**********************************************************************
; Render lat/lon in grid corners from lat/lon-DOT obtained from 
; mcip GRIDDOT file (for CMAQ simulations)
;**********************************************************************
undef("render_4corners_latlon_from_dot")
function render_4corners_latlon_from_dot(lat_dot, lon_dot, opt)
local nrowD, ncolD, nrowC, ncolC, r, c, lat2d_4corners, lon2d_4corner, res
; opt - not used currently, just set 0
begin
    nrowD = dimsizes(lat_dot(:, 0))
    ncolD = dimsizes(lat_dot(0, :))
    nrowC = nrowD - 1
    ncolC = ncolD - 1
    lat2d_4corners = new ((/nrowC, ncolC, 4/), float)
    lon2d_4corners = new ((/nrowC, ncolC, 4/), float)
    do r = 0, nrowC - 1
    do c = 0, ncolC - 1
        lat2d_4corners(r, c, 0) = lat_dot(r, c)
        lat2d_4corners(r, c, 1) = lat_dot(r + 1, c)
        lat2d_4corners(r, c, 2) = lat_dot(r + 1, c + 1)
        lat2d_4corners(r, c, 3) = lat_dot(r, c + 1)
        lon2d_4corners(r, c, 0) = lon_dot(r, c)
        lon2d_4corners(r, c, 1) = lon_dot(r + 1, c)
        lon2d_4corners(r, c, 2) = lon_dot(r + 1, c + 1)
        lon2d_4corners(r, c, 3) = lon_dot(r, c + 1)
    end do
    end do

    res = 1
    res@lat2d_4corners = lat2d_4corners
    res@lon2d_4corners = lon2d_4corners

    return res
end



;**********************************************************************
; Render lat/lon in grid corners from 1-dimensional lat/lon array and bins
;**********************************************************************
undef("render_4corners_latlon_in_rect_grids")
function render_4corners_latlon_in_rect_grids(lat1d, lon1d, lat_bin, lon_bin)
local lat2d, lon2d, r, c, lat2d_4corners, lon2d_4corners, res
begin
    lat2d = new ((/dimsizes(lat1d), dimsizes(lon1d)/), typeof(lat1d))
    lon2d = lat2d
    do r = 0, dimsizes(lat1d) - 1
        lat2d(r, :) = lat1d(r)
    end do
    do c = 0, dimsizes(lon1d) - 1
        lon2d(:, c) = lon1d(c)
    end do
    lat2d_4corners = new ((/dimsizes(lat1d), dimsizes(lon1d), 4/), typeof(lat1d))
    lon2d_4corners = lat2d_4corners
    do r = 0, dimsizes(lat1d) - 1
    do c = 0, dimsizes(lon1d) - 1
        lat2d_4corners(r, c, 0) = lat2d(r, c) - lat_bin / 2 
        lat2d_4corners(r, c, 1) = lat2d(r, c) + lat_bin / 2 
        lat2d_4corners(r, c, 2) = lat2d(r, c) + lat_bin / 2 
        lat2d_4corners(r, c, 3) = lat2d(r, c) - lat_bin / 2 

        lon2d_4corners(r, c, 0) = lon2d(r, c) - lon_bin / 2
        lon2d_4corners(r, c, 1) = lon2d(r, c) - lon_bin / 2
        lon2d_4corners(r, c, 2) = lon2d(r, c) + lon_bin / 2
        lon2d_4corners(r, c, 3) = lon2d(r, c) + lon_bin / 2
    end do
    end do

    res = 1
    res@lat2d = lat2d
    res@lon2d = lon2d
    res@lat2d_4corners = lat2d_4corners
    res@lon2d_4corners = lon2d_4corners

    return res

end



undef("remove_pts_pp")
function remove_pts_pp(lats, lons, opt)
; opt - currently not used, just set to 0
local ind90_idct, i, j, res, res_lats, res_lons
begin

    ind90_idct = where(lats .eq. 90 .or. lats .eq. -90, 1, 0) ; indicator
    do i = 0, dimsizes(lats) - 1
        if (ind90_idct(i) .eq. 1) then
            ind90_idct(i) = 0
            break
        end if
    end do

    res_lats = lats(ind(ind90_idct .eq. 0))
    res_lons = lons(ind(ind90_idct .eq. 0))

    res = True
    res@lats = res_lats
    res@lons = res_lons

    return res

end



;**********************************************************************
; Calculate grid areas for rectangular grids
;**********************************************************************
undef("getArea_rect_grids")
function getArea_rect_grids(ClatG, ClonG, latG_bin, lonG_bin, opt)
; ClatG, ClonG          : lat/lon at corners/boundary of each grid
; latG_bin, lonG_bin    : interval of lat/lon
; opt - 
;       @rspn           : radius of earth (determining unit)
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
        fixLL = remove_pts_pp(BlatG(r, c, :), BlonG(r, c, :), 0) ; points in polar point
        area(r, c) = area_poly_sphere(fixLL@lats, fixLL@lons, rspn)   ; m^2
    end do
    end do

    return area
end



;**********************************************************************
; Calculate grid areas for curvilinear grids
;**********************************************************************
undef("getArea_curv_grids")
function getArea_curv_grids(Blat, Blon, opt)
; Blat, Blon    : lat2d/lon2d at corners/boundary
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



;**********************************************************************
; Attach lat/lon info to data
; both 2-d and 1-d lat/lon are available
;**********************************************************************
undef("assignLatLon")
procedure assignLatLon(data, lat, lon)
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



;**********************************************************************
; This procedure is used to check if the (i, j) grid is the closest grid
; according to given lat/lon
;>>>>>>>>>>>>>>>>>>>>>>>>
; DEPRECATED
;     because there may exist a point locating in one grid but the smallest
;     diff of sum of abs of lat/lon is another adjacent grid! for lcc projection
;**********************************************************************
undef("__ensureClosestGrid")
procedure __ensureClosestGrid(lat, lon, i, j, latG, lonG, opt)
; opt@
;     mode : near / full
begin
    ndims_LL = dimsizes(dimsizes(latG))
    mode = "near"
    if (isatt(opt, "mode")) then
        mode = opt@mode
    end if
    if (ndims_LL .eq. 1) then
        diffNow = abs(latG(j) - lat) + abs(lonG(i) - lon)
        if (mode .eq. "full") then
            do iT = 0, dimsizes(lonG) - 1
            do jT = 0, dimsizes(latG) - 1
                diffT = abs(latG(jT) - lat) + abs(lonG(iT) - lon)
                if (diffT .lt. diffNow) then
                    print("find closer grid for lat = " + lat + ", lon = " + lon + ", now i = " + i + ", j = " + j + ", latTar = " + latG(j) + ", lonTar = " + lonG(i) + ", closer i = " + iT + ", j = " + jT + ", latCloser = " + latG(jT) + ", lonCloser = " + lonG(iT))
                    exit()
                end if
            end do
            end do
        elseif (mode .eq. "near") then
            do iT = i - 1, i + 1
            do jT = j - 1, j + 1
                if (iT .ge. 0 .and. iT .lt. dimsizes(lonG) .and. jT .ge. 0 .and. jT .lt. dimsizes(latG)) then
                    diffT = abs(latG(jT) - lat) + abs(lonG(iT) - lon)
                    if (diffT .lt. diffNow) then
                        print("find closer grid for lat = " + lat + ", lon = " + lon + ", now i = " + i + ", j = " + j + ", latTar = " + latG(j) + ", lonTar = " + lonG(i) + ", closer i = " + iT + ", j = " + jT + ", latCloser = " + latG(jT) + ", lonCloser = " + lonG(iT))
                        exit()
                    end if
                end if
            end do
            end do
        else
            print("unknown mode " + mode)
            exit()
        end if
    elseif (ndims_LL .eq. 2) then
        diffNow = abs(latG(j, i) - lat) + abs(lonG(j, i) - lon)
        if (mode .eq. "full") then
            do iT = 0, dimsizes(lonG(:, 0)) - 1
            do jT = 0, dimsizes(latG(0, :)) - 1
                diffT = abs(latG(jT, iT) - lat) + abs(lonG(jT, iT) - lon)
                if (diffT .lt. diffNow) then
                    print("find closer grid for lat = " + lat + ", lon = " + lon + ", now i = " + i + ", j = " + j + ", latTar = " + latG(j, i) + ", lonTar = " + lonG(j, i) + ", closer i = " + iT + ", j = " + jT + ", latCloser = " + latG(jT, iT) + ", lonCloser = " + lonG(jT, iT))
                    exit()
                end if
            end do
            end do
        elseif (mode .eq. "near") then
            do iT = i - 1, i + 1
            do jT = j - 1, j + 1
                if (iT .ge. 0 .and. iT .lt. dimsizes(lonG(0, :)) .and. jT .ge. 0 .and. jT .lt. dimsizes(latG(:, 0))) then
                    diffT = abs(latG(jT, iT) - lat) + abs(lonG(jT, iT) - lon)
                    if (diffT .lt. diffNow) then
                        print("find closer grid for lat = " + lat + ", lon = " + lon + ", now i = " + i + ", j = " + j + ", latTar = " + latG(j, i) + ", lonTar = " + lonG(j, i) + ", closer i = " + iT + ", j = " + jT + ", latCloser = " + latG(jT, iT) + ", lonCloser = " + lonG(jT, iT))
                        exit()
                    end if
                end if
            end do
            end do
        else
            print("unknown mode " + mode)
            exit()
        end if
    end if
end


;**********************************************************************
; WAITING
; This procedure is used to test if a point located in a grid
;**********************************************************************
undef("grid_inout")
function grid_inout(plat, plon)
begin
    ; Need to be developed
    ; for latlon grids and lcc grids
    return 0
end
