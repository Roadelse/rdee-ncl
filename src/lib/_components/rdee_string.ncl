
; Customized functions/procedures regarding string processing
; category : string



;**********************************************************************
; This function is a modified version of str_get_field
; since the original function will not take empty field into consideration
;**********************************************************************
undef("str_get_field_we")
function str_get_field_we(string_val : string, field_number[1] : integer, delimiter[1] : string)
begin
    table = str_split_csv(string_val, delimiter, 0)
    table@_FillValue = ""

    delete(table@_FillValue)

    return table(:, field_number - 1)

end
