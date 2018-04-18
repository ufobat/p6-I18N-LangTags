use v6.c;
unit class I18N::LangTags:ver<0.0.1>;
use I18N::LangTags::Grammar;
use I18N::LangTags::Actions;

my $actions = I18N::LangTags::Actions.new();
my regex ix { ['i' | 'x' ] }

sub is_language_tag(Str:D $tag --> Bool) is export {
    return so I18N::LangTags::Grammar.parse($tag, :rule('langtag'))
}

sub extract_language_tags(Str:D $text --> Seq) is export {
    return I18N::LangTags::Grammar.parse(
        $text,
        :rule('scan_langtags'),
        :$actions).made
}

sub same_language_tag(Str:D $tag1, Str:D $tag2 --> Bool) is export {
    return encode_language_tag($tag1) eq encode_language_tag($tag2)
        if is_language_tag($tag1) and is_language_tag($tag2);
    return False;
}

sub similarity_language_tag(Str:D $tag1, Str:D $tag2 --> Int) is export {
    return Nil unless is_language_tag($tag1) and is_language_tag($tag2);
    return 0 unless is_language_tag($tag1) or is_language_tag($tag2);

    my @subtags1 = encode_language_tag($tag1).split('-');
    my @subtags2 = encode_language_tag($tag2).split('-');

    my Int $similarity = 0;
    for (@subtags1 Z[eq] @subtags2) -> $similar {
        if $similar {
            $similarity++;
        } else {
            return $similarity;
        }
    }
    return $similarity;
}

sub is_dialact_of(Str:D $tag1, Str:D $tag2 --> Bool) is export {
    my $lang1 = encode_language_tag($tag1);
    my $lang2 = encode_language_tag($tag2);

    return Bool if !is_language_tag($lang1) && !is_language_tag($lang2);
    return False if !is_language_tag($lang1) or !is_language_tag($lang2);

    return True if $lang1 eq $lang2;
    return False if $lang1.chars < $lang2.chars;

    $lang1 ~= '-';
    $lang2 ~= '-';
    return $lang1.substr(0, $lang2.chars) eq $lang2;
}

sub super_languages(Str:D $tag --> List) is export {
    return () unless is_language_tag($tag);
    # a hack for those annoying new (2001) tags:
    $tag ~~ s:i/ ^ 'nb' <|w> / 'no-bok' /; # yes, backwards
    $tag ~~ s:i/ ^ 'nn' <|w> / 'no-nyn' /; # yes, backwards
    $tag ~~ s:i/ ^ <ix> ( '-hakka' <|w> ) / 'zh' $1 /; # goes the right way
    # i-hakka-bork-bjork-bjark => zh-hakka-bork-bjork-bjark

    my @supers;
    for $tag.split('-') -> $bit {
        @supers.push( @supers.elems > 0 ?? @supers[*-1] ~ '-' ~ $bit !! $bit);
    };
    pop @supers if @supers;
    shift @supers if @supers[0] ~~ m:i/ ^ <ix> $ /;
    return @supers.reverse();
}

sub locale2language_tag(Str:D $locale is copy --> Str) is export {
    return $locale if is_language_tag($locale);
    $locale ~~ s:g/ '_' /-/;
    $locale ~~ s/ [ ['.'|'@'] [ <alnum> | '-' ]+]+ $ //;
    return $locale if is_language_tag($locale);
    return Str;
}

sub encode_language_tag(Str:D $tag is copy --> Str:D) is export {
    # Only similarity_language_tag() is allowed to analyse encodings!
    ## Changes in the language tagging standards may have to be reflected here.
    return Nil unless is_language_tag($tag);

    # For the moment, these legacy variances are few enough that
    #  we can just handle them here with regexps.

    $tag ~~ s:i/ ^ 'iw'           <|w> /he/; # Hebrew
    $tag ~~ s:i/ ^ 'in'           <|w> /id/; # Indonesian
    $tag ~~ s:i/ ^ 'cre'          <|w> /cr/; # Cree
    $tag ~~ s:i/ ^ 'jw'           <|w> /jv/; # Javanese
    $tag ~~ s:i/ ^ <ix> '-lux'    <|w> /lb/; # Luxemburger
    $tag ~~ s:i/ ^ <ix> '-navajo' <|w> /nv/; # Navajo
    $tag ~~ s:i/ ^ 'ji'           <|w> /yi/; # Yiddish

    # SMB 2003 -- Hm.  There's a bunch of new XXX->YY variances now,
    #  but maybe they're all so obscure I can ignore them.   "Obscure"
    #  meaning either that the language is obscure, and/or that the
    #  XXX form was extant so briefly that it's unlikely it was ever
    #  used.  I hope.
    #
    # These go FROM the simplex to complex form, to get
    #  similarity-comparison right.  And that's okay, since
    #  similarity_language_tag is the only thing that
    #  analyzes our output.
    $tag ~~ s:i/ ^ <ix> '-hakka' <|w> /zh-hakka/;  # Hakka
    $tag ~~ s:i/ ^ 'nb'          <|w> /no-bok/;    # BACKWARDS for Bokmal
    $tag ~~ s:i/ ^ 'nn'          <|w> /no-nyn/;    # BACKWARDS for Nynorsk

    # Just lop off any leading "x/i-"
    $tag ~~ s:i/ ^ <ix> '-' //;
    return "~" ~ uc($tag);
}

