local print_table = function(t)
    local print_table_cache = {}
    local function sub_print_table(t, indent)
        if print_table_cache[tostring(t)] then
            print(indent .. "*" .. tostring(t))
        else
            print_table_cache[tostring(t)] = true
            if type(t) == "table" then
                for pos, val in pairs(t) do
					pos = tostring(pos)
                    if type(val) == "table" then
                        print(indent .. "[" .. pos .. "] => " .. tostring(t) ..
                                  " {")
                        sub_print_table(val, indent ..
                                            string.rep(" ", string.len(pos) + 8))
                        print(indent .. string.rep(" ", string.len(pos) + 6) ..
                                  "}")
                    elseif type(val) == "string" then
                        print(indent .. "[" .. pos .. '] => "' .. val .. '"')
                    else
                        print(indent .. "[" .. pos .. "] => " .. tostring(val))
                    end
                end
            else
                print(indent .. tostring(t))
            end
        end
    end
    if type(t) == "table" then
        print(tostring(t) .. " {")
        sub_print_table(t, "  ")
        print("}")
    else
        sub_print_table(t, "  ")
    end
end
return {print_table = print_table}
