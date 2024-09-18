-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.api.nvim_command("autocmd BufEnter * highlight ExtraWhitespace guibg=red")

local function toggle_whitespace_match(mode)
  -- Only show whitespace that is after the cursor to avoid
  -- annoying highlights as you type
  local pattern = (mode == "i") and [[\s\+\%#\@<!$]] or [[\s\+$]]
  if vim.w.whitespace_match_number then
    vim.fn.matchdelete(vim.w.whitespace_match_number)
    vim.w.whitespace_match_number = vim.fn.matchadd("ExtraWhitespace", pattern)
  else
    -- Something went wrong, try to be graceful.
    vim.w.whitespace_match_number = vim.fn.matchadd("ExtraWhitespace", pattern)
  end
end

vim.api.nvim_create_augroup("WhitespaceMatch", {
  clear = true,
})
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = "WhitespaceMatch",
  callback = function()
    vim.w.whitespace_match_number = vim.fn.matchadd("ExtraWhitespace", [[\s\+$]])
  end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  group = "WhitespaceMatch",
  callback = function()
    toggle_whitespace_match("i")
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  group = "WhitespaceMatch",
  callback = function()
    toggle_whitespace_match("n")
  end,
})
-- Press <F6> to trim trailing whitespace
vim.api.nvim_set_keymap(
  "n",
  "<F6>",
  [[:let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>]],
  { noremap = true, silent = true }
)

vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function()
    vim.fn.matchadd(
      "BadCharactersHighlight",
      [==[[\x0b\x0c\u00a0\u1680\u180e\u2000-\u200a\u2028\u202f\u205f\u3000\ufeff]]==]
    )
  end,
})
vim.api.nvim_set_hl(0, "BadCharactersHighlight", { ctermbg = "red", bg = "#f92672" })

vim.api.nvim_create_augroup("FixBrokenLspForGoConditionalBuildFiles", { clear = true })
vim.api.nvim_create_autocmd("BufReadPre", {
  group = "FixBrokenLspForGoConditionalBuildFiles",
  pattern = "*.go",
  callback = function()
    local filepath = vim.fn.expand("<afile>")
    -- Can't use `vim.api.nvim_buf_get_lines(0, 0, 10, false)` because it's empty during BufReadPre
    local handle = io.popen("head -n 10 " .. filepath)
    local result = handle:read("*a")
    handle:close()

    local build_tag_pattern = "^//%s*go:build%s([%w_*]+)"
    for line in result:gmatch("[^\r\n]+") do
      local flag = string.match(line, build_tag_pattern)
      if flag then
        print(flag)
        vim.fn.setenv("GOFLAGS", "-tags=" .. flag)
        break
      end
    end
  end,
})
