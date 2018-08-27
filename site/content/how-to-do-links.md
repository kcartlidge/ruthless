# How to do Links

Links are done in the normal Markdown way:

```` markdown
[Back to the home page](index.html)
````

To target your own pages note that only extentions (not file names) are changed when creating the static site.
This means you target the *existing* folder/file names as per the original folder/file structure in ```content```.
Therefore it is suggested your content filenames are *slugs* (e.g. ```this-page``` not ```This Page```).
Whether you need ```.html``` depends upon whether you activate simple URLs.

The default template will automatically (via JavaScript) add a ```target``` attribute to any links that have a protocol.
For example ```[Liquid](https://shopify.github.io/liquid/)``` looks like: [Liquid](https://shopify.github.io/liquid/)

[Back to the home page](index.html)
