<div align="center">

# jest.nvim

###### Run your jest tests and get results from the comfort of neovim

</div>

## Note

This plugin is pretty rough. It's a WIP and was put together quickly to solve a problem I had. If you run into problems, feel free to open an issue.

## The Problem

You can run jest in watch mode in a second terminal. Any time you save a file, jest re-runs the tests and you can see the results. Nothing wrong with that. I just wanted faster results when I ran my jest tests.

## The Solution

This plugin executes jest when you write a test file.

It passes the current file as an argument to jest so only that file is run. Once jest has finished, the results are reported next to the relevant test. If there are any errors, additional diagnostic information is provided for the failed test.

This lets you run jest without having to worry about using another tool (terminal).

That's all it does.

Nothing more. Nothing less (hopefully).

## Installation

- A nightly neovim build is required because this plugin makes use of the `vim.fs` api.
- Install using your favorite plugin manager:

```vim
Plug TheSSHGuy/jest.nvim
```

## Configuration

### `init_type`

- `autocmd` - this tells neovim to create the user command `JestStart`. Running the user command will create an autocmd that executes jest on file save.
- `startup` - this skips the user command and sets up the autocmd when neovim starts.

**Note:** When the autocmd is created a one time user command `JestStop` is created to clear any existing diagnostic information and stop the process.

### `pattern`

This is the pattern that is used for the autocmd. It's an array of strings that represent filename patterns that should run the autocmd.

It's set to the following by default:

```lua
-- Set to common jest test filename patterns
local pattern = {
  "**/__tests__/**.{js,jsx,ts,tsx}",
  "*.spec.{js,jsx,ts,tsx}",
  "*.test.{js,jsx,ts,tsx}"
}
```

### `root_markers`

`jest.nvim` executes the test command from the root directory of your project. This allows you to pass commands like: `./node_modules/jest/bin/jest.js`.

It's set to the following by default:

```lua
-- Set to common JS project root directory files
local root_markers = {".git", "package.json"}
```

### `jest_commands`

This is an array of `{path_regex, jest_command}` tuples that `jest.nvim` uses to determine which command should be run. This lets you have different commands for different folders.

For example, I might want to target `./node_modules/jest/bin/jest.js` for one project, but `npm t --` for another project. This can be useful for projects which don't allow you to run jest directly (like Create React App where you have to run `react-scripts test` because it uses an internal jest config).

`jest.nvim` loops through this array until a match is found which means patterns that are higher in the list have a higher priority. If you want a catch-all command to be run so you don't have to set things up per project, you can pass `".*"` as the `path_regex` which should catch all paths.

It's set to the following by default:

```lua
-- Set to a catch-all `path_regex` that runs jest from `node_modules`
local jest_commands = {{".*", "./node_modules/jest/bin/jest.js"}}
```

## Usage

```lua
require("jest").setup({
    init_type = "startup",
    jest_commands = {{"~/code/proj", "npm t --"}, {".*", "./node_modules/jest/bin/jest.js"}}
})
```

## Other

You can find out more information about [how this was built](https://blog.thesshguy.com/jest-nvim-a-neovim-plugin) here.