sub alternate_language_tags(Str:D $tag) is export {
    return () unless is_language_tag($tag);
    my @em;

    if    $tag ~~ m:i/ ^ <ix> '-hakka' <|w> (.*)/ { push @em, "zh-hakka$0"; }
    elsif $tag ~~ m:i/ ^ 'zh-hakka' <|w> (.*)/ {    push @em, "x-hakka$0", "i-hakka$0"; }
    elsif $tag ~~ m:i/ ^ 'he' <|w> (.*)/ {          push @em, "iw$0"; }
    elsif $tag ~~ m:i/ ^ 'iw' <|w>(.*)/ {           push @em, "he$0"; }
    elsif $tag ~~ m:i/ ^ 'in' <|w>(.*)/ {           push @em, "id$0"; }
    elsif $tag ~~ m:i/ ^ 'id' <|w>(.*)/ {           push @em, "in$0"; }
    elsif $tag ~~ m:i/ ^ <ix> '-lux' <|w>(.*)/ {    push @em, "lb$0"; }
    elsif $tag ~~ m:i/ ^ 'lb' <|w>(.*)/ {           push @em, "i-lux$0", "x-lux$0"; }
    elsif $tag ~~ m:i/ ^ <ix> '-navajo' <|w>(.*)/ { push @em, "nv$0"; }
    elsif $tag ~~ m:i/ ^ 'nv' <|w>(.*)/ {           push @em, "i-navajo$0", "x-navajo$0"; }
    elsif $tag ~~ m:i/ ^ 'yi' <|w>(.*)/ {           push @em, "ji$0"; }
    elsif $tag ~~ m:i/ ^ 'ji' <|w>(.*)/ {           push @em, "yi$0"; }
    elsif $tag ~~ m:i/ ^ 'nb' <|w>(.*)/ {           push @em, "no-bok$0"; }
    elsif $tag ~~ m:i/ ^ 'no-bok' <|w>(.*)/ {       push @em, "nb$0"; }
    elsif $tag ~~ m:i/ ^ 'nn' <|w>(.*)/ {           push @em, "no-nyn$0"; }
    elsif $tag ~~ m:i/ ^ 'no-nyn' <|w>(.*)/ {       push @em, "nn$0"; }

    state %alt = (
        i => 'x',
        x => 'i',
    );
    push @em, %alt{ $1.lc()} ~ $2 if $tag ~~ m:i/^ (<ix>) ('-' .+)/;
    return @em;
}

my sub init_panic(--> Hash) is pure {
    my %panic;
    for (
        # MUST all be lowercase!
        # Only large ("national") languages make it in this list.
        #  If you, as a user, are so bizarre that the /only/ language
        #  you claim to accept is Galician, then no, we won't do you
        #  the favor of providing Catalan as a panic-fallback for
        #  you.  Because if I start trying to add "little languages" in
        #  here, I'll just go crazy.

        # Scandinavian lgs.  All based on opinion and hearsay.
        'sv'       => <nb no da nn>,
        'da'       => <nb no sv nn>, # I guess
        <no nn nb> => <no nn nb sv da>,
        'is'       => <da sv no nb nn>,
        'fo'       => <da is no nb nn sv>, # I guess

        # I think this is about the extent of tolerable intelligibility
        #  among large modern Romance languages.
        'pt' => <es ca it fr>, # Portuguese, Spanish, Catalan, Italian, French
        'ca' => <es pt it fr>,
        'es' => <ca it fr pt>,
        'it' => <es fr ca pt>,
        'fr' => <es it ca pt>,

        # Also assume that speakers of the main Indian languages prefer
        #  to read/hear Hindi over English
        <as bn gu kn ks kok ml mni mr ne or pa sa sd te ta ur> => 'hi',

        # Assamese, Bengali, Gujarati, [Hindi,] Kannada (Kanarese), Kashmiri,
        # Konkani, Malayalam, Meithei (Manipuri), Marathi, Nepali, Oriya,
        # Punjabi, Sanskrit, Sindhi, Telugu, Tamil, and Urdu.
        'hi' => <bn pa as or>,

        # I welcome finer data for the other Indian languages.
        #  E.g., what should Oriya's list be, besides just Hindi?
        # And the panic languages for English is, of course, nil!

        # My guesses at Slavic intelligibility:
        Pair.new( |( <ru be uk> xx 2)),   # Russian, Belarusian, Ukranian
        Pair.new( |( <sr hr bs> xx 2)),  # Serbian, Croatian, Bosnian
        'cs' => 'sk', 'sk' => 'cs', # Czech + Slovak
        'ms' => 'id', 'id' => 'ms', # Malay + Indonesian
        'et' => 'fi', 'fi' => 'et', # Estonian + Finnish
        #?? 'lo' => 'th', 'th' => 'lo', # Lao + Thai
    ) {
        my ($keys, $vals) = .kv;
        for |$keys -> $k {
            for |$vals -> $v {
                %panic{ $k }.push: $v;
            }
        }
    }
    return %panic;
}

