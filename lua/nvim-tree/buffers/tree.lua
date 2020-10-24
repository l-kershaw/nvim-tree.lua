local a = vim.api

local M = {}

M.config = {
  name = "NvimTree",
  filetype = "NvimTree"
}

local function is_open()
  return vim.fn.bufwinnr(M.config.name) ~= -1
end

local function bind(buf, left, right, opts)
  a.nvim_buf_set_keymap(buf, "n", left, right, opts or { silent = true })
end

function M.open()
  if is_open() then return end

  local side = M.config.side == 'left' and 'topleft' or 'botright'
  vim.cmd(string.format("%s %svsplit", side, M.config.width))

  local win = a.nvim_get_current_win()
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false

  local bufnr
  if vim.fn.bufexists(M.config.name) ~= 0 then
    bufnr = vim.fn.bufnr(M.config.name)
  else
    bufnr = a.nvim_create_buf(false, true)
    a.nvim_buf_set_name(bufnr, M.config.name)
    vim.bo[bufnr].filetype = M.config.filetype
    vim.bo[bufnr].modifiable = false
    vim.bo[bufnr].swapfile = false
  end

  for left, right in pairs(M.config.keybindings) do
    bind(bufnr, left, right)
  end

  a.nvim_win_set_buf(win, bufnr)
end

function M.close()
  if not is_open() then return end
  if #a.nvim_list_wins() == 1 then
    vim.cmd "q!"
  else
    a.nvim_win_close(vim.fn.bufwinid(M.config.name), true)
  end
end

local ns_id = a.nvim_create_namespace(M.config.name)

function M.render(lines, highlights)
  if not is_open() then return end

  local bufnr = vim.fn.bufnr(M.config.name)
  vim.bo[bufnr].modifiable = true

  a.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  a.nvim_buf_clear_namespace(bufnr, ns_id)
  for _, hl in ipairs(highlights) do
    a.nvim_buf_set_extmark(bufnr, ns_id, hl.line, hl.col, {
        end_line = hl.line,
        end_col = hl.end_col,
        hl_group = hl.group
      })
  end

  vim.bo[bufnr].modifiable = false
end

function M.configure(opts)
  M.config = vim.tbl_extend("keep", opts, M.config)

  if opts.auto_close then
    vim.cmd "au! WinClosed * lua vim.defer_fn(require'nvim-tree'.close, 1)"
  end
end

return M
