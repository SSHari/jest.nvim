local M = {}

M.parse_output = function(data)
    for _, line in ipairs(data) do
        local success, json = pcall(vim.json.decode, line)
        if success then return json end
    end
end

M.find_root_dir = function(root_markers)
    local full_path = vim.fn.expand("%:p")
    return vim.fs.dirname(vim.fs.find(root_markers, {path = full_path, upward = true})[1])
end

M.find_matching_command = function(jest_commands, root_dir)
    for _, command_tuple in ipairs(jest_commands) do
        local path_regex = command_tuple[1]
        local jest_command = command_tuple[2]

        if string.match(root_dir, path_regex) then return jest_command end
    end
end

M.icons = {success = "✓", error = "✕", result = "●"}

return M