sub panic_languages(*@tags --> Set) is export {
    # When in panic or in doubt, run in circles, scream, and shout!
    state %panic = init_panic();
    my @out = <en>;
    for @tags -> $tag {
        @out.push: |$_ with %panic{$tag};
    }
    return set @out;
}

sub implicate_supers(*@tags --> Set) is export {
    my @languages = @tags.grep({ is_language_tag($_) });
    my @out;

    for @languages -> $lang {
        @out.push: $lang;
        @out.append: super_languages($lang);
    }

    return set @out;
}

sub implicate_supers_strictly(*@tags --> Set) is export {
    my @languages = @tags.grep({ is_language_tag($_) });
    my @out = @languages;

    for @languages -> $lang {
        @out.append: super_languages($lang);
    }
    return set @out;
}

=begin pod

=head1 NAME

I18N::LangTags - ported from Perl5

=head1 SYNOPSIS

  use I18N::LangTags;

=head1 DESCRIPTION

Language tags are a formalism, described in RFC 3066 (obsoleting
1766), for declaring what language form (language and possibly
dialect) a given chunk of information is in.

This library provides functions for common tasks involving language
tags as they are needed in a variety of protocols and applications.

Please see the "See Also" references for a thorough explanation
of how to correctly use language tags.

=head1 FUNCTIONS

=begin item
is_language_tag($lang1)

Returns true iff $lang1 is a formally valid language tag.

   is_language_tag("fr")            is TRUE
   is_language_tag("x-jicarilla")   is FALSE
       (Subtags can be 8 chars long at most -- 'jicarilla' is 9)

   is_language_tag("sgn-US")    is TRUE
       (That's American Sign Language)

   is_language_tag("i-Klikitat")    is TRUE
       (True without regard to the fact noone has actually
        registered Klikitat -- it's a formally valid tag)

   is_language_tag("fr-patois")     is TRUE
       (Formally valid -- altho descriptively weak!)

   is_language_tag("Spanish")       is FALSE
   is_language_tag("french-patois") is FALSE
       (No good -- first subtag has to match
        /^([xXiI]|[a-zA-Z]{2,3})$/ -- see RFC3066)

   is_language_tag("x-borg-prot2532") is TRUE
       (Yes, subtags can contain digits, as of RFC3066)
=end item

=head1 SEE ALSO

* L<https://metacpan.org/pod/I18N::LangTags>

* L<I18N::LangTags::List|I18N::LangTags::List>

* RFC 3066, C<http://www.ietf.org/rfc/rfc3066.txt>, "Tags for the
Identification of Languages".  (Obsoletes RFC 1766)

* RFC 2277, C<http://www.ietf.org/rfc/rfc2277.txt>, "IETF Policy on
Character Sets and Languages".

* RFC 2231, C<http://www.ietf.org/rfc/rfc2231.txt>, "MIME Parameter
Value and Encoded Word Extensions: Character Sets, Languages, and
Continuations".

* RFC 2482, C<http://www.ietf.org/rfc/rfc2482.txt>,
"Language Tagging in Unicode Plain Text".

* Locale::Codes, in
C<http://www.perl.com/CPAN/modules/by-module/Locale/>

* ISO 639-2, "Codes for the representation of names of languages",
including two-letter and three-letter codes,
C<http://www.loc.gov/standards/iso639-2/php/code_list.php>

* The IANA list of registered languages (hopefully up-to-date),
C<http://www.iana.org/assignments/language-tags>

=head1 AUTHOR

Martin Barth <martin@senfdax.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Martin Barth

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
