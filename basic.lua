local print_table = require"print".print_table
local get_params = function(params_list)
    local params = {}
    for i = 1, #params_list do
        local key = params_list[i][1]
        local value = params_list[i][2]
        params[key] = value
    end
    return params
end

local func = function(func_name)
    return function(params_define_list)
        return function(func_list)
            local env = {}
            env[func_name] = function(params_list)
                local params = get_params(params_list)
                print_table(params_list)
                print_table(params)
                return func_list[1](params)
            end
            for i = 1, #params_define_list, 2 do
                local var_name = params_define_list[i + 1]
                local var_type_func = params_define_list[i]
                env[var_name] = function(val)
                    return var_type_func(var_name, val)
                end
            end
            return env
        end
    end
end

local run_with_env = function(chunk, env) load(chunk, nil, nil, env)() end
local function run_in_sandbox(chunk, env)
    local ConncatEnv = function(env1, env2)
        local newEnv = {}
        for key, value in pairs(env1) do newEnv[key] = value end
        for key, value in pairs(env2) do newEnv[key] = value end
        return newEnv
    end
    local CachedEnv = _ENV
    _ENV = ConncatEnv(_ENV, env)
    chunk()
    _ENV = CachedEnv
end

local number = function(name, num) return {name, tonumber(num)} end
local boolean = function(name, bool) return {name, bool == "true"} end
local vector = function(name, vec)
    local x, y, z = string.match(vec, "(%d+),(%d+),(%d+)")
    return {name, {x = x, y = y, z = z}}
end

local env = func "MoveTo" {
    number, "_delay", boolean, "_import", vector, "Loc", boolean, "IsJump"
} {
    function(params)
        print_table(params._delay)
        print_table(params._import)
        print_table(params.Loc)
        print_table(params.IsJump)
    end
}

local print_env = func "Print" {number, "value"} {
    function(params) print(params.value) end
}

run_in_sandbox(function()
    MoveTo {_delay "1", _import "true", Loc "100,100,300", IsJump "true"}
end, env)

run_in_sandbox(function() Print {value "1"} end, print_env)
run_with_env(
    "MoveTo {_delay \"1\", _import \"true\", Loc \"100,100,300\", IsJump \"true\"}",
    env)
