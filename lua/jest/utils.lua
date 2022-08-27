local M = {}

M.parse_output = function(data)
    for _, line in ipairs(data) do
        local success, json = pcall(vim.json.decode, line)
        if success then return json end
    end
end

M.find_jest_paths = function()
    local relative_path = vim.fn.expand("%")
    local absolute_path = vim.fn.expand("%:p")
    local node_modules = vim.fn.finddir("node_modules", absolute_path .. ";")
    local jest_executable = vim.fn.findfile("jest.js", node_modules .. "/jest/bin")

    if jest_executable then
        local root_dir = string.gsub(node_modules, "node_modules", "")
        -- Return the jest executable and root directory path
        return string.gsub(absolute_path, relative_path, jest_executable),
               string.gsub(absolute_path, relative_path, root_dir)
    end
end

M.icons = {success = "✓", error = "✕", result = "●"}

return M
