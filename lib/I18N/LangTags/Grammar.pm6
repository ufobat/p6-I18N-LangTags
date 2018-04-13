use v6.c;

grammar I18N::LangTags::Grammar {
    token TOP { <disrec_language> | <language> }
    token disrec_language { '[' <language> ']' }
    token language { '{' <langtag> '}' \h+ [ ':' \h+]? <name> }
    regex langtag {
        [ 'i' | 'x' | [<alpha> ** 2..3] ] # start
        [ '-' <alpha> ** 1..8] *            # subtags
    }
    token name { <[\w\s\-()]>+ }

    regex scan_languages { [ .*? <TOP> .*?]+  }
    regex scan_langtags  { [ .*? <|w> <langtag> <|w> .*? ]+ }
    regex formerly { .*? 'Formerly "' <langtag> '"' .*? }
}
