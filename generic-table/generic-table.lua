local auto_generated_table  = {}
local keyword_data          = {}

-- Sort a map alphabetically
local function pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
        table.sort(a, f)
        -- iterator variable
        local i = 0
        -- iterator function
        local iter = function ()
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

-- Extract arguments from BulletList
local function extract_table_args (bulletlist)
    local meta_name     = ''
    local meta_caption  = ''
    local tmp
    for _, arg in pairs(bulletlist.content) do
        local str = pandoc.utils.stringify(arg)
        tmp = str:match('meta: %s-(.+)')
        if tmp ~= nil then
            meta_name = tmp
        else
            tmp = str:match('caption: %s-(.+)')
            if tmp ~= nil then
                meta_caption = tmp
            end
        end
    end

    return meta_name, meta_caption
end

-- Initialize the global variable for auto-generated tables
function fetch_auto_generated_table (div)
    if div.classes[1] == 'table' then
        local name, caption = extract_table_args(div.content[1])

        -- Update global variable
        if name ~= '' and caption ~= '' then
            auto_generated_table[name] = { data = nil, caption = caption, owns_keywords = false }
        end
    end
end

-- Process metadata and initialize keywords data
function extract_auto_generated_table_data_and_init_keywords (meta)
    local function generate_keywords (table_name, table_data)
        -- get Inlines as a lua list
        local function PandocInlines_to_List(inlines)
            local out = {}
            for _, inline in pairs(inlines) do
                table.insert(out, inline)
            end
            return out
        end

        for _, row in pairs(table_data.rows) do
            local link_object = pandoc.Link (
                PandocInlines_to_List(row.keyword),
                '#' .. table_name,
                pandoc.utils.stringify(row.description)
            )
            -- Add link to map of pairs and reset counters to 0
            keyword_data[pandoc.utils.stringify(row.keyword)] = { table = table_name, link = link_object, detected = 0, created = 0 }
        end
    end

    -- Walk each table
    for name, args in pairs(auto_generated_table) do
        -- Check if corresponding meta exists
        if meta[name] ~= nil then
            -- Store content to corresponding table
            auto_generated_table[name].data = meta[name]

            -- Generate keywords if table is keyword-compatible
            local keyword_column        = false
            local description_column    = false
            for _, column in pairs(meta[name].layout) do
                local str = pandoc.utils.stringify(column.id)
                if str == 'keyword' then keyword_column = true end
                if str == 'description' then description_column = true end
            end
            if keyword_column == true and description_column == true then
                auto_generated_table[name].owns_keywords = true
                generate_keywords(name, meta[name])
            end
        else
            print('generic-table: error with table \'' .. name .. '\'')
        end
    end

    -- -- Debug
    -- print('Existing links:')
    -- for key, content in pairsByKeys(keyword_data) do
    --     print(string.format('%15s | %20s: %3d/%3d -> %s', content.link.target, key, content.created, content.detected, content.link.title))
    -- end
end

