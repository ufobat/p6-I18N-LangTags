grammar I18N::LangTags::Grammar {
    token TOP { <disrec_language> | <language> }
    token disrec_language { '[' <language> ']' }
    token language { '{' <langtag> '}' \h+ [ ':' \h+]? <name> }
    token langtag { [ <alpha> | '-' ]+ }
    token name { <[\w\s\-()]>+ }

    regex scan_languages { [ .*? <TOP> .*?]+  }
    regex formerly { .*? 'Formerly "' <langtag> '"' .*? }
}
