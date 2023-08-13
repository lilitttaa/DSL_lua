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

local FUNC = function(func_name)
    return function(params_define_list)
        return function(func_wrapp)
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

			local params_env = {}
			-- 对参数进行包装
            local func = function(params_list)
                local params = get_params(func_name, params_list)
                return func_wrapp[1](params)
            end
			-- 将参数类型检查函数存到params_env中等待使用
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

--[[
	类型检查函数
]]--
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

local string = function(name, val)
	if type(val) ~= 'string' then
		error("type need to be string name: " .. name .. "val" .. val)
	end
	return {name, val}
end

-- 顺序指令
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

-- 并行指令
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

-- -- JUMP指令
-- local JUMP = function(pc)
-- 	return function(next)
-- 		print("JUMP " .. pc)
-- 		next()
-- 	end
-- end

-- -- Push指令
-- local PUSH = function(pc)
-- 	return function(next)
-- 		print("PUSH " .. pc)
-- 		next()
-- 	end
-- end

-- -- POP指令
-- local POP = function()
-- 	return function(next)
-- 		print("POP")
-- 		next()
-- 	end
-- end

-- -- Call指令
-- local CALL = function(addr)
-- 	return function(next)
-- 		print("CALL " .. addr)
-- 		next()
-- 	end
-- end

-- local ADDI = function()
-- 	return function(next)
-- 		print("ADDI ")
-- 		next()
-- 	end
-- end


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
        print("parse error:"..errorMsg..extra_error_msg)
    end
end






-- usecase
dsl.define_scripts {
    FUNC "MoveTo" {number, "_delay", boolean, "_import", vector, "loc", number, "speed"} {
        function(params)
            return function(next)
                print_table(params)
                next()
            end
        end
    },
	FUNC "SetPlayerLoc" {vector,"loc"} {
		function(params)
			return function (next)
				print_table(params)
				next()
			end
		end
	}
}

dsl.run_dsl([[
	SEQ{
		MoveTo{_delay{2.2},_import{true},loc{{100,100,300}},speed{343}},
		PARA{
			MoveTo{loc{{100,100,300}},speed{123}},
			MoveTo{loc{{100,100,300}},speed{32}},
		},
		MoveTo{_delay{245},_import{true},loc{{100,100,300}},speed{42}},
		SetPlayerLoc{loc{{523,43,54}}},
	}
]], function() print("end_dsl") end,", invalid dialogue:[100101]")



-- TALK{"场景一"}{
-- 	boolean,"disable_skip"
-- }
-- SEQ{
-- 	PARA{
-- 		"对话1",
-- 		ACTION{Char_heitao{"动作1"},Char_hongtao{"动作2"}},
-- 		TURNTO{Char_heitao{45},Char_hongtao{90},Char_hong{Char_hongtao}},
-- 		AUDIO{"音效1"},
-- 		CAMERA{_delay{1.5},height{100},loc{100,100}},
-- 	},
-- 	OPTION{
-- 		"选项1",EXIT{},
-- 		"选项2",EXIT{},
-- 		"选项3",PARA{
-- 			"对话1",
-- 		}
-- 	},
-- 	"对话2",
-- 	JUMP "场景二",
-- }


