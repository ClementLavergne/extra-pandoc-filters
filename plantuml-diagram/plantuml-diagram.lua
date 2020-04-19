function process_plantuml_code (block)
    local function extract_plantuml_info(text)
        -- Extract caption
        caption = text:match('caption%s+(%w.-)[\r\n]')
        -- Extract scale
        scale = text:match('scale%s+(%d.-)[\r\n]')
        -- Remove caption
        code = text:gsub('(caption.-[\r\n])', '')

        return {caption = caption, scale = scale, code = code}
    end

    local function String_to_List(string)
        local inline  = {}
        local split   = {}
        local count   = 0

        -- Split the string by space delimiter
        for item in string:gmatch("%S+") do
            table.insert(split, item)
            count = count + 1
        end
        -- Build the inline
        for k, v in pairs(split) do
            table.insert(inline, pandoc.Str(v))

            if k < count then
                table.insert(inline, pandoc.Space())
            end
        end
        return inline
    end

    if block.classes[1] == 'plantuml' then
        local filetype = {
            latex = 'eps',
            html = 'svg',
            docx = 'eps'
        }

        if filetype[FORMAT] ~= nil then
            local javaPath = os.getenv('JAVA_HOME')
            local plantumlPath = os.getenv('PLANTUML')
            local ready = true

            if javaPath == nil then
                ready = false
                print('plantuml-diagram: missing JAVA_HOME environment variable')
            end
            if plantumlPath == nil then
                ready = false
                print('plantuml-diagram: missing PLANTUML environment variable')
            end

            if ready then
                -- Extract information from code
                local info = extract_plantuml_info(block.text)
                local caption_inlines = {}
                if info.caption ~= nil then
                    caption_inlines = String_to_List(info.caption)
                end
                -- Compute the output file name
                local out_folder = string.format('%s/%s/%s/', os.getenv('OUT_PATH'), os.getenv('TMP_DIR'), os.getenv('SRC_NAME'))
                local filename = pandoc.sha1(info.code)
                local in_filepath = out_folder .. filename ..'.uml'
                local out_filepath = out_folder .. filename ..'.' .. filetype[FORMAT]

                -- Check if out file already exists
                local out_file = io.open(out_filepath, 'r')
                local generate = out_file == nil

                -- Generate image
                if generate then
                    -- Extract the code
                    in_file = io.open(in_filepath, 'w')
                    for line in info.code:gmatch("[^\r\n]+") do
                        in_file:write(line .. '\r\n')
                    end
                    in_file:close()

                    -- Execute plantuml.jar
                    os.execute(string.format(
                        '%s -jar %s -t%s -charset UTF8 %s',
                        os.getenv('JAVA_HOME'),
                        os.getenv('PLANTUML'),
                        filetype[FORMAT],
                        in_filepath
                    ))

                    if info.caption ~= nil then
                        print(string.format('plantuml-diagram: figure "%s" has been generated! (%s)', info.caption, filename))
                    else
                        print(string.format('plantuml-diagram: figure without caption has been generated! (%s)', filename))
                    end
                else
                    out_file:close()
                end

                local image = pandoc.Image(caption_inlines, out_filepath, 'fig:')
                if info.scale ~= nil and FORMAT:match 'latex' then
                    image.attributes.width = string.format('%d', tonumber(info.scale) * 100) .. '%'
                end

                return pandoc.Para { image }
            end
        else
            print(string.format('plantuml-diagram: generation discarded for \'%s\' output', FORMAT))
            return {}
        end
    end
end

return {
    { CodeBlock = process_plantuml_code }
}