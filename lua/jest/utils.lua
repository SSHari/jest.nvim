local M = {}

M.parse_output = function(data)
    for _, line in ipairs(data) do
        local success, json = pcall(vim.json.decode, line)
        if success then return json end
    end
end

M.find_jest_executable = function()
    local node_modules = vim.fn.finddir("node_modules", ";")
    return vim.fn.findfile("jest.js", node_modules .. "/jest/bin")
end

M.icons = {success = "✓", error = "✕", result = "●"}

return M
