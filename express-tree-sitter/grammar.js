// https://en.wikipedia.org/wiki/EXPRESS_(data_modeling_language)

const ident_regex = /[a-zA-Z_][a-zA-Z0-9_]*/;

module.exports = grammar({
  name: "express",
  rules: {
    // NOTE: the first rule is the one is the top-level one!
    source_file: $ => seq("SCHEMA", $.identifier, ";", repeat($.top_decl)),
    identifier: $ => ident_regex,
    top_decl: $ => choice(
      $.entity
    ),
    entity: $ => seq(
      "ENTITY", $.identifier,
      repeat($.entity_attr),
      "END_ENTITY", ";"
    ),
    entity_attr: $ => choice(
      $.property,
      $.supertype_rel,
      $.subtype_rel,
    ),
    supertype_rel: $ => seq(optional("ABSTRACT"), "SUPERTYPE", "OF", $.type_set),
    subtype_rel: $ => seq(optional("ABSTRACT"), "SUBTYPE", "OF", $.type_set),
    type_set: $ => seq("(", repeat1(seq($.type), ","), ")"),
    property: $ => seq($.identifier, ":", optional("OPTIONAL"), $.type, ";"),
    type: $ => $.identifier,
    comment: $ => /\/\*.*?\*\?/,
  },
  // prettier-ignore
  extras: ($) => [
    $.comment,
    /\s/, // whitespace
  ],
});
