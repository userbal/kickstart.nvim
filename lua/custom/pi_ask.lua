local M = {}

local active_process
local chat_bufnr
local chat_winnr
local session_path
local start_fresh_on_next_ask = false

local function get_session_path()
  if session_path then
    return session_path
  end

  local dir = vim.fn.stdpath('state') .. '/pi-ask'
  vim.fn.mkdir(dir, 'p')
  session_path = dir .. '/' .. vim.fn.sha256(vim.fn.getcwd()) .. '.jsonl'
  return session_path
end

local function get_visual_context(bufnr)
  local anchor = vim.fn.getpos('v')
  local cursor = vim.fn.getpos('.')
  local mode = vim.fn.mode(1)
  local region = vim.fn.getregion(anchor, cursor, { type = mode })
  local start_line = math.min(anchor[2], cursor[2])
  local end_line = math.max(anchor[2], cursor[2])
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  local context_start = math.max(1, start_line - 12)
  local context_end = math.min(total_lines, end_line + 12)
  local context = vim.api.nvim_buf_get_lines(bufnr, context_start - 1, context_end, false)

  return {
    file = vim.api.nvim_buf_get_name(bufnr),
    filetype = vim.bo[bufnr].filetype,
    range = string.format('%d-%d', start_line, end_line),
    selection = table.concat(region, '\n'),
    context = table.concat(context, '\n'),
    context_range = string.format('%d-%d', context_start, context_end),
  }
end

local function get_buffer_context(bufnr)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  local start_line = math.max(1, cursor_line - 40)
  local end_line = math.min(total_lines, cursor_line + 40)
  local context = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

  return {
    file = vim.api.nvim_buf_get_name(bufnr),
    filetype = vim.bo[bufnr].filetype,
    context = table.concat(context, '\n'),
    context_range = string.format('%d-%d', start_line, end_line),
  }
end

local function build_prompt(question, context)
  local code_fence = '```' .. (context.filetype or '')
  local parts = {
    'Answer the question about this code. Do not modify any files. Treat the supplied Neovim code as authoritative if it differs from disk.',
  }

  if context.file and context.file ~= '' then
    table.insert(parts, 'File: ' .. context.file)
  end

  if context.selection then
    table.insert(parts, 'Selected lines: ' .. context.range)
    table.insert(parts, 'Selected code:\n' .. code_fence .. '\n' .. context.selection .. '\n```')
  end

  if context.context and context.context ~= '' then
    table.insert(parts, 'Nearby code (lines ' .. context.context_range .. '):\n' .. code_fence .. '\n' .. context.context .. '\n```')
  end

  table.insert(parts, 'Question: ' .. question)
  return table.concat(parts, '\n\n')
end

