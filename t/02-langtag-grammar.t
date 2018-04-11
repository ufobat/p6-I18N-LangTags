use I18N::LangTags::List;

use Test;


is I18N::LangTags::List::LangTagGrammar.parse(
    'en',
    :rule('langtag')),
'en';

is I18N::LangTags::List::LangTagGrammar.parse(
    'This is English',
    :rule('name')),
'This is English';

is I18N::LangTags::List::LangTagGrammar.parse(
    '{en} : This is English',
    :rule('language')),
'{en} : This is English';

is I18N::LangTags::List::LangTagGrammar.parse(
    '[{en} : This is English]'),
'[{en} : This is English]';

is I18N::LangTags::List::LangTagGrammar.parse(
    'noise [{en} : This is English] noise {de} : German',
    :rule('scan_languages')),
'noise [{en} : This is English] noise {de} : German';


# With actions
# a Pair
is-deeply I18N::LangTags::List::LangTagGrammar.parse(
    '{en} : This is English',
    :rule('language'),
    :actions(I18N::LangTags::List::LangTagActions.new)).made,
(en => 'This is English');

# TOP token
is-deeply I18N::LangTags::List::LangTagGrammar.parse(
    '[{en} : This is English]',
    :actions(I18N::LangTags::List::LangTagActions.new)).made,
(en => 'This is English');

is-deeply I18N::LangTags::List::LangTagGrammar.parse(
    'noise [{en} : This is English] noise {de} : German',
    :rule('scan_languages'),
    :actions(I18N::LangTags::List::LangTagActions.new)).made
, {
    en => 'This is English',
    de => 'German',
};