-- Keyword detection and block replacement
function detect_keywords_and_add_links (block)
    local content_string
    local tag = block.tag

    local function insert_keywords (inlines, match_list)
        local function filter_keywords()
            local out = {}

            -- print('Unfiltered matches:')
            local last_start    = 1
            local last_end      = 1
            local filtered_list = {}
            for current_start, match in pairsByKeys(match_list) do
                local kept_index    = 1
                local keep          = true

                if current_start < last_end then
                    -- Case 2: Keyword in the middle of another one
                    keep = false
                end

                for index, value in pairs(match) do
                    -- print(string.format('- %s (start: %d, end: %d)', value.keyword, current_start, value.end_pos))

                    -- Case 1: Starting from the same point, keep the longest keyword
                    if value.end_pos > last_end then
                        last_end    = value.end_pos
                        kept_index  = index
                    end
                end

                if keep == true then
                    filtered_list[current_start] = match[kept_index]
                end

                last_start = current_start
            end

            -- print('Filtered matches:')
            for start, value in pairsByKeys(filtered_list) do
                -- print(string.format('- %s (start: %d, end: %d)', value.keyword, start, value.end_pos))
                -- Store keyword in a list
                table.insert(out, value)
                -- Increment keyword detection
                keyword_data[value.keyword].detected = keyword_data[value.keyword].detected + 1
            end

            return out
        end

        local function update_inlines(filtered_keywords)
            local function find_string_and_replace(expected_string, inlines)
                local function generate_inlines(input_string)
                    local new_inlines   = {}

                    -- Global match
                    if string.match(input_string, expected_string) ~= nil then
                        if input_string ~= expected_string then
                            local before_str = input_string:gsub('[' .. expected_string .. '].*', '', 1)
                            local after_str = input_string:gsub('^.[' .. expected_string .. ']+', '', 1)
                            -- print(string.format('Before: %s', before_str))
                            -- print(string.format('After:  %s', after_str))

                            -- Bug fix: Make sure that detected keyword is not part of a string
                            if  before_str:match('%w+') == nil and after_str ~= input_string then
                                -- Str
                                if before_str ~= '' then
                                    table.insert(new_inlines, pandoc.Str(before_str))
                                end
                                -- Link
                                table.insert(new_inlines, keyword_data[expected_string].link)
                                -- Str
                                if after_str ~= '' then
                                    table.insert(new_inlines, pandoc.Str(after_str))
                                end

                                -- Increment keyword creation
                                keyword_data[expected_string].created = keyword_data[expected_string].created + 1
                            else
                                -- Decrement keyword detection
                                keyword_data[expected_string].detected = keyword_data[expected_string].detected - 1
                                -- print('Bad keyword detection fixed!')
                            end
                        else
                            -- Link
                            table.insert(new_inlines, keyword_data[expected_string].link)
                            -- Increment keyword creation
                            keyword_data[expected_string].created = keyword_data[expected_string].created + 1
                        end
                    end

                    return new_inlines
                end

                -- Initialization
                local out_inlines   = {}
                local recorded      = {}
                local found         = false
                local record        = false
                local counter       = 0
                local splitted_str = {}
                for str in expected_string:gmatch('[^%s]+') do
                    table.insert(splitted_str, str)
                    counter = counter + 1
                end
                local first_str = splitted_str[1]
                local last_str  = splitted_str[counter]

                for _, inline in pairs(inlines) do
                    local inline_tag = inline.tag

                    if found == false then
                        -- Content: String
                        if inline_tag == 'Str' then
                            -- Initialize the recording
                            if record == false then
                                if inline.text:match(first_str) ~= nil then
                                    record = true
                                    -- print('-- Start recording --')
                                end
                            end

                            -- print(string.format('- %10s: %s', inline_tag, inline.text))

                            -- Recording until reaching last Str of current keyword
                            if record == true then
                                table.insert(recorded, inline)
                                if inline.text:match(last_str) ~= nil then
                                    record = false
                                    -- print('-- Stop recording --')

                                    -- Process recorded inlines
                                    local tmp = generate_inlines(pandoc.utils.stringify(recorded))
                                    if next(tmp) ~= nil then
                                        for _, generated_inline in pairs(tmp) do
                                            table.insert(out_inlines, generated_inline)
                                        end

                                        found = true
                                    end
                                end
                            end

                        -- Discard
                        else
                            -- Record if necessary
                            if record == true then
                                table.insert(recorded, inline)
                            end

                            -- print(string.format('- %10s', inline_tag))
                        end

                        -- Keep inline as is if necessary
                        if found == false and record == false then
                            table.insert(out_inlines, inline)
                        end

                    -- Keyword already replaced in current inlines
                    else
                        table.insert(out_inlines, inline)
                    end
                end

                return out_inlines
            end

            -- Initialization
            local out = inlines
            for _, filtered_keyword in pairs(filtered_keywords) do
                -- print(string.format('Keyword \'%s\':', filtered_keyword.keyword))
                out = find_string_and_replace(filtered_keyword.keyword, out)
            end
            -- print('...')

            return out
        end

        -- print('---')
        -- print(string.format('%s: %s', tag, content_string))

        -- Insert links to expected place
        return update_inlines(filter_keywords())
    end

    -- Content: List of Inlines
    if tag == 'Para' or tag == 'Plain' or tag == 'LineBlock' then
        content_string = pandoc.utils.stringify(block.content)

        local detected_matches = {}
        for key, tuple in pairs(keyword_data) do
            local search    = true
            local start_pos = nil
            local end_pos   = 1
            -- Get each occurence of a keyword within this block
            while search == true do
                -- Limitation: Exact match + 0 or n characters
                start_pos, end_pos = string.find(content_string, key .. '.-', end_pos)
                if start_pos == nil then
                    search = false
                elseif start_pos == 1 and end_pos == 1 then
                    search = false
                else
                    if detected_matches[start_pos] == nil then
                        detected_matches[start_pos] = {}
                    end
                    table.insert(detected_matches[start_pos], {
                        keyword = key,
                        end_pos = end_pos
                    })
                end
            end
        end

        -- Update the current block
        if next(detected_matches) ~= nil then
            block.content = insert_keywords(block.content, detected_matches)
        end
    else
        -- print(string.format('Discarded %s', tag))
    end

    return block
end

