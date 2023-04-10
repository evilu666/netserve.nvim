

# Prevents the plugin from being loaded multiple times. If the loaded
# variable exists, do nothing more. Otherwise, assign the loaded
# variable and continue running this instance of the plugin.

if vim.g.loaded_netserve then
    return
end

vim.g.loaded_netserve = 1

local base_options = {
	max_length = 50
  cmd = "netserve-client"
}

local options = setmetatable({}, base_options)

function set_options(opt)
    options = setmetatable(opt, base_options)
end

function choose_model()
    models = vim.fn.systemlist(options.cmd .. " model list --names-only")
    if #models then
        model_select = {}
        for i, model in ipairs(models) do
            model_select[i] = i + ": " + model

        selected = vim.fn.inputlist(model_select)
        vim.b.netserve_model = models[selected]
    end
end

function generate_text(source_text)
    if not vim.b.netserve_model then
        print("No model selected for current buffer")
        return false
    end

    print("Generating...")
    text = vim.fn.systemlist(options.cmd .. " generate -i " .. vim.b.netserve_model, source_text)
    return text
end

vim.api.nvim_create_user_command("NetserveModel", function(opts)
    choose_model()
end)

vim.api.nvim_create_user_command("NetserveGenerate", function(opt)
    first = opt.line1
    last = opt.line2

    text = vim.fn.region(vim.b.bufnr, {first, 0}, {last+1, 0}, "", false)
    generated_text = generate_text(text)

    if generated_text then
        for i, line in ipairs(generated_text) do
            linenum = first + (i - 1)
            if linenum <= last then
                vim.fn.setbufline(vim.b.bufnr, linenum, line)
            else
                vim.fn.appendbufline(vim.b.bufnr, linenum, line)
            end
        end
    end
end)
