

; this script contains customized functions/procedures which are commonly used in my work
; category : array processing



;**********************************************************************
; This function is an implimentation of "in" in python
;**********************************************************************
undef("in")
function in(arr, ele[1])
begin
    assert(typeof(arr) .eq. typeof(ele), "function <in> requires the same type of param-arr and param-ele!")

    if (num(arr .eq. ele) .gt. 0) then
        return True
    else
        return False
    end if

end



;**********************************************************************
; This function is a "map" of function ind
;**********************************************************************
undef("ind_eq_map")
function ind_eq_map(arrP[*], arrC[*], opt)
local allowMissing, resStr, res, i, indT
begin
    allowMissing = False
    allowRepeat = False
    autoSort = False
    if (isatt(opt, "allowMissing")) then
        allowMissing = opt@allowMissing
    end if
    if (isatt(opt, "allowRepeat")) then
        allowRepeat = opt@allowRepeat
    end if
    if (isatt(opt, "autoSort")) then
        autoSort = opt@autoSort
    end if

    resStr = ""
    do i = 0, dimsizes(arrC) - 1
        indT := ind(arrP .eq. arrC(i))
        if (.not. allowRepeat) then
            print("Error! arrP have multiple arrC-elements!")
            exit()
        end if
        if (.not.all(ismissing(indT))) then
            resStr = resStr + "," + str_join("" + indT, ",")
        else
            if (.not. allowMissing) then
                print("element " + arrC(i) + " cannot be found in the parent array!")
                exit()
            end if
        end if
    end do

    if (resStr .eq. "") then
        res = new (1, integer)
        return res
    end if

    res = toint(str_split(resStr, ","))
    if (autoSort) then
        qsort(res)
    end if

    return res
end



;**********************************************************************
; This function is used to convert edge value to center value for bins
;**********************************************************************
undef("E2C")
function E2C(edges)
begin
; edges should be 1-dimensional data
    res = new (dimsizes(edges) - 1, typeof(edges))
    do i = 0, dimsizes(res) - 1
        res(i) = (edges(i) + edges(i + 1) ) / 2.
    end do

    return res

end


;**********************************************************************
; this function is used to get unique values for 1d array without sort
;**********************************************************************
undef("get_unique_values_1d_stable")
function get_unique_values_1d_stable(data[*])
local dict, holders, pos, i, strT
begin
    dict = True

    holders = new (dimsizes(data), typeof(data))

    pos = 0

    do i = 0, dimsizes(data) - 1
        strT = "" + data(i)
        if (isatt(dict, strT)) then
            continue
        end if
        holders(pos) = data(i)
        dict@$strT$ = 1
        pos = pos + 1
    end do

    res = holders(0 : pos - 1)

    return res

end



;**********************************************************************
; this function is used to slice and remain dimensions even the length 
; of slice is 1
;**********************************************************************
undef("slice_rmd")
function slice_rmd(data, index, idim)
local dims, ndim, res
begin
    dims = dimsizes(data)
    ndim = dimsizes(dims)

    if (ndim .eq. 1 .and. idim .eq. 0) then
        res = data(index)
    elseif (ndim .eq. 2 .and. idim .eq. 0) then
        if (dimsizes(index) .gt. 1) then
            res = data(index, :)
        else
            res = data(index : index, :)
        end if
    elseif (ndim .eq. 2 .and. idim .eq. 1) then
        if (dimsizes(index) .gt. 1) then
            res = data(:, index)
        else
            res = data(:, index : index)
        end if
    elseif (ndim .eq. 3 .and. idim .eq. 0) then
        if (dimsizes(index) .gt. 1) then
            res = data(index, :, :)
        else
            res = data(index : index, :, :)
        end if
    elseif (ndim .eq. 4 .and. idim .eq. 0) then
        if (dimsizes(index) .gt. 1) then
            res = data(index, :, :, :)
        else
            res = data(index : index, :, :, :)
        end if
    else
        print("function <slice_rmd> : unsupported ndim " + ndim + ", and idim " + idim + ", please add code!")
        exit()
    end if

    return res
end



