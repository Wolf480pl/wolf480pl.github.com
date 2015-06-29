---
title: template-maven-plugin
url: https://github.com/Wolf480pl/template-maven-plugin
widget: true
#nodesc: true
shortdesc: Maven plugin for generating code from trove4j-like templates
---
a Mavenized and improved version of trove4j's code generator. When [flow-math] needed to generate Java classes for each primitive type (because Java generics don't work with primitives), we decided to do it in a similar way trove4j does. I took their generator, wrapped it in a Maven plugin, and added some configurability to it. It uses the same template format as trove4j, except you can define custom placeholders.


[flow-math]: https://github.com/flow/math/
