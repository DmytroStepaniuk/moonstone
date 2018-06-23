module Moonstone::Api
  AUTHORIZATION_TOKEN_KEY              = "token="
  AUTHORIZATION_TOKEN_REGEX            = /^(Token|Bearer)\s+/
  AUTHORIZATION_PAIR_DELIMITERS        = /(?:,|;|\t+)/
  AUTHORIZATION_SPLIT_RAW_PARAMS       = /=(.+)?/
  AUTHORIZATION_GSUB_PARAMS_ARRAY_FROM = /^"|"$/

  def authorization_token_and_options
    _raw_params = request.headers["Authorization"].sub(AUTHORIZATION_TOKEN_REGEX, "").split(/\s*#{ AUTHORIZATION_PAIR_DELIMITERS }\s*/)

     if not( _raw_params.first =~ %r{\A#{ AUTHORIZATION_TOKEN_KEY }} )
      _raw_params[0] = "#{ AUTHORIZATION_TOKEN_KEY }#{ _raw_params.first }"
    end

    params_array_from = _raw_params.map { |param| param.split AUTHORIZATION_SPLIT_RAW_PARAMS }

    rewrite_param_values = params_array_from.map { |param| (param[1] || "".dup).gsub AUTHORIZATION_GSUB_PARAMS_ARRAY_FROM, "" }

    options_array = params_array_from.map do |param|
      param.map { |param_lvl2| param_lvl2.empty? ? nil : param_lvl2 }.compact
    end

    options = {} of String => String?

    options_array.each do |option|
      options[option.first] = option[1]
    end

    options.reject!("token")

    [rewrite_param_values.first, options]
  end
end