;**********************************************************************
; this function is used to dynamically assign values to data slice
; use brute-force loop method
;**********************************************************************
undef("assignValue")
procedure assignValue(data, values, idims, idim_indexes)
begin
    dims = dimsizes(data)
    ndims = dimsizes(dims)

    nidims = dimsizes(idims)
    dims_ii = dimsizes(idim_indexes)
    if (nidims .eq. 1) then
        assert(dimsizes(dims_ii) .eq. 1, "function <assignValue> : unexpected dimensions of param-idim_indexes")
    else
        assert(dims_ii(0) .eq. nidims, "function <assignValue> : unexpected dimensions of param-idim_indexes")
    end if

    if (ndims .eq. 1 .and. nidims .eq. 1) then
        data(idim_indexes) = values
    elseif (ndims .eq. 2 .and. nidims .eq. 1 .and. idims .eq. 0) then
        data(idim_indexes, :) = values
    elseif (ndims .eq. 2 .and. nidims .eq. 1 .and. idims .eq. 1) then
        data(:, idim_indexes) = values
    elseif (ndims .eq. 2 .and. nidims .eq. 2 .and. all(idims .eq. (/1, 2/)))
        data(idim_indexes(0, :), idim_indexes(1, :)) = values
    elseif (ndims .eq. 2 .and. nidims .eq. 2 .and. all(idims .eq. (/2, 1/)))
        print("function <assignValue> : werid condition, anyway, ncl will go on")
        data(idim_indexes(1, :), idim_indexes(0, :)) = values
    elseif (ndims .eq. 3 .and. nidims .eq. 1 .and. idims .eq. 0) then
        data(idim_indexes, :, :) = values
    elseif (ndims .eq. 3 .and. nidims .eq. 1 .and. idims .eq. 1) then
        data(:, idim_indexes, :) = values
    elseif (ndims .eq. 3 .and. nidims .eq. 1 .and. idims .eq. 2) then
        data(:, :, idim_indexes) = values
    elseif (ndims .eq. 4 .and. nidims .eq. 1 .and. idims .eq. 0) then
        data(idim_indexes, :, :, :) = values
    elseif (ndims .eq. 4 .and. nidims .eq. 1 .and. idims .eq. 1) then
        data(:, idim_indexes, :, :) = values
    else
        print("function <assignValue> : unknown ndims = " + ndims + ", nidims = " + ndims + ", idims = " + idims)
        exit()
    end if

end



;**********************************************************************
; This function is used to convert nd-array to 1d-array and remove 
; missing values
;**********************************************************************
undef("get1dR")
function get1dR(data)
local dt_1d, dt_1d_real
begin

    if (all(ismissing(data))) then
        print("<get1dR> argument-data contains all misisng values! fails!")
        exit()
    end if

    dt_1d = ndtooned(data)
    dt_1d_real = dt_1d(ind(.not.ismissing(dt_1d)))

    return dt_1d_real

end



;**********************************************************************
; This function is used to get percentile
;**********************************************************************
undef("getPercentile")
function getPercentile(data, ps)
; data - nd-array 
; ps - an array of values from 0 to 1, representing percentils
local dt1dR, res, i, psT, targetPos
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



;**********************************************************************
; This function is used to get percentile, cumulatively, head and toe
;**********************************************************************
undef("getPercentile_cumu")
function getPercentile_cumu(data[*] : numeric, ps[*] : float)
local len, S, res, j, i, sTar, sTmp
begin
    len = dimsizes(data)
    S = sum(data)

    if (any(ps .gt. 1) .or. any(ps .lt. 0)) then
        print("function <getPercentile_cumu> : Error! ps must be >= 0 and <= 1")
        exit()
    end if

    res = ps

    do j = 0, dimsizes(ps) - 1
        p = ps(j)

        sTar = p * S

        sTmp = 0.
        do i = 0, len - 1
            if (ismissing(data(i))) then
                continue
            end if
            sTmp = sTmp + data(i)
            if (sTmp .ge. sTar) then
                break
            end if
        end do

        if (i .eq. 0) then
            res(j) = i
            continue
        end if

        res(j) = linint1((/sTmp - data(i), sTmp/), (/i - 1, i/), False, sTar, 0)

    end do

    return res

end



