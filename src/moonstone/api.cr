module Moonstone::Api
  TOKEN_KEY              = "token="
  TOKEN_REGEX            = /^(Token|Bearer)\s+/
  AUTHN_PAIR_DELIMITERS  = /(?:,|;|\t+)/

  SPLIT_RAW_PARAMS       = /=(.+)?/
  GSUB_PARAMS_ARRAY_FROM = /^"|"$/

  def authorization_token_and_options
    _raw_params = request.headers["Authorization"].sub(TOKEN_REGEX, "").split(/\s*#{ AUTHN_PAIR_DELIMITERS }\s*/)

    _raw_params[0] = "#{TOKEN_KEY}#{_raw_params.first}" if !(_raw_params.first =~ /\Atoken=/ )

    params_array_from = _raw_params.map { |param| param.split SPLIT_RAW_PARAMS }

    rewrite_param_values = params_array_from.map { |param| (param[1] || "".dup).gsub GSUB_PARAMS_ARRAY_FROM, "" }

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
