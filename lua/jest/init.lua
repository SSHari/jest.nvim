local loader = require("jest.loader")
local utils = require("jest.utils")

local M = {}

local ns = vim.api.nvim_create_namespace("TheSSHGuy_jest.nvim")

local create_jest_run_autocmd = function(config)
    local autocmd_nr = vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("TheSSHGuy_jest.nvim", {clear = true}),
        pattern = config.pattern,
        callback = function()
            -- Skip trying to run the tests if a root dir can't be found
            local root_dir = utils.find_root_dir(config.root_markers)
            if not root_dir then return end

            local bufnr = vim.api.nvim_get_current_buf()
            local bufnm = vim.api.nvim_buf_get_name(bufnr)

            -- Clear previous diagnostics
            vim.diagnostic.reset(ns, bufnr)

            -- Clear previous namespace highlights
            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

            local append_data = function(_, data)
                if data then
                    local json = utils.parse_output(data)
                    if not json then return end

                    local testResults = json.testResults[1]
                    local assertionResults = testResults.assertionResults
                    local messages = vim.split(vim.trim(testResults.message), utils.icons.result)

                    -- Remove the leading empty space
                    table.remove(messages, 1)

                    -- Keep track of diagnostics for any test that failed
                    local diagnostics = {}

                    for _, result in ipairs(assertionResults) do
                        -- lines are 0 based in nvim_buf_set_extmark but 1 based in jest
                        local line = result.location.line - 1

                        if result.status == "passed" then
                            -- Set status icon
                            local text = {utils.icons.success, "DiagnosticInfo"}
                            vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {virt_text = {text}})
                        end

                        if result.status == "failed" then
                            -- Set status icon
                            local text = {utils.icons.error, "DiagnosticError"}
                            vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {virt_text = {text}})

                            -- Create diagnostics for test error
                            local message = table.remove(messages, 1)
                            local diagnostic_structure = {
                                bufnr = bufnr,
                                lnum = line,
                                end_lnum = line,
                                col = 0,
                                message = utils.icons.result .. message,
                                source = "jest.nvim diagnostics"
                            }

                            table.insert(diagnostics, diagnostic_structure)
                        end
                    end

                    -- Display any additional errors on the first row
                    for _, message in ipairs(messages) do
                        local diagnostic_structure = {
                            bufnr = bufnr,
                            lnum = 0,
                            end_lnum = 0,
                            col = 0,
                            message = utils.icons.result .. message,
                            source = "jest.nvim diagnostics"
                        }

                        table.insert(diagnostics, diagnostic_structure)
                    end

                    -- Set the diagnostics
                    vim.diagnostic.set(ns, bufnr, diagnostics, {virtual_text = false})
                end
            end

            -- Skip trying to run the tests if a matching command can't be found
            local command = utils.find_matching_command(config.jest_commands, root_dir)
            if not command then return end

            command = command .. " --watchAll=false --reporters --json --testLocationInResults "
                          .. bufnm

            local stop_loader = loader.start();

            vim.fn.jobstart(command, {
                cwd = root_dir,
                stdout_buffered = true,
                on_stdout = append_data,
                on_stderr = append_data,
                on_exit = stop_loader
            })
        end
    })

    -- Create a one time user command to stop the process
    vim.api.nvim_create_user_command("JestStop", function()
        -- Clear plugin display information
        local bufnr = vim.api.nvim_get_current_buf()
        vim.diagnostic.reset(ns, bufnr)
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

        -- Remove the autocmd and user command
        vim.api.nvim_del_autocmd(autocmd_nr)
        vim.api.nvim_del_user_command("JestStop")
    end, {})
end

M.setup = function(config)
    local base_config = {
        init_type = "autocmd",
        pattern = {"**/__tests__/**.{js,jsx,ts,tsx}", "*.spec.{js,jsx,ts,tsx}",
                   "*.test.{js,jsx,ts,tsx}"},
        root_markers = {".git", "package.json"},
        jest_commands = {{".*", "./node_modules/jest/bin/jest.js"}}
    }

    local merged_config = vim.tbl_deep_extend("force", base_config, config)

    -- Verify config is valid
    vim.validate({
        init_type = {merged_config.init_type, function(arg)
            return arg == "autocmd" or arg == "startup"
        end, "autocmd or startup"},
        pattern = {merged_config.pattern, "table"},
        root_markers = {merged_config.root_markers, "table"},
        jest_commands = {merged_config.jest_commands, "table"}
    })

    if merged_config.init_type == "startup" then create_jest_run_autocmd(merged_config) end
    if merged_config.init_type == "autocmd" then
        vim.api.nvim_create_user_command("JestStart", function()
            create_jest_run_autocmd(merged_config)
        end, {})
    end
end

return M
