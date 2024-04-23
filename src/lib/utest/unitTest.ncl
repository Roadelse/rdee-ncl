load "$NCL_RDEE/lib/rdee.ncl"

; this script acts as an unit test for functions within c4.ncl

undef("test_dim_shiftTC_n")
procedure test_dim_shiftTC_n()
begin
    ; ----- construct 1-day and 20-day hourly data
    data1 = random_uniform(0, 10, (/24, 2, 2/))
    data2 = random_uniform(0, 10, (/240, 2, 2/))
    data3 = random_uniform(0, 10, 24)


    opt = 1
    opt@tc_src = 0
    opt@tc_dst = 8

; ################ data1
    print(">>>>>>>>>>>>> direct avg")
    write_matrix(dim_avg_n(data1, 0), "2f6.2", False)
    print(">>>>>>>>>>>>> direct avg from 0 to 15")
    write_matrix(dim_avg_n(data1(0:15, :, :), 0), "2f6.2", False)


    ; ----- usemiss
    opt@mode = "usemiss"
    data1_stc = dim_shiftTC_n(data1, 0, opt)
    print(">>>>>>>>>>>>> usemiss")
    write_matrix(dim_avg_n(data1_stc, 0), "2f6.2", False)

    ; ----- nextday
    opt@mode = "nextday"
    data1_stc = dim_shiftTC_n(data1, 0, opt)
    print(">>>>>>>>>>>>> nextday")
    write_matrix(dim_avg_n(data1_stc, 0), "2f6.2", False)

    ; ----- explicit
    opt@mode = "explicit"
    opt@missData = random_uniform(0, 10, (/8, 2, 2/))
    data1_stc = dim_shiftTC_n(data1, 0, opt)
    print(">>>>>>>>>>>>> explicit")
    write_matrix(dim_avg_n(data1_stc, 0), "2f6.2", False)


; ################ data3

    ; print(">>>>>>>>>>>>> direct avg")
    ; print("" + avg(data3))
    ; print(">>>>>>>>>>>>> direct avg from 8")
    ; print("" + avg(data3(8:)))

    ; print("data3 = " + str_join("" + data3, ","))

    ; ; ----- usemiss
    ; opt@mode = "usemiss"
    ; data3_stc = dim_shiftTC_n(data3, 0, opt)
    ; print(">>>>>>>>>>>>> usemiss")
    ; print("" + avg(data3_stc))

    ; ; ----- nextday
    ; opt@mode = "nextday"
    ; data3_stc = dim_shiftTC_n(data3, 0, opt)
    ; print(">>>>>>>>>>>>> nextday")
    ; print("" + avg(data3_stc))

    ; print("data3_stc = " + str_join("" + data3_stc, ","))

    ; ; ----- explicit
    ; opt@mode = "explicit"
    ; opt@missData = random_uniform(0, 10, 8)
    ; data3_stc = dim_shiftTC_n(data3, 0, opt)
    ; print(">>>>>>>>>>>>> explicit")
    ; print("" + avg(data3_stc))


end

undef("test_render_di")
procedure test_render_di()
begin
    print(render_di("20120501", "20120630", "ALL", "ALL", "ALL"))
    print(render_di("20120501", "20120630", "ALL", "ALL", "05"))
    print(render_di("20120501", "20120630", "ALL", "ALL", "06"))
    print(render_di("20120501", "20120630", "ALL", "1", "ALL"))
    print(render_di("20120501", "20120630", "2030", "1", "ALL"))
end


undef("test_dim_xxx_m2s_n")
procedure test_dim_xxx_m2s_n()
begin
    yms = (/"201701", "201702", "201703", "201704", "201705", "201706", "201707", "201708", "201709", "201710", "201711", "201712"/)
    data = (/1,2,3,4,5,6,7,8,9,10,11,12./)
    res = dim_xxx_m2s_n(data, 0, yms, "sum")
    print(res)

end

undef("test_dim_xxx_cate_n")
procedure test_dim_xxx_cate_n()
begin
    ; test : dim_xxx_cate_n, assignValue, slice_rmd
    

    data1 = (/1,2,3,4,5,6,7,8,9,10,11/)
    labels1 = (/0,0,0,1,1,1,2,2,3,4,1/)
    cates1 = (/0, 1, 2, 3, 4/)

    res1 = dim_xxx_cate_n(data1, labels1, cates1, 0, "sum")
    print(res1)

    data2 = (/(/1,2,3,4,5/), (/6,7,8,9,10/)/)
    labels2 = (/0,1,0,2,1/)
    cates2 = (/0,1,2/)
    res2 = dim_xxx_cate_n(data2, labels2, cates2, 1, "sum")
    print(res2)
end


undef("test_dim_xxx_label_n")
procedure test_dim_xxx_label_n()
begin
    ; test : dim_xxx_label_n, dim_xxx_n
    

    data1 = (/1,2,3,4,5,6,7,8,9,10/)
    labels1 = (/0,0,0,1,1,1,2,2,3,4/)
    labels1B = (/4, 0,0,0,1,1,1,2,2,3/)

    res1 = dim_xxx_label_n(data1, labels1B, 0, "sum")
    print(res1)
end


