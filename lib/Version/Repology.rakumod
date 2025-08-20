#- Rank ------------------------------------------------------------------------
enum Rank <none lower-bound
  pre-release zero post-release non-zero letter-suffix
  upper-bound
>;

my constant %special =
  "alpha",   pre-release,
  "beta",    pre-release,
  "rc",      pre-release,
  "pre",     pre-release,
  "post",    post-release,
  "patch",   post-release,
  "pl",      post-release,
  "errata",  post-release,
;
my constant @special-keys = %special.keys.sort(-*.chars);

#- Version::Repology -----------------------------------------------------------
class Version::Repology:ver<0.0.1>:auth<zef:lizmat> {
    has @.parts;
    has $.bound;
    has @.ranks is built(False);

    multi method new(Version::Repology: Str() $spec) {
        self.bless(:$spec, |%_)
    }

    submethod TWEAK(
      Str:D :$spec,
            :$p-is-patch,
            :$any-is-patch,
            :$bound,
            :$lower-bound,
            :$upper-bound,
    --> Nil) {

        $!bound := $bound.defined
          ?? $bound eq 'upper'
            ?? upper-bound
            !! $bound eq 'lower'
              ?? lower-bound
              !! die "Unknown bound indicator: $bound.  Must be 'upper' or 'lower'"
          !! $lower-bound
            ?? lower-bound
            !! $upper-bound
              ?? upper-bound
              !! zero;

        my @parts;
        my @ranks;

        my sub add-number($number --> Nil) {
            @parts.push: $number;
            @ranks.push: $number ?? non-zero !! zero;
        }

        for $spec.comb(/ <[ 0..9 a..z A..Z ]>+ /) -> $outer {
            with $outer.Int -> $number {
                add-number($number);
            }
            else {
                my @inner = $outer
                  .comb(/ \d+ | <[ a..z A..Z ]>+ /)
                  .map: { .Int // $_ }

                for @inner.kv -> int $i, $part is copy {
                    if $part ~~ Int {
                        add-number($part);
                    }
                    else {
                        $part .= lc;
                        @parts.push: $part.substr(0,1);  # 1st letter only
                        @ranks.push: do if $any-is-patch {
                            post-release
                        }

                        # Need to determine the rank
                        else {
# A special case exists for alphabetic component which follows numeric
# component, and is not followed by another numeric component (1.0a,
# 1.0a.1, but not 1.0a1). Such alphabetic component is assigned a
# different rank, LETTER_SUFFIX, which follows NONZERO
                            my $rank = $i                # not first
                              && @inner[$i-1] ~~ Int     # following numeric
                              && $i == @inner.end        # last one
                              ?? letter-suffix
                              !! $p-is-patch && $part eq 'p'
                                ?? post-release
                                !! pre-release;

                            # Handle the special cases
                            for @special-keys {
                                if $part.starts-with($_) {
                                    $rank = %special{$_};
                                    last;
                                }
                            }

                            $rank
                        }
                    }
                }
            }
        }

        @!parts := @parts.List;
        @!ranks := @ranks.List;
    }

    multi method Str(Version::Repology:D:) {
        @!parts.join(".")
    }
    multi method raku(Version::Repology:D:) {
        self.^name ~ ".new(" ~ self.Str.raku ~ ")"
    }

    method cmp(Version::Repology:D: Version::Repology:D $other --> Order) {
        my @oparts := $other.parts;
        my @oranks := $other.ranks;
        my $obound := $other.bound;

        # Start with comparing ranks
        my int $i;
        for @!ranks -> $rank {

            # Something to compare with
            with @oranks[$i] -> $orank {
                if $rank cmp $orank -> $diff {
                    return $diff;  # UNCOVERABLE
                }
            }

            # Nothing to compare with, is right side is always upper?
            else {
                if $rank cmp $obound -> $diff {
                    return $diff;  # UNCOVERABLE
                }
            }

            # Ranks the same, need to check parts
            my $left  := @!parts[$i];
            my $right := @oparts[$i];

            # Same types can use cmp semantics for comparison
            if $left.WHAT =:= $right.WHAT {
                if $left cmp $right -> $diff {
                    return $diff;  # UNCOVERABLE
                }
            }

            # I'd say that intuitively 1.0 < 1.0a < 1.0.1 because
            # a seems to be tighter "variant" of 1.0 than the "next
            # release" 1.0.1, and it would also correspond to how
            # general alphabetic parts are ordered (a < 1), but we
            # still stick to 1.0 < 1.0.1 < 1.0a order, because in
            # practice no valid cases were found to be broken by
            # this, but a number of cases where incorrectly written
            # versions (1.0a as 1.0.1) were favored upon genuine
            # ones appeared.
            elsif $left ~~ Int {  # && $right ~~ Str  # UNCOVERABLE
                return Less
            }

            ++$i;
        }

        # More on the right-hand side
        with @oranks[$i] -> $rank {
            $!bound cmp $rank
        }

        # Same so far, with nothing left to check
        else {
             $!bound cmp $obound
        }
    }
}

#- infixes ---------------------------------------------------------------------
my multi sub infix:<cmp>(
  Version::Repology:D $a, Version::Repology:D $b
--> Order:D) is export {
    $a.cmp($b)
}

my multi sub infix:<==>(
  Version::Repology:D $a, Version::Repology:D $b
--> Bool:D) is export {
    $a.cmp($b) == Same
}

my multi sub infix:<!=>(
  Version::Repology:D $a, Version::Repology:D $b
--> Bool:D) is export {
    $a.cmp($b) != Same
}

my multi sub infix:«<» (
  Version::Repology:D $a, Version::Repology:D $b
--> Bool:D) is export {
    $a.cmp($b) == Less
}

my multi sub infix:«<=» (
  Version::Repology:D $a, Version::Repology:D $b
--> Bool:D) is export {
    $a.cmp($b) != More
}

my multi sub infix:«>» (
  Version::Repology:D $a, Version::Repology:D $b
--> Bool:D) is export {
    $a.cmp($b) == More
}

my multi sub infix:«>=» (
  Version::Repology:D $a, Version::Repology:D $b
--> Bool:D) is export {
    $a.cmp($b) != Less
}

# vim: expandtab shiftwidth=4