local function clear_conversation()
  local path = get_session_path()
  if vim.fn.filereadable(path) == 1 then
    vim.fn.delete(path)
  end
  if chat_bufnr and vim.api.nvim_buf_is_valid(chat_bufnr) then
    vim.bo[chat_bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(chat_bufnr, 0, -1, false, { '# pi Q&A', '' })
    vim.bo[chat_bufnr].modifiable = false
  end
end

local function ensure_chat_split()
  if chat_bufnr and not vim.api.nvim_buf_is_valid(chat_bufnr) then
    chat_bufnr = nil
    chat_winnr = nil
  end

  if not chat_bufnr then
    chat_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(chat_bufnr, 'pi-ask://' .. vim.fn.sha256(vim.fn.getcwd()):sub(1, 12))
    vim.bo[chat_bufnr].buftype = 'nofile'
    vim.bo[chat_bufnr].bufhidden = 'hide'
    vim.bo[chat_bufnr].swapfile = false
    vim.bo[chat_bufnr].filetype = 'markdown'
    vim.api.nvim_buf_set_lines(chat_bufnr, 0, -1, false, { '# pi Q&A', '' })
    vim.bo[chat_bufnr].modifiable = false

    vim.keymap.set('n', '<CR>', M.ask_followup, { buffer = chat_bufnr, desc = 'Reply to pi' })
    vim.keymap.set('n', '<leader>aa', M.ask_followup, { buffer = chat_bufnr, desc = 'Reply to pi' })
    vim.keymap.set('n', 'q', function()
      start_fresh_on_next_ask = true
      if chat_winnr and vim.api.nvim_win_is_valid(chat_winnr) then
        vim.api.nvim_win_close(chat_winnr, true)
      end
      chat_winnr = nil
    end, { buffer = chat_bufnr, desc = 'Close pi conversation' })
  end

  if not chat_winnr or not vim.api.nvim_win_is_valid(chat_winnr) then
    vim.cmd 'botright split'
    chat_winnr = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(chat_winnr, chat_bufnr)
    vim.cmd('resize ' .. math.max(10, math.min(30, math.floor(vim.o.lines * 0.45))))
  else
    vim.api.nvim_set_current_win(chat_winnr)
  end
  vim.wo[chat_winnr].wrap = true
  vim.wo[chat_winnr].linebreak = true
  vim.wo[chat_winnr].breakindent = true
  vim.wo[chat_winnr].number = false
  vim.wo[chat_winnr].relativenumber = false
  vim.wo[chat_winnr].signcolumn = 'no'
  vim.wo[chat_winnr].conceallevel = 2
  vim.wo[chat_winnr].concealcursor = 'nc'
end

local function append_lines(lines)
  vim.bo[chat_bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(chat_bufnr, -1, -1, false, lines)
  vim.bo[chat_bufnr].modifiable = false
  vim.api.nvim_win_set_cursor(chat_winnr, { vim.api.nvim_buf_line_count(chat_bufnr), 0 })
end

local function replace_lines(start_row, end_row, lines)
  vim.bo[chat_bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(chat_bufnr, start_row, end_row, false, lines)
  vim.bo[chat_bufnr].modifiable = false
  if chat_winnr and vim.api.nvim_win_is_valid(chat_winnr) then
    vim.api.nvim_win_set_cursor(chat_winnr, { vim.api.nvim_buf_line_count(chat_bufnr), 0 })
  end
end

local function add_turn(question, context)
  ensure_chat_split()

  local heading = { '## You', '' }
  if context and context.file and context.file ~= '' then
    table.insert(heading, 'Context: `' .. context.file .. '`')
  end
  if context and context.range then
    table.insert(heading, 'Selected lines: ' .. context.range)
  end
  table.insert(heading, question)
  table.insert(heading, '')
  append_lines(heading)

  local response_row = vim.api.nvim_buf_line_count(chat_bufnr)
  append_lines({ '## pi', '', '_Thinking…_', '' })
  return response_row + 2
end

local function ask(question, context)
  if active_process then
    vim.notify('A pi question is already running', vim.log.levels.WARN)
    return
  end

  if start_fresh_on_next_ask then
    clear_conversation()
    start_fresh_on_next_ask = false
  end

  local prompt = build_prompt(question, context or {})
  local response_row = add_turn(question, context)
  local ok, process = pcall(vim.system, {
    'pi',
    '--print',
    '--session',
    get_session_path(),
    '--tools',
    'read',
    '--no-mcp',
    '--no-extensions',
    '--no-skills',
    '--',
    prompt,
  }, { text = true }, function(result)
    active_process = nil
    vim.schedule(function()
      if result.code ~= 0 then
        local details = vim.trim(result.stderr or '')
        if details == '' then
          details = 'pi exited with code ' .. result.code
        end
        replace_lines(response_row, response_row + 1, { '**pi error:** ' .. details })
        return
      end

      local answer = vim.trim(result.stdout or '')
      if answer == '' then
        answer = 'pi returned an empty response.'
      end
      replace_lines(response_row, response_row + 1, vim.split(answer, '\n', { plain = true }))
    end)
  end)

  if not ok then
    active_process = nil
    replace_lines(response_row, response_row + 1, { '**pi error:** ' .. tostring(process) })
    return
  end
  active_process = process
end

local function prompt_for_question(context)
  vim.ui.input({ prompt = 'Ask pi: ' }, function(question)
    if question and vim.trim(question) ~= '' then
      ask(question, context)
    end
  end)
end

function M.ask_selection()
  local bufnr = vim.api.nvim_get_current_buf()
  prompt_for_question(get_visual_context(bufnr))
end

function M.ask_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  prompt_for_question(get_buffer_context(bufnr))
end

function M.ask_followup()
  prompt_for_question(nil)
end

function M.new_conversation()
  if active_process then
    vim.notify('Wait for the current pi response before starting a new conversation', vim.log.levels.WARN)
    return
  end

  clear_conversation()
  start_fresh_on_next_ask = false
  vim.notify('Started a new pi conversation')
end

function M.setup()
  vim.keymap.set('n', '<leader>aa', M.ask_buffer, { desc = 'Ask pi about code near cursor' })
  vim.keymap.set('x', '<leader>aa', M.ask_selection, { desc = 'Ask pi about visual selection' })
  vim.keymap.set('n', '<leader>an', M.new_conversation, { desc = 'Start a new pi conversation' })
  vim.api.nvim_create_user_command('PiAskNew', M.new_conversation, { desc = 'Start a new pi conversation' })
end

return M