undef("test_transform_time_reso_rtc")
procedure test_transform_time_reso_rtc()
begin
    ; ; not valid online
    ; load "$PCS/configPCS.ncl"
    ; opt_pcs = 1
    ; opt_pcs@case = "hist"
    ; opt_pcs@tc = 8

    ; config = GC(opt_pcs)

    ; f1 = addfile(config@WRF_L1_DAILY_DATA, "r")
    ; f2 = addfile(config@WRF_L1_MONTHLY_DATA, "r")
    ; f3 = addfile(config@WRF_L1_SEASONAL_DATA, "r")
    ; f4 = addfile(config@WRF_L1_OMONTHLY_DATA, "r")
    ; f5 = addfile(config@WRF_L1_OSEASONAL_DATA, "r")

    ; T2_f1 = f1->T2
    ; days = f1->days
    ; T2_f2 = f2->T2
    ; T2_f3 = f3->T2
    ; T2_f4 = f4->T2
    ; T2_f5 = f5->T2

    ; opt_ttrr = 1
    ; opt_ttrr@method = "avg"
    ; opt_ttrr@time_reso_dst = "monthly"
    ; opt_ttrr@time_fmt_src = "%Y%N%D"

    ; T2_f1_MONTHLY = transform_time_reso_rtc(T2_f1, 0, days, opt_ttrr)
    ; print(sum(abs(T2_f1_MONTHLY - T2_f2)))

    ; opt_ttrr@time_reso_dst = "seasonal"
    ; T2_f1_SEASONAL = transform_time_reso_rtc(T2_f1, 0, days, opt_ttrr)
    ; print(sum(abs(T2_f1_SEASONAL - T2_f3)))

    ; opt_ttrr@time_reso_dst = "Omonthly"
    ; T2_f1_OMONTHLY = transform_time_reso_rtc(T2_f1, 0, days, opt_ttrr)
    ; print(sum(abs(T2_f1_OMONTHLY - T2_f4)))

    ; opt_ttrr@time_reso_dst = "Oseasonal"
    ; T2_f1_OSEASONAL = transform_time_reso_rtc(T2_f1, 0, days, opt_ttrr)
    ; print(sum(abs(T2_f1_OSEASONAL - T2_f5)))
    ; ; print(sum(T2_f1_OSEASONAL))
    ; ; print(sum(T2_f5))
    return

end

undef("test_hour2daily")
procedure test_hour2daily()
begin
    data1 = ispan(1, 48, 1)
    opt = 1
    opt@method = "avg"
    data1_daily = hour2daily(data1, 0, opt)
    print(data1_daily)

    data2 = new ((/3, 48/), double)
    data2(0, :) = todouble(ispan(1, 48, 1))
    data2(1, :) = todouble(ispan(1, 48, 1))
    data2(2, :) = todouble(ispan(1, 48, 1))
    data2_daily = hour2daily(data2, 1, opt)
    print(data2_daily)

end

undef("test_hour2daily_tct")
procedure test_hour2daily_tct()
begin
    data1 = ispan(1, 48, 1)
    opt = 1
    opt@method = "avg"
    opt@mode = "nextday"
    opt@tc_src = 0
    opt@tc_dst = 8
    data1_daily = hour2daily_tct(data1, 0, opt)
    print(data1_daily)

    data2 = new ((/3, 48/), double)
    data2(0, :) = todouble(ispan(1, 48, 1))
    data2(1, :) = todouble(ispan(1, 48, 1))
    data2(2, :) = todouble(ispan(1, 48, 1))
    data2_daily = hour2daily_tct(data2, 1, opt)
    print(data2_daily)

end


undef("test_xy2ll_and_ll2xy_lcc")
procedure test_xy2ll_and_ll2xy_lcc()
begin
    f = addfile("materials/llpc_cmaq_cn36_136x205.nc", "r")
    x = f@XORIG
    y = f@YORIG

    phi0 = f@YCENT
    phi1 = f@P_ALP
    phi2 = f@P_BET

    lambda0 = f@P_GAM

    latBL = f@latBL
    lonBL = f@lonBL

    opt = True

    opt@phi0 = phi0
    opt@phi1 = phi1
    opt@phi2 = phi2
    opt@lambda0 = lambda0

    ll_from_xy = xy2ll_lam(x, y, opt)
    xy_from_ll = ll2xy_lam(lonBL, latBL, opt)

    print("x = " + x + ", y = " + y + ", x-fromll = " +  xy_from_ll(0) + ", y-fromll = " + xy_from_ll(1))
    print("lon = " + lonBL + ", lat = " + latBL + ", lon-fromxy = " +  ll_from_xy(0) + ", lat-fromxy = " + ll_from_xy(1))


end


undef("test_splitIntsDef")
procedure test_splitIntsDef()
begin
    iDef = "2015-2017,2022-2020,2030,2031,2040-2050,2070-2069"
    print(splitIntsDef(iDef, "-", ","))

end

undef("test_resolveYMS")
procedure test_resolveYMS()
local opt
begin
    opt = True
    print(resolveYMS("2015-2019|06,2017-2015|08,2015_2017_2016|12,201501-201503,2018|12_01_04,2017-2015_2019||11", opt))

end


begin
    ; test_dim_shiftTC_n()

    test_dim_xxx_m2s_n()

    ; test_dim_xxx_cate_n()

    ; test_dim_xxx_label_n()

    ; test_transform_time_reso_rtc()

    ; test_hour2daily()
    ; test_hour2daily_tct()

    ; test_xy2ll_and_ll2xy_lcc()

    ; test_splitIntsDef()

    ; test_resolveYMS()

end