;**********************************************************************
; This procedure is used to assignment dimension names for nd-array
;**********************************************************************
undef("assignDim")
procedure assignDim(data, dims)
local ndim
begin
    ndim = dimsizes(dimsizes(data))
    if (ndim .ne. dimsizes(dims)) then
        print("function <assignDim> : the number of dimensions from data shoule be equal to dims!")
        exit()
    end if
    if (ndim .ge. 1 .and. dims(0) .ne. "") then
        data!0 = dims(0)
    end if
    if (ndim .ge. 2 .and. dims(1) .ne. "") then
        data!1 = dims(1)
    end if
    if (ndim .ge. 3 .and. dims(2) .ne. "") then
        data!2 = dims(2)
    end if
    if (ndim .ge. 4 .and. dims(3) .ne. "") then
        data!3 = dims(3)
    end if
    if (ndim .ge. 5 .and. dims(4) .ne. "") then
        data!4 = dims(4)
    end if
    if (ndim .ge. 6 .and. dims(5) .ne. "") then
        data!5 = dims(5)
    end if
    if (ndim .ge. 7 .and. dims(6) .ne. "") then
        data!6 = dims(6)
    end if
end



;**********************************************************************
; This procedure is used to assignment coordinates for nd-array
;**********************************************************************
undef("assignCoord")
procedure assignCoord(data, dimnames[*]:string, dict)
local ndim, dmT, i
begin
    do i = 0, dimsizes(dimnames) - 1
        dmT = dimnames(i) ; dimension name temp
        if (.not. isdim(data, dmT)) then
            print("procedure <assignCoord> : unkonwn dimension " + dmT + " for data!")
            exit()
        end if
        if (.not. isatt(dict, dmT)) then
            print("procedure <assignCoord> : unknown dimension " + dmT + " for dict!")
            exit()
        end if
        data&$dmT$ = dict@$dmT$
    end do

end



;**********************************************************************
; This function is used to obtain real data if there exists @add_offset
; and @scale_factor (usually ERA5 data)
;**********************************************************************
undef("handle_scale_offset")
function handle_scale_offset(data)
begin
    assert(isatt(data, "scale_factor") .and. isatt(data, "add_offset"), "function <handle_scale_offset> : Error! data must have attr-scale_factor and attr-add_offset!")
    return data * data@scale_factor + data@add_offset
end



;**********************************************************************
; like handle_scale_offset, but keeping its meta info
;**********************************************************************
undef("handle_scale_offset_wrap")
function handle_scale_offset_wrap(data)
begin
    assert(isatt(data, "scale_factor") .and. isatt(data, "add_offset"), "function <handle_scale_offset_wrap> : Error! data must have attr-scale_factor and attr-add_offset!")
    res = data * data@scale_factor + data@add_offset
    copy_VarMeta(data, res)
    delete(res@add_offset)
    delete(res@scale_factor)
    return res
end



;**********************************************************************
; This function is an abstract function from avg, max, 
; min, and all functions owning shape of xxx from dim_xxx_n
;**********************************************************************
undef("xxx")
function xxx(data, method)
local res
begin
    ; printVarSummary(data) ; # debug
    if (method .eq. "avg") then
        res = avg(data)
    elseif (method .eq. "max") then
        res = max(data)
    elseif (method .eq. "min") then
        res = min(data)
    elseif (method .eq. "sum") then
        res = sum(data)
    elseif (method .eq. "spread") then
        res = max(data) - min(data)
    else
        print("unknown method - " + method)
        exit()
    end if

    return res

end



;**********************************************************************
; Calculate max - min
;**********************************************************************
undef("dim_spread_n")
function dim_spread_n(data:numeric, idim:integer)
begin
    res = dim_max_n(data, idim) - dim_min_n(data, idim)
    return res
end 



;**********************************************************************
; This function is an abstract function from dim_avg_n, dim_max_n, 
; dim_min_n, and all functions owning shape of dim_xxx_n
;**********************************************************************
undef("dim_xxx_n")
function dim_xxx_n(data, idim, method)
local res
begin
    ; printVarSummary(data) ; # debug
    if (method .eq. "avg") then
        result = dim_avg_n(data, idim)
    elseif (method .eq. "max") then
        result = dim_max_n(data, idim)
    elseif (method .eq. "min") then
        result = dim_min_n(data, idim)
    elseif (method .eq. "sum") then
        result = dim_sum_n(data, idim)
    elseif (method .eq. "spread") then
        result = dim_spread_n(data, idim)
    elseif (method .eq. "std" .or. method .eq. "stddev") then
        result = dim_stddev_n(data, idim)
    else
        print("unknown method - " + method)
        exit()
    end if

    return result

end



;**********************************************************************
; This function is used to calculate Accumulate multiplication
;**********************************************************************
undef("mmul")
function mmul(x)
local res, i
begin
    assert(dimsizes(dimsizes(x)) .eq. 1, "<function> mmul only supports 1-dimensional data! Error")

    res = 1.
    do i = 0, dimsizes(x) - 1
        res = res * x(i)
    end do

    return res
