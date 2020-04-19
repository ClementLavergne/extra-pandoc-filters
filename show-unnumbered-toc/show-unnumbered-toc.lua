function manage_phantom_section (header)
    if FORMAT:match 'latex' then
        if header.classes[1] == 'unnumbered' then
            print('show-unnumbered-toc: "' .. pandoc.utils.stringify(header.content) .. '" is now visible')
            return {
                pandoc.RawBlock('latex', '\\phantomsection'),
                header
            }
        end
    end
end

return {
    { Header = manage_phantom_section }
}