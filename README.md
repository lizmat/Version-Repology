[![Actions Status](https://github.com/lizmat/Version-Repology/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/Version-Repology/actions) [![Actions Status](https://github.com/lizmat/Version-Repology/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/Version-Repology/actions) [![Actions Status](https://github.com/lizmat/Version-Repology/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/Version-Repology/actions)

NAME
====

Version::Repology - Implement Repology Version logic

SYNOPSIS
========

```raku
use Version::Repology;
```

DESCRIPTION
===========

The `Version::Repology` distribution provides a `Version::Repology` class that encapsulates the logic for creating a `Version`-like object with semantics matching the Repology implementation of [`libversion`](https://github.com/repology/libversion/tree/master?tab=readme-ov-file#libversion).

In order to avoid any dependencies, this implementation is a pure Raku implementation.

CREDITS
=======

This module is based on the work done by Dmitry Marakasov on the [`libversion`](https://github.com/repology/libversion/tree/master?tab=readme-ov-file#libversion) project.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Version-Repology . Comments and Pull Requests are welcome.

If you like this module, or what I’m doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2025 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