end



;**********************************************************************
; This function is used to multiply two arrays with different dimensions
; with right alignment
;**********************************************************************
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



;**********************************************************************
; This function is used to get first unconsistent values for each 
; element
; for example : 
;       1,1,2,3,1,1,1,3,3,3,2
;       x   x x x     x     x   (x means the target positions)
;**********************************************************************
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
    return get_unique_values(res)  ; res is monotonically no-decrease, so get_unique_values is ok
end



;**********************************************************************
; This function is similar with get_start_pos_for_continuous_values, 
; except for the processing method of the last element 
; This function use a pseudo position at the last for convenience 
;**********************************************************************
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

    return get_unique_values(res) ; res is monotonically no-decrease, so get_unique_values is ok
end



;**********************************************************************
; This function is used to calculate average according to labels
;**********************************************************************
undef("dim_avg_label_n")
function dim_avg_label_n(data, label, idim)
; NOTE : this function would not merge the discontinuous same labels!
local dims, ndim, label_sps2, res, i
begin
    dims = dimsizes(data)
    ndim = dimsizes(dims)
    if (dimsizes(label) .ne. dims(idim)) then
        print("function <dim_avg_label_n> size of label should be equal to size of ndim of data")
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
            print("function <dim_avg_label_n> : plz update code to support the combination of ndim and idim")
            exit()
        end if
    end do

    return res
end



;**********************************************************************
; This function is used to calculate avg/sum/max/min/... according to 
; labels
;**********************************************************************
undef("dim_xxx_label_n")
function dim_xxx_label_n(data, label, idim, method)
; NOTE : this function would not merge the discontinuous same labels!
local dims, ndim, label_sps2, res, i
begin
    dims = dimsizes(data)
    ndim = dimsizes(dims)
    if (dimsizes(label) .ne. dims(idim)) then
        print("function <dim_xxx_label_n> size of label should be equal to size of ndim of data")
        printVarSummary(data)
        printVarSummary(label)
        exit()
    end if
    label_sps2 = get_start_pos_for_continuous_values_2(label)
    dims2 = dims
    dims2(idim) = dimsizes(label_sps2) - 1
    res = new (dims2, typeof(data))
    ; print(dims2)
    ; print(label_sps2)
    do i = 0, dims2(idim) - 1
        if (ndim .eq. 1 .and. idim .eq. 0) then
            res(i) = dim_xxx_n(data(label_sps2(i) : label_sps2(i + 1) - 1), idim, method)
        elseif (ndim .eq. 2 .and. idim .eq. 0) then
            res(i, :) = dim_xxx_n(data(label_sps2(i) : label_sps2(i + 1) - 1, :), idim, method)
        elseif (ndim .eq. 3 .and. idim .eq. 0) then
            res(i, :, :) = dim_xxx_n(data(label_sps2(i) : label_sps2(i + 1) - 1, :, :), idim, method)
        elseif (ndim .eq. 4 .and. idim .eq. 0) then
            res(i, :, :, :) = dim_xxx_n(data(label_sps2(i) : label_sps2(i + 1) - 1, :, :, :), idim, method)
        elseif (ndim .eq. 4 .and. idim .eq. 1) then
            res(:, i, :, :) = dim_xxx_n(data(:, label_sps2(i) : label_sps2(i + 1) - 1, :, :), idim, method)
        elseif (ndim .eq. 5 .and. idim .eq. 0) then
            res(i, :, :, :, :) = dim_xxx_n(data(label_sps2(i) : label_sps2(i + 1) - 1, :, :, :, :), idim, method)
        elseif (ndim .eq. 2 .and. idim .eq. 1) then
            res(:, i) = dim_xxx_n(data(:, label_sps2(i) : label_sps2(i + 1) - 1), idim, method)
        else
            print("function <dim_xxx_label_n> : plz update code to support the combination of ndim = " + ndim + " and idim = " + idim)
            exit()
        end if
    end do

    res@labels = get_unique_values_1d_stable(label)

    return res
end



