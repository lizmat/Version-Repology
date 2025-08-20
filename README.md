[![Actions Status](https://github.com/lizmat/Version-Repology/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/Version-Repology/actions) [![Actions Status](https://github.com/lizmat/Version-Repology/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/Version-Repology/actions) [![Actions Status](https://github.com/lizmat/Version-Repology/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/Version-Repology/actions)

NAME
====

Version::Repology - Implement Repology Version logic

SYNOPSIS
========

```raku
use Version::Repology;

my $left  = Version::Repology.new("1.0");
my $right = Version::Repology.new("1.1");

# method interface
say $left.cmp($right);  # Less
say $left."<"($right);  # True

# infix interface
say $left cmp $right;  # Less
say $left < $right;    # True
```

DESCRIPTION
===========

The `Version::Repology` distribution provides a `Version::Repology` class that encapsulates the logic for creating a `Version`-like object with semantics matching the Repology implementation of [`libversion`](https://github.com/repology/libversion/tree/master?tab=readme-ov-file#libversion).

In order to avoid any dependencies, this implementation is a pure Raku implementation.

FEATURES
========

From the `libversion` documentation:

A short list of features
------------------------

  * Simple versions, obviously: 0.9 < 1.0 < 1.1

  * Omitting insignificant components: 1.0 == 1.0.0

  * Leading zeroes: 1.001 == 1.1

  * Unusual separators: 1_2~3 == 1.2.3

  * Letter suffixes: 1.2 < 1.2a < 1.2b < 1.3

Alphanumeric prerelease components:

  * 1.0alpha1 == 1.0.alpha1 == 1.0a1 == 1.0.a1

  * 1.0alpha1 < 1.0alpha2 < 1.0beta1 < 1.0rc1 < 1.0

Awareness of pre-release keywords: alpha, beta, rc, pre

  * while 1.0 < 1.0a-1 (a treated as version addendum)

  * but 1.0alpha-1 < 1.0 (alpha is treated as prerelease marker)

Awareness post-release keywords: patch, post, pl, errata

  * while 1.0alpha1 < 1.0 (alpha is pre-release)

  * but 1.0 < 1.0patch1 < 1.1 (patch is post-release)

Customizable handling of `p` keyword (it may mean either "patch" or "pre").

Logic for checking whether a given version "belongs" to another version logically.

INSTANTIATION
=============

```raku
use Version::Repology;

my $v = Version::Repology.new("1.0");
my $p = Version::Repology.new("1.0", :p-is-patch);
my $a = Version::Repology.new("1.0", :any-is-patch);
my $u = Version::Repology.new("1.0", :upper-bound);
my $l = Version::Repology.new("1.0", :lower-bound);
my $n = Version::Repology.new("0.0.1", :no-leading-zero);
```

The basic instantion of a `Version::Repology` object is done with the `new` method, taking the version string as a positional argument.

Additionally, the following named arguments can be specified:

:p-is-patch
-----------

If an alphabetic component consists of "p", then assume it's the same as "patch", aka a post-release string. If not specified, or specified with a false value, will consider "p" as a pre-release string (the same as "pre").

:any-is-patch
-------------

Any alphabetic component is assumed as "patch", aka a post-release string. If not specified, or specified with a false value, will consider any alphabetic component as a pre-release string (the same as "pre").

:upper-bound
------------

If in comparison two objects are the same, then select this one as being **higher** in version. Can also be specified as `:bound<upper>`.

:lower-bound
------------

If in comparison two objects are the same, then select this one as being **lower** in version. Can also be specified as `:bound<lower>`.

:no-leading-zero
----------------

Remove any leading `0` parts from a version string so that `0.0.1` is the same as `1`. If not specified, or specified with a false value, will **not** remove any leading `0` parts.

This is an additional feature in the Raku implementation only.

ACCESSORS
=========

parts
=====

```raku
my $a  = Version::Repology.new("1.0.foo");
dd $a.parts;  # (1, 0, "f")
```

Returns the values that are associated with each logical part of the version.

ranks
=====

```raku
my $a  = Version::Repology.new("1.0.foo");
say $a.ranks;  # (non-zero zero pre-release)
```

Returns the `Rank` enums that are associated with each logical part of the version.

bound
=====

```raku
my $a  = Version::Repology.new("1.0", :upper-bound");
say $a.bound;  # upper-bound
```

Returns the special bound `Rank` value. This is `zero` by default, but can be changed with the `:upper-bound` and `:lower-bound` named arguments on object instantiation.

OTHER METHODS
=============

cmp
---

```raku
my $left  = Version::Repology.new("1.0");
my $right = Version::Repology.new("1.1");

say $left.cmp($left);   # Same
say $left.cmp($right);  # Less
say $right.cmp($left);  # More
```

The `cmp` method returns the `Order` of a comparison of the invocant and the positional argument, which is either `Less`, `Same`, or `More`. This method is the workhorse for comparisons.

eqv
---

```raku
my $left  = Version::Repology.new("1.0foo");
my $right = Version::Repology.new("1.0f");

say $left.eqv($right);  # True
```

The `eqv` method returns whether the internal state of two `Version::Repology` objects is identical. Note that does not necessarily means that their stringification is the same, as any alphabetical string is internally shortened to first lowercased character for comparisons.

== != < <= > >=
---------------

```raku
my $left  = Version::Repology.new("1.0foo");
my $right = Version::Repology.new("1.0f");

say $left."=="($left);  # True
say $left."<"($right);  # True
```

These oddly named methods provide the same functionality as their infix counterparts. Please note that you **must** use the `"xx"()` syntax, because otherwise the Raku compiler will assume you've made a syntax error.

EXPORTED INFIXES
================

The following `infix` candidates handling `Version::Repology` are exported:

  * cmp (returns `Order`)

  * eqv == != < <= > >= (returns `Bool`)

ALGORITHM
=========

The actual algorithm is described in the [`libversion repository`](https://github.com/repology/libversion/blob/master/doc/ALGORITHM.md).

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