-- Auto generate corresponding tables
function instantiate_auto_generated_table (div)
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

    -- Extract all inlines as list
    local function PandocInlines_to_Cell(list)
        local out = {}
        if list.tag == 'MetaInlines' then
            for _, inline in pairs(list) do
                table.insert(out, inline)
            end
            return {pandoc.Plain(out)}

        elseif list.tag == 'MetaBlocks' then
            for _, block in pairs(list) do
                table.insert(out, block)
            end
            return out
        else
            -- print(list.tag)
        end
    end

    -- Extraction of alignment data
    local function get_aligns(columns)
        local out = {}
        for _, column in pairs(columns) do
            local alignment = table.unpack(column.align).text
            if alignment == 'AlignDefault' then
                table.insert(out, pandoc.AlignDefault)
            elseif alignment == 'AlignCenter' then
                table.insert(out, pandoc.AlignCenter)
            elseif alignment == 'AlignLeft' then
                table.insert(out, pandoc.AlignLeft)
            elseif alignment == 'AlignRight' then
                table.insert(out, pandoc.AlignRight)
            end
        end

        return out
    end

    -- Extraction of widths data
    local function get_widths(columns)
        local out = {}
        for _, column in pairs(columns) do
            table.insert(out, tonumber(table.unpack(column.width).text))
        end

        return out
    end

    -- Extraction of headers data
    local function get_headers(columns)
        local out = {}
        for _, column in pairs(columns) do
            table.insert(out, PandocInlines_to_Cell(column.header))
        end

        return out
    end

    -- Extraction of rows data
    local function get_rows(table_name)
        local out        = {}
        local ids        = {}
        local table_data = auto_generated_table[table_name].data

        -- Create ids map to respect column sequence
        for k, column in pairs(table_data.layout) do
            ids[k] = table.unpack(column.id).text
        end

        -- Get rows
        if auto_generated_table[table_name].owns_keywords == true then
            -- Sort keywords alphabetically
            for key, item in pairsByKeys(keyword_data) do
                if item.table == table_name and item.created ~= 0 then
                    for _, row in pairs(table_data.rows) do
                        if pandoc.utils.stringify(row.keyword) == key then
                            -- Generate table cell for current row
                            local cells = {}
                            for k, id in pairs(ids) do
                                table.insert(cells, PandocInlines_to_Cell(row[id]))
                            end
                            table.insert(out, cells)
                            -- print(string.format('%15s | %20s: %3d/%3d -> %s', item.link.target, key, item.created, item.detected, item.link.title))
                            break
                        end
                    end
                end
            end
        else
            for _, row in pairs(table_data.rows) do
                -- Generate table cell for current row
                local cells = {}
                for k, id in pairs(ids) do
                    table.insert(cells, PandocInlines_to_Cell(row[id]))
                end
                table.insert(out, cells)
            end
        end

        return out
    end

    if div.classes[1] == 'table' then
        -- Extract table arguments
        local name, caption = extract_table_args(div.content[1])
        if auto_generated_table[name] ~= nil then
            local table_data = auto_generated_table[name].data
            if table_data ~= nil then
                local content = {}
                -- Extract rows
                local rows = get_rows(name)
                -- Build table if not empty
                if next(rows) ~= nil then
                    table.insert(content,
                    pandoc.Table(
                        String_to_List(caption),
                        get_aligns(table_data.layout),
                        get_widths(table_data.layout),
                        get_headers(table_data.layout),
                        rows
                    ))

                    return pandoc.Div(content, pandoc.Attr(name,{},{}))
                else
                    print('generic-table: no keyword used from table \'' .. name .. '\'')
                    return {}
                end
            else
                print('generic-table: table \'' .. name .. '\' is not correctly initialized')
                return {}
            end
        else
            print('generic-table: table \'' .. name .. '\' does not exists')
            return {}
        end
    end
end

-- For PDF output only, enable tip box when hoovering a keyword
function add_pdf_popup_to_each_keyword_link (el)
    if FORMAT:match 'latex' then
        local target    = string.gsub(el.target, '%#', '')
        local content   = string.gsub(pandoc.utils.stringify(el.content), '%_', '\\textunderscore ')
        local desc      = string.gsub(el.title, '%_', '\\textunderscore ')

        if desc ~= '' then
            return pandoc.RawInline('latex', string.format(
                '\\hyperlinkWithTip{%s}[cyan]{%s}{\\parbox{0.5\\linewidth}{%s}}',
                target, content, desc))
        end
    end
end

return {
    { Div = fetch_auto_generated_table },
    { Meta = extract_auto_generated_table_data_and_init_keywords },
    { Block = detect_keywords_and_add_links },
    { Div = instantiate_auto_generated_table }
  }