;**********************************************************************
; This function is used to calculate avg/sum/max/min/... according to 
; labels and categories
;**********************************************************************
undef("dim_xxx_cate_n")
function dim_xxx_cate_n(data, labels, cates, idim, method)
local dims, ndim, dims2, res, i
begin
    dims = dimsizes(data)
    ndim = dimsizes(dims)
    if (dimsizes(labels) .ne. dims(idim)) then
        print("function <dim_xxx_cate_n> size of label should be equal to size of ndim of data")
        printVarSummary(labels)
        printVarSummary(data)
        exit()
    end if

    dims2 = dims
    dims2(idim) = dimsizes(cates)
    res = new (dims2, typeof(data))
    ; printVarSummary(res)

    do i = 0, dimsizes(cates) - 1

        dataCT := totype(dim_xxx_n(slice_rmd(data, ind(labels .eq. cates(i)), idim), idim, method), typeof(data))  ; children temp
        assignValue(res, dataCT, idim, i)

        ; if (ndim .eq. 1 .and. idim .eq. 0) then
        ;     res(i) = totype(xxx(data(ind(labels .eq. cates(i))), method), typeof(data))
        ; elseif (ndim .eq. 2 .and. idim .eq. 0) then
        ;     res(i, :) = totype(dim_xxx_n(slice_rmd(data, ind(labels .eq. cates(i)), idim), idim, method), typeof(data))
        ; elseif (ndim .eq. 3 .and. idim .eq. 0) then
        ;     res(i, :, :) = totype(dim_xxx_n(slice_rmd(data, ind(labels .eq. cates(i)), idim), idim, method), typeof(data))
        ; elseif (ndim .eq. 4 .and. idim .eq. 0) then
        ;     res(i, :, :, :) = totype(dim_xxx_n(slice_rmd(data, ind(labels .eq. cates(i)), idim), idim, method), typeof(data))
        ; elseif (ndim .eq. 2 .and. idim .eq. 1) then
        ;     res(:, i) = totype(dim_xxx_n(slice_rmd(data, ind(labels .eq. cates(i)), idim), idim, method), typeof(data))
        ; else
        ;     print("function <dim_xxx_cate_n> : plz update code to support the combination of ndim = " + ndim + " and idim = " + idim)
        ;     exit()
        ; end if
    end do

    return res

end



;**********************************************************************
; similar with histogram, but supporting several operations
;**********************************************************************
undef("xxx_inte")
function xxx_inte(data, values, intervals, method)
local data_dims, values_dims, res, i, L, R
begin
    data_dims = dimsizes(data)
    values_dims = dimsizes(values)

    assert(all(data_dims .eq. values_dims), "function <xxx_inte> : Error! dims must be the same!")

    res = new (dimsizes(intervals) - 1, typeof(data))
    samplesize = new (dimsizes(intervals) - 1, integer)
    samplesize = 0

    do i = 0, dimsizes(intervals) - 2
        L = intervals(i)
        R = intervals(i + 1)
        assert(R .gt. L, "function <xxx_inte> : Error! intervals must be monotonically increase!")
        dataT = mask(data, values .ge. L .and. values .lt. R, True)
        if (.not.all(ismissing(dataT))) then
            res(i) = xxx(dataT, method)
            samplesize(i) = num(.not.ismissing(dataT))
        end if
    end do

    res@sampleSize = samplesize

    return res

end

;**********************************************************************
; TO BE DEV
;**********************************************************************
undef("dim_xxx_inte_n")
function dim_xxx_inte_n(data, values, intervals, idim, method)
begin
    print("not yet")
    exit()

end



;**********************************************************************
; This function is used to calculate average according to labels
; remain metadata
;**********************************************************************
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
            print("function <dim_avg_label_n_Wrap> : plz update code to support the combination of ndim and idim")
            exit()
        end if
    end do

    return res
end



;**********************************************************************
; This function is used to init array
; similar with new, but more abstract
; more convenient when looping data with different types
;**********************************************************************
undef("initArray")
function initArray(dims, typeTemplate)  ; initialize array filled with _FillValue by default
local type, res
begin
    type = typeof(typeTemplate)
    res = new (dims, type)
    res@_FillValue = default_fillvalue(type)
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
local res
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
; this function is used to shift array by positions
; U need to point the dim to be shifted
;**********************************************************************
undef("shiftArray")
function shiftArray(data, idim[1]:integer, npos[1]:integer, fillv)
; fillv : > 0 means shift to right
local dims, ndims, res, a
begin
    if (npos .eq. 0) then
        return data
    end if

    dims = dimsizes(data)
    ndims = dimsizes(dims)

    res = new (dims, typeof(data))
    if (typeof(fillv) .eq. "string" .and. fillv .eq. "missing") then
        a = 1  ; act as pass
    else
        res = fillv
    end if

    if (ndims .eq. 3 .and. idim .eq. 0) then
        if (npos .gt. 0) then
            res(npos : , :, :) = data(:dims(0) - npos - 1, :, :)
        else
            res(:dims(0) - npos - 1, :, :) = data(npos : , :, :)
        end if
    elseif (ndims .eq. 1 .and. idim .eq. 0) then
        if (npos .gt. 0) then
            res(npos :) = data(:dims(0) - npos - 1)
        else
            res(:dims(0) - npos - 1) = data(npos :)
        end if
    else
        print("unsupported combinations of ndims = " + ndims + " and idim = " + idim)
        exit()
    end if

    return res

