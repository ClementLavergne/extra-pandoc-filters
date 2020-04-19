-- Requires package 'pdflscape'
function landscape (div)
    if div.classes[1] == 'landscape' then
        if FORMAT:match 'latex' then
            local out = {}

            table.insert(out, pandoc.RawBlock('latex', '\\begin{landscape}\n'))
            for _, content in pairs(div.content) do
                table.insert(out, content)
            end
            table.insert(out, pandoc.RawBlock('latex', '\\end{landscape}\n'))

            print('landscape: content processed')
            return out
        else
            return div.content
        end
    end
end

return {
    { Div = landscape }
}