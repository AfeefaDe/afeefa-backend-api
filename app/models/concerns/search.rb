module Search

  def search(terms, attributes, objects, attributes_operator: 'OR', terms_operator: 'AND')
    search_with_custom_operators(terms, attributes, objects, attributes_operator, terms_operator)
  end

  private

  def search_with_custom_operators(terms, attributes, objects, attributes_operator, terms_operator)
    terms = normalize_terms(terms)
    term_conditions = build_term_conditions(terms, attributes)

    x = objects.where(
      build_statements_for_terms(term_conditions, attributes_operator, terms_operator),
      *build_bind_variables_for_terms(term_conditions)
    )
    pp x.to_sql
    x
  end

  def build_statements_for_terms(term_conditions, attributes_operator, terms_operator)
    statements =
      term_conditions.map do |term_condition|
        build_statements_for_term(term_condition).
          join(" #{attributes_operator} ")
      end.
        join(") #{terms_operator} (")
    "(#{statements})"
  end

  def build_statements_for_term(term_condition)
    term_condition[0].map do |attribute|
      "#{attribute} LIKE ?"
    end
  end

  def build_bind_variables_for_terms(term_conditions)
    term_conditions.map do |term_condition|
      build_bind_variables_for_term(term_condition)
    end.
      flatten
  end

  def build_bind_variables_for_term(term_condition)
    bind_variables = []
    term_condition[0].size.times do |_count|
      bind_variables << "%#{term_condition[1]}%"
    end
    bind_variables
  end

  def normalize_terms(terms)
    if terms.is_a?(Array)
      terms
    else
      terms_for_string(terms)
    end
  end

  def terms_for_string(terms)
    regex = /("[^"]+"|[^"\s]+)/
    matches = terms.scan(regex)
    matches.flatten.compact.map do |match|
      match.remove(/\A"/).remove(/"\z/)
    end
  end

  def build_term_conditions(terms, attributes)
    terms.map do |term|
      [
        attributes,
        term
      ]
    end
  end

end
