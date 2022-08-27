local M = {}

-- Set custom loader colors
vim.cmd([[highlight Loader ctermfg=7 guifg=#99D59D gui=bold ]])

-- Loader adapted from: https://github.com/sindresorhus/cli-spinners
local loader_frames = {"( ●    )", "(  ●   )", "(   ●  )", "(    ● )", "(     ●)",
                       "(    ● )", "(   ●  )", "(  ●   )", "( ●    )", "(●     )"}

local create_runner = function(bufnr)
    local run_config = {current_frame = 10, done = false}

    function run_config:update_frame()
        if self.done then return end

        local current_frame = self.current_frame

        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {"Jest: " .. loader_frames[current_frame]})

        self.current_frame = current_frame + 1
        if self.current_frame == 11 then self.current_frame = 1 end

        vim.defer_fn(function()
            self.update_frame(self)
        end, 500)
    end

    return run_config
end

M.start = function()
    local status_line_height = 0
    local last_status = vim.opt.laststatus:get()

    -- Calculation pulled from: https://github.com/j-hui/fidget.nvim/blob/main/lua/fidget.lua#L110
    if last_status == 2 or last_status == 3
        or (last_status == 1 and #vim.api.nvim_tabpage_list_wins() > 1) then
        status_line_height = 1
    end

    -- Build the buffer and window
    local bufnr = vim.api.nvim_create_buf(false, true)
    local winnr = vim.api.nvim_open_win(bufnr, false, {
        relative = "editor",
        anchor = "SE",
        width = 14,
        height = 1,
        row = vim.opt.lines:get() - status_line_height - vim.opt.cmdheight:get(),
        col = vim.opt.columns:get(),
        focusable = false,
        style = "minimal",
        noautocmd = true
    })

    -- Set the window styles
    vim.api.nvim_win_call(winnr, function()
        vim.cmd("setlocal winblend=100")
        vim.cmd("setlocal winhighlight=Normal:Loader")
    end)

    local run_config = create_runner(bufnr)
    vim.schedule(function()
        run_config.update_frame(run_config)
    end)

    local stop = function()
        run_config.done = true
        vim.api.nvim_win_close(winnr, false)
        vim.api.nvim_buf_delete(bufnr, {})
    end

    return stop
end

return M
