# Landscape

This `pandoc` filter wraps content in *landscape* (rotated page) for `PDF` output.

## How-to

This filter is called through a `Div` macro:

```markdown
<!-- Next content will be displayed in landscape -->
::: landscape
# A chapter

A paragraph

![A large image](image/big-image.jpg)
:::

<!-- Next content will be displayed in portrait -->
# Another chapter

A paragraph
```
