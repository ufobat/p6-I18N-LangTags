use v6.c;
use I18N::LangTags::List;
use Test;

my $has-inline-perl5 = not (try require Inline::Perl5) === Nil;

if $has-inline-perl5 {
    my $p = Inline::Perl5.new();
    my ($p5-name, $p5-disrec) = $p.run(q:to/END/);
    # this is perl5 code
    use strict;
    use I18N::LangTags::List;
    [\%I18N::LangTags::List::Name, \%I18N::LangTags::List::Is_Disrec]
    END

    is %I18N::LangTags::List::Name.elems, $p5-name.elems, "found all tags";
    for $p5-name.kv -> $tag, $name {
        ok %I18N::LangTags::List::Name{ $tag }:exists, "found language tag from perl5: $tag - $name";
    }

    for $p5-disrec.kv -> $tag, $name {
        exit unless ok %I18N::LangTags::List::Is_Disrec{ $tag }:exists, "found disecommended language tag from perl5: $tag - $name";
    }
    is %I18N::LangTags::List::Name.elems, $p5-name.elems, "found all recommended languages";
    is %I18N::LangTags::List::Is_Disrec.elems, $p5-disrec.elems, "found all disrecommended languages";

} else {
    skip 'can not use Inline::Perl5';
}

done-testing;
