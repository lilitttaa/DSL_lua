print_table = require "print".print_table
local vm = {}
function vm:init()
    self.stack = {}
	self.constants = {}
	self.registers = {}
    self.pc = 1
end

-- 执行指令
function vm:execute(program)
    self:init()
    while self.pc <= #program do
        local code = program[self.pc] -- 当前指令
		local opcode
		if(type(code)=='function') then
			opcode = code()
		else
			opcode = code[1]
		end
		local case={
			LOAD = function()
				local value = code[2] -- 要加载的值
				table.insert(self.stack, value)
				self.pc = self.pc + 1
			end,
			ADD = function()
				local a = table.remove(self.stack)
				local b = table.remove(self.stack)
				table.insert(self.stack, a + b)
				self.pc = self.pc + 1
			end,
			SUB = function()
				local a = table.remove(self.stack)
				local b = table.remove(self.stack)
				table.insert(self.stack, a - b)
				self.pc = self.pc + 1
			end,
			PRINT = function()
				local value = table.remove(self.stack)
				print(value)
				self.pc = self.pc + 1
			end
		}

        if case[opcode] then
			case[opcode]()
		else
			error("Unknown opcode: " .. opcode)
		end
    end
end

local LOAD = function(val)
	return {"LOAD",val[1]}
end

local ADD = function()
	return "ADD"
end

local SUB = function()
	return "SUB"
end

local PRINT = function()
	return "PRINT"
end

local program = {
	LOAD{20},
	LOAD{10},
	ADD,
	PRINT,
}



vm:execute(program)