end



;**********************************************************************
; this function is an abstract for logical op, such as .ge., .eq.
;**********************************************************************
undef("lop")
function lop(arrL, arrR, op)
begin
    if (op .eq. "ge") then
        res = arrL .ge. arrR
    elseif (op .eq. "le") then
        res = arrL .le. arrR
    elseif (op .eq. "gt") then
        res = arrL .gt. arrR
    elseif (op .eq. "lt") then
        res = arrL .lt. arrR
    elseif (op .eq. "eq") then
        res = arrL .eq. arrR
    elseif (op .eq. "ne") then
        res = arrL .ne. arrR
    else
        print("function <lop> : unkonwn op : " + op + ", Error, plz update code")
        exit()
    end if

    return res

end



;**********************************************************************
; synchronization of 2 array
;**********************************************************************
undef("sync_array")
procedure sync_array(arr1, arr2, opt)
; opt - not used presently, just 0
local dims1, dims2
begin
    dims1 = dimsizes(arr1)
    dims2 = dimsizes(arr2)
    assert(all(dims1 .eq. dims2), "procedure <sync_array> : Error! different dimsizes!")

    ; validIndex = venn2_intersection(ind(.not.ismissing(arr1)), ind(.not.ismissing(arr1)))

    arr1 = mask(arr1, ismissing(arr2), False)
    arr2 = mask(arr2, ismissing(arr1), False)

end



;**********************************************************************
; min-max scaler
;**********************************************************************
undef("minmax_scaler")
function minmax_scaler(data[*]:numeric)
local minV, maxV, delta, res
begin
    minV = min(data)
    maxV = max(data)
    delta = maxV - minV

    res = (data - minV) / delta

    return res
end



;**********************************************************************
; calculate moving average
;**********************************************************************
undef("movAvg")
function movAvg(data, n)
local data_movAvg, i, size
begin
    size = dimsizes(data)
    data_movAvg = data
    do i = n, size - 1 - n
        if (.not. all(ismissing(data(i-n:i+n)))) then
            data_movAvg(i) = avg(data(i-n:i+n))
        end if
    end do
    return data_movAvg
end



;**********************************************************************
; calculate adjacent difference, i+1 - i
;**********************************************************************
undef("adjDiff")
function adjDiff(data)
begin
    size = dimsizes(data)
    diff = new (size, typeof(data))
    do i = 0, size - 2
        diff(i) = data(i + 1) - data(i)
    end do
    return diff
end



;**********************************************************************
; calculate skewness only
;**********************************************************************
undef("cal_skewness")
function cal_skewness(x)
local stats
begin
    stats = dim_stat4(x)
    return stats(2)
end 



;**********************************************************************
; Convert definition of a series of integer into an array
; supporting "to" and "sep" sign
;**********************************************************************
undef("splitIntsDef")
function splitIntsDef(idef, to, sep)
; to : from A to B, usually "-", such as 2015-2020, 1-9
; sep : seperator, usually ",", such as "1,3,5,7"
begin
    pos_sep = str_index_of_substr(idef, sep, 1)
    if (ismissing(pos_sep)) then
        if (str_match_bool(idef, to)) then
            i_pair = toint(str_split(idef, to))
            if (i_pair(0) .lt. i_pair(1)) then
                iList = ispan(i_pair(0), i_pair(1), 1)
            else
                iList = ispan(i_pair(1), i_pair(0), 1)
                iList = iList(::-1)
            end if
            return iList 
        else
            return toint(idef)
        end if
    else
        res = array_append_record(splitIntsDef(str_get_cols(idef, 0, pos_sep - 1), to, sep), splitIntsDef(str_get_cols(idef, pos_sep + 1, -1), to, sep), 0)
        return res
    end if

end