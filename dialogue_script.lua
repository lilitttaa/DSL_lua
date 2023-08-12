local print_table = require"print".print_table
local SEQ = function(statements)
    local pc = 1
    return function(next)
        local function loc_next()
            local statement = statements[pc]
            pc = pc + 1
            if statement then
                statement(loc_next)
            else
                next()
            end
        end
        loc_next()
    end
end

local PARA = function(statements)
    local wait_count = #statements
    return function(next)
        local function local_next()
            wait_count = wait_count - 1
            if wait_count == 0 then next() end
        end
        for i = 1, #statements do statements[i](local_next) end
    end
end

local get_params = function(func_name, params_list)
    local params = {}
    for i = 1, #params_list do
        local param_pair = params_list[i]()
        local param_name = param_pair[1]
        local param_val = param_pair[2]
        -- local params_env = _ENV[_ENV[func_name]]
        -- params_env[param_name](param_val)
        params[param_name] = param_val
    end
    return params
end

local FUNC = function(func_name)
    return function(params_define_list)
        return function(func_wrapp)
            local params_env = {}
            local func = function(params_list)
                local params = get_params(func_name, params_list)
                return func_wrapp[1](params)
            end
            for i = 1, #params_define_list, 2 do
                local var_name = params_define_list[i + 1]
                local var_type_func = params_define_list[i]
                params_env[var_name] = function(val)
                    return var_type_func(var_name, val)
                end
            end
            return {func_name, func, params_env}
        end
    end
end

local number = function(name, val)
    if type(val) ~= 'number' then
        error("type need to be number name: " .. name .. " val: " .. val)
    end
    return {name, val}
end

local boolean = function(name, val)
    if type(val) ~= 'boolean' then
        error("type need to be boolean name: " .. name .. "val" .. val)
    end
    return {name, val}
end

local vector = function(name, val)
    if type(val) ~= 'table' then
        error("type need to be vector name: " .. name .. "val" .. tostring(val))
    end
    return {name, val}
end

local dsl = {}
dsl.sandbox_env = setmetatable({
    print = print,
    require = require,
    error = error,
    print_table = print_table,
    SEQ = SEQ,
    PARA = PARA
}, {
    __index = function(t, k)
        return function(vals) return function() return {k, vals[1]} end end
    end
})

dsl.define_scripts = function(func_infos)
    for _, func_info in ipairs(func_infos) do
        local func_name, func, params_env = func_info[1], func_info[2],
                                            func_info[3]
        dsl.sandbox_env[func_name] = func
        dsl.sandbox_env[func] = params_env
    end
end

dsl.run_dsl = function(chunk, callback,extra_error_msg)
    callback = callback or function() end
    dsl.sandbox_env.callback = callback
    local success, errorMsg = pcall(function()
        load(chunk .. "(callback)", "chunk", "t", dsl.sandbox_env)()
    end)

    if not success then
        print("parse error:"..errorMsg..extra_error_msg) -- 打印错误消息
    end
end

dsl.define_scripts {
    FUNC "MoveTo" {
        number, "_delay", boolean, "_import", vector, "loc", boolean, "is_jump"
    } {
        function(params)
            return function(next)
                print_table(params)
                next()
            end
        end
    }
}

dsl.run_dsl([[
	SEQ{
		MoveTo{_delay{2.2},_import{true},loc{{100,100,300}},is_jump{true}},
		PARA{
			MoveTo{loc{{100,100,300}},is_jump{true}},
			MoveTo{loc{{100,100,300}},is_jump{true}},
		},
		MoveTo{_delay{245},_import{true},loc{{100,100,300}},is_jump{true}},
	}
]], function() print("end_dsl") end,", invalid dialogue:[100101]")

