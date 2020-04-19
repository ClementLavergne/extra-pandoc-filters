# Columns

This `pandoc` filter enables the support of columns for `PDF` output.
`Pandoc` already renders them for some markup formats like `HTML`, but not for `PDF`.

## How-to

Columns are defined through nested `Divs` as following:

```markdown
:::::: {.columns}
::: {.column width="50%"}
First column content (left)
:::
::: {.column width="50%"}
Second column content (right)
:::
::::::
```

> It is possible to declare `n` columns.

## Limitation

The **width** of a column is discarded; columns are evenly distributed on the whole page width.
