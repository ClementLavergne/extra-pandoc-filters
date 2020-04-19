# Generic table

This `pandoc` filter allows you to declare an auto-generated table through `YAML` metadata.
The metadata structure is generic but provides keyword-related features.

## Declare a table

A *generic table* is a map composed of two **keys**:

* `layout` is a list of **column properties**.
* `rows` is a list of **row contents**.

For instance, a **generic table** called `abbreviations` can be declared as following:

```yaml
abbreviations:
    rows:
        -   keyword:        H/W
            description:    Hardware

        -   keyword:        IPC
            description:    Inter-Process Communication

        -   keyword:        SDD
            description:    Software Design Document

        -   keyword:        S/W
            description:    Software

    layout:
        -   id:             keyword
            header:         Acronym
            align:          AlignCenter
            width:          0.25

        -   id:             description
            header:         Definition
            align:          AlignDefault
            width:          0.75
```

The order of the defined columns - in `layout` - will be used as is for the rendering of the table (from **left** to **right**).

### Layout

A `layout` item is a map of four **keys**:

* `id` defines the **key** associated to the column.
* `header` defines the **title** of the column
* `align` defines the **alignment** of the column content; four constants are available:
    * `AlignDefault`
    * `AlignLeft`
    * `AlignCenter`
    * `AlignRight`
* `width` defines the **width** of the column

> Make sure the total amount of **width** is equal to `1`.

#### Keyword detection

If `id` is equal to `keyword`, the filter will perform a **keyword detection** across the document and display the used ones only!

Such feature might be useful for **abbreviations**, **terms** and **bibliography**.

### Rows

A `rows` item is a map of `n` columns defined in `layout`.

> The value of each defined **key** must be set.

## Generate a table

A **generic table** is instantiated thanks to a `Div` element; if we consider the previous `abbreviations` table we should have:

```markdown
::: table
* meta:     abbreviations
* caption:  Employed acronyms
:::
```
