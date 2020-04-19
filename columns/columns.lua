function manage_columns (div)
    if FORMAT:match 'latex' then
        if div.classes[1] == 'columns' then
            local out = {}
            table.insert(out, pandoc.RawBlock('latex', '\\begin{multicols}{' .. #div.content .. '}\n'))
            for id, column in pairs(div.content) do
                for _, inline in pairs(column.content) do
                    table.insert(out, inline)
                end
                if id ~= #div.content then
                    table.insert(out, pandoc.RawBlock('latex', '\\columnbreak\n'))
                end
            end
            table.insert(out, pandoc.RawBlock('latex', '\\end{multicols}\n'))

            print('columns: ' .. #div.content .. ' columns have been processed')
            return out
        end
    end
end

return {
    { Div = manage_columns }
}