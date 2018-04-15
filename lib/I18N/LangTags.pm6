use v6.c;
unit class I18N::LangTags:ver<0.0.1>;
use I18N::LangTags::Grammar;
use I18N::LangTags::Actions;
use I18N::LangTags::Grammar;

my $actions = I18N::LangTags::Actions.new();

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

sub encode_language_tag(Str:D $tag is copy --> Str:D) is export {
    # Only similarity_language_tag() is allowed to analyse encodings!
    ## Changes in the language tagging standards may have to be reflected here.
    return Nil unless is_language_tag($tag);

    # For the moment, these legacy variances are few enough that
    #  we can just handle them here with regexps.
    my regex ix { ['i' | 'x' ] }

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

sub similarity_language_tag(Str:D $tag1, Str:D $tag2 --> Int) is export {
    return Nil unless is_language_tag($tag1) and is_language_tag($tag2);
    return 0 unless is_language_tag($tag1) or is_language_tag($tag2);

    my @subtags1 = encode_language_tag($tag1).split('-');
    my @subtags2 = encode_language_tag($tag2).split('-');

    return (@subtags1 Z== @subtags2).grep(*.so).elems;
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
