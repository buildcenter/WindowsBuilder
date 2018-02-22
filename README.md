Windows Image Customization Tool
================================
WindowsBuilder is a tool for servicing Windows `WIM` image. You can now deep customize your Windows installation with ease!

```batchfile
C:\> md win10 && cd win10
C:\repo\> powershell -Command "& { wget https://raw.githubusercontent.com/buildcenter/WindowsBuilder/master/scaffold.ps1 -UseBasicParsing | iex }"
C:\repo\> build configure
C:\repo\> build mount
C:\repo\> build
C:\repo\> build dismount
```

Congrats! Your shiny new Windows image is ready!


How to Customize
================
First make a copy of `/src/global.bsd` and name it something meaningful, like `win10.bsd`. Edit it with reference to the schema described below. 

Your assets lives under `/resource` by default, so copy them there.


We Need Undo
============
Good news!

```batchfile
C:\repo\> build dismount undo
```

Mounting and dismounting can take quite a while, depending on your hard disk I/O performance. You definitely want to run this on a good SSD.


Schema
======
The source in [/src/global.bsd](./src/global.bsd) contains global settings. Each subfolder under `/src` contain their own schema. You should be able figure everything out just by looking at the comments.

Specific schematics are documented [in the docs](http://buildcenter.github.io/WindowsBuilder/schema).

Since everything is script and template driven, you should just [look at the source](./tools/WindowsBuilder) whenever in doubt.


Contributing
============
If you are interested in fixing issues and contributing directly to the code base,
please see the document [How to Contribute](https://buildcenter.github.io/how-to-contribute), which covers the following:

* [The development workflow, including debugging and running tests](https://buildcenter.github.io/how-to-contribute#development-workflow)
* [Coding Guidelines](https://buildcenter.github.io/coding-guidelines)
* [Submitting pull requests](https://buildcenter.github.io/how-to-contribute#pull-requests)
* [Contributing to translations](https://buildcenter.github.io/how-to-contribute#translations)

Please see also our [Code of Conduct](https://buildcenter.github.io/code-of-conduct).


Feedback
========
* Request a new feature [right here](https://buildcenter.github.io/how-to-contribute).
* Ask a question on [Stack Overflow](https://stackoverflow.com/questions/tagged/windowsbuilder).
* Vote for [popular feature requests](https://github.com/buildcenter/WindowsBuilder/issues?q=is%3Aopen+is%3Aissue+label%3Afeature-request+sort%3Areactions-%2B1-desc).
* File a bug in [GitHub Issues](https://github.com/buildcenter/WindowsBuilder/issues).
* [Tweet](https://twitter.com/lizoc) us with other feedback.

Related Projects
================
DotNetBuild dependencies live in their own repositories on GitHub:
* [Builder](https://www.github.com/buildcenter/Builder)
* [PSTemplate](https://www.github.com/buildcenter/PSTemplate)
* [PSCONFIGON](https://www.github.com/buildcenter/PSConfigon)


License
=======
Copyright (c) Lizoc Corporation. All rights reserved.

Licensed under the [MIT](LICENSE) License.
