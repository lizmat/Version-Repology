#- Rank ------------------------------------------------------------------------
enum Rank <none lower-bound
  pre-release zero post-release non-zero letter-suffix
  upper-bound
>;

my constant %repology-special =
  "alpha",   pre-release,
  "beta",    pre-release,
  "rc",      pre-release,
  "pre",     pre-release,
  "post",    post-release,
  "patch",   post-release,
  "pl",      post-release,
  "errata",  post-release,
;
my constant @repology-special-keys = %repology-special.keys.sort(-*.chars);

#- Version::Repology -----------------------------------------------------------
class Version::Repology:ver<0.0.5>:auth<zef:lizmat> {
    has @.parts;
    has $.bound;
    has @.ranks   is built(False);  # done in TWEAK
    has %.special is built(False);  # done in TWEAK
    has $.raku    is built(False);  # done in TWEAK
    has @!special-keys;

    multi method new(Version::Repology: Str() $spec) {
        self.bless(:$spec, |%_)
    }

    submethod TWEAK(
      Str:D :$spec is copy,
            :$p-is-patch,
            :$any-is-patch,
            :$bound,
            :$lower-bound,
            :$upper-bound,
            :$no-leading-zero,
            :$leading-zero-alpha,
            :%special,
            :%additional-special,
    --> Nil) {

        # Set up bound logic
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

        # Set up correct .raku representation
        my str @raku = self.^name ~ qq/.new("$spec"/;
        if $bound && $bound != zero {
            @raku.push: $bound == upper-bound
              ?? ':upper-bound'
              !! ':lower-bound';
        }
        @raku.push: ":p-is-patch"         if $p-is-patch;
        @raku.push: ":any-is-patch"       if $any-is-patch;
        @raku.push: ":no-leading-zero"    if $no-leading-zero;
        @raku.push: ":leading-zero-alpha" if $leading-zero-alpha;

        # Set up any special strings handling
        my sub special-keys(%map) {
            %map.keys.sort( { $^b.chars < $^a.chars || $^a cmp $^b } ).List
        }
        my sub raku-keys(%map, @keys) {
            @keys.map(
              -> $key { ":" ~ $key ~ "($_)" with %map{$key} }
            ).join(", ")
        }

        my @keys;
        if %special {
            %!special := %special.Map;
            @keys := special-keys(%special);
            @raku.push: ":special(&raku-keys(%!special, @keys))";
        }
        elsif %additional-special {
            my %map is Map = |%repology-special, |%additional-special;
            %!special := %map;
            @keys := special-keys(%map);
            @raku.push: ":additional-special(&raku-keys(%additional-special, @keys))";
        }
        else {
            %!special := %repology-special;
            @keys := @repology-special-keys;
        }
        @!special-keys := @keys;

        # Process the specification and create parts/ranks
        my @parts;
        my @ranks;

        my sub add-number($number --> Nil) {
            @parts.push: $number;
            @ranks.push: $number ?? non-zero !! zero;
        }

        $spec .= subst(/ ^ <[0 \W]>+ /) if $no-leading-zero;
        for $spec.comb(/ <[ 0..9 a..z A..Z ]>+ /) -> $outer {
            with $outer.Int -> $number {
                if $leading-zero-alpha && $outer.starts-with("0") {
                    @parts.push: $outer;
                    @ranks.push: $any-is-patch ?? post-release !! pre-release;
                }
                else {
                    add-number($number);
                }
            }
            else {
                my @inner = $outer
                  .comb(/ \d+ | <[ a..z A..Z ]>+ /)
                  .map: { .Int // $_ }

                for @inner.kv -> int $i, $part {
                    if $part ~~ Int {
                        add-number($part);
                    }
                    else {
                        my $lc-part := $part.lc;
                        @parts.push: $lc-part.substr(0,1);  # 1st letter only
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
                              !! $p-is-patch && $lc-part eq 'p'
                                ?? post-release
                                !! pre-release;

                            # Handle the special cases
                            for @keys {
                                if $lc-part.starts-with($_) {
                                    $rank = %!special{$_};
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
        $!raku  := @raku.join(", ") ~ ")";
    }

    multi method Str(Version::Repology:D:) { @!parts.join(".") }
    multi method raku(Version::Repology:D:) { $!raku }

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

    method eqv(Version::Repology:D: Version::Repology:D $other) {
        @!ranks eqv $other.ranks
          && @!parts eqv $other.parts
          && $!bound ==  $other.bound
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

my multi sub infix:<eqv> (
  Version::Repology:D $a, Version::Repology:D $b
--> Bool:D) is export {
    $a.eqv($b)
}

#- other infix methods ---------------------------------------------------------
# Note that this is a bit icky, but it allows for a direct mapping of the
# infix op name to a method for comparison with the $a."=="($b) syntax,
# without having to have the above infixes to be imported
BEGIN {
    Version::Repology.^add_method: "==", { $^a.cmp($^b) == Same }  # UNCOVERABLE
    Version::Repology.^add_method: "!=", { $^a.cmp($^b) != Same }  # UNCOVERABLE
    Version::Repology.^add_method: "<",  { $^a.cmp($^b) == Less }  # UNCOVERABLE
    Version::Repology.^add_method: "<=", { $^a.cmp($^b) != More }  # UNCOVERABLE
    Version::Repology.^add_method: ">",  { $^a.cmp($^b) == More }  # UNCOVERABLE
    Version::Repology.^add_method: ">=", { $^a.cmp($^b) != Less }  # UNCOVERABLE
}

# vim: expandtab shiftwidth=4
