local secnumdepth   = 0
local tocdepth      = 0

-- Extract metadata
function extract_metadata (meta)
    for k, v in pairs(meta) do
        if k == 'secnumdepth' then
            secnumdepth = table.unpack(v).text
        elseif k == 'toc-depth' then
            tocdepth = table.unpack(v).text
        end
    end
end

-- Replace macros by expected content
function process_macro (div)
    if div.classes[1] == 'separator' then
        if FORMAT:match 'latex' then
            print('preamble-separator: content added (secnumdepth=' .. secnumdepth .. ', tocdepth=' .. tocdepth .. ')')
            return pandoc.Plain {
                pandoc.RawInline('latex', string.format('\\setcounter{secnumdepth}{%d}\n', secnumdepth)),
                pandoc.RawInline('latex', string.format('\\setcounter{tocdepth}{%d}\n', tocdepth)),
                pandoc.RawInline('latex', '\\tableofcontents\n'),
                pandoc.RawInline('latex', '\\listoftables\n'),
                pandoc.RawInline('latex', '\\listoffigures\n')
            }
        else
            return {}
        end
    end
end

return {
    { Meta = extract_metadata },
    { Div = process_macro }
}