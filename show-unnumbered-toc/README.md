# Show unnumbered section in TOC

This `pandoc` filter forces *unnumbered* sections to be listed within the table of contents for `PDF` output.

For your information, an *unnumbered* section is defined as following:

```markdown
<!-- This next section will be unnumbered -->
# Preamble {-}

<!-- This next section will be numbered -->
# Chapter one
```

Usually, *unnumbered* sections are not part of the **table of contents** for `PDF`.
