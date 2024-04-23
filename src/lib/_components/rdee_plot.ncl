
; Customized functions/procedures regarding plot
; category : plot 



;**********************************************************************
;Trim png figures
; ImageMagick must be installed!
;**********************************************************************
undef("trimPic")
procedure trimPic(pic)
begin
    system("convert -trim '" + pic + "' '" + pic + "'")
end



;**********************************************************************
; Auto-calculate panels layout (for gsnPanelRowSpec only)
;**********************************************************************
undef("setGrid")
function setGrid(n, opt)
; n     : total number of panels
; opt   : not used, just set 0
; return ->
;        the number of panels for each row
local x, k, remainder, res
begin
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



;**********************************************************************
; convert integer RGB(0~255) to float RGB (0~1)
;**********************************************************************
undef("RGB_i2f")
function RGB_i2f(arr)
begin
    dims = dimsizes(arr)
    ndims = dimsizes(dims)

    assert(ndims .lt. 3, "function<RGB_i2f> Error! unsupported ndims = " + ndims)

    if (ndims .eq. 1) then
        assert(dims .eq. 4, "function<RGB_i2f> Error! unsupported dims = " + dims)
        rst = (/arr(0) / 255., arr(1) / 255., arr(2) / 255., arr(3)/)
    else 
        assert(dims(1) .eq. 4, "function<RGB_i2f> Error! unsupported dims(1) = " + dims(1))
        rst = tofloat(arr)
        rst(:, :2) = arr(:, :2) / 255.
    end if

    return rst
end



;**********************************************************************
; Get positions for x-titles, given one specific plot 
;**********************************************************************
undef("get_xtitle_position")
function get_xtitle_position(plot, dy)
local vpy, vpx, vph
begin
  getvalues plot
      "vpYF"       : vpy
      "vpXF"       : vpx
      "vpWidthF"   : vpw
  end getvalues
  pos = (/vpx + 0.5 * vpw,vpy + dy/)
  return(pos)
end



;**********************************************************************
; Get positions for y-titles, given one specific plot 
;**********************************************************************
undef("get_ytitle_position")
function get_ytitle_position(plot ,dx)
local vpy, vpx, vph
begin
  getvalues plot
      "vpYF"       : vpy
      "vpXF"       : vpx
      "vpHeightF"  : vph
  end getvalues
  pos = (/vpx + dx, vpy- vph * 0.5/)
  return(pos)
end