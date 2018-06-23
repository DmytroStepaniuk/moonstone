module Moonstone::Api::Controller
  AUTHORIZATION_TOKEN_KEY              = "token="
  AUTHORIZATION_TOKEN_REGEX            = /^(Token|Bearer)\s+/
  AUTHORIZATION_PAIR_DELIMITERS        = /(?:,|;|\t+)/
  AUTHORIZATION_SPLIT_RAW_PARAMS       = /=(.+)?/
  AUTHORIZATION_GSUB_PARAMS_ARRAY_FROM = /^"|"$/

  #
  # Parse `Authorization` header, return token and options in `Rails`-style
  #
  def authorization_token_and_options
    _raw_params = request.headers["Authorization"].sub(AUTHORIZATION_TOKEN_REGEX, "").split(/\s*#{ AUTHORIZATION_PAIR_DELIMITERS }\s*/)

     if !( _raw_params.first =~ %r{\A#{ AUTHORIZATION_TOKEN_KEY }} )
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

  #
  # => Rails-inspired errors hash
  #
  def decorated_errors_of(resource)
    resource_errors = {} of String => Array(String)

    resource.errors.each do |error|
      #
      # => Array(Granite::Error)
      #
      if error.responds_to?(:field)
        resource_errors[error.field.to_s] ||= [] of String
        resource_errors[error.field.to_s].push error.message.to_s
      #
      # => Accord::ErrorList
      #
      elsif error.responds_to?(:field)
        resource_errors[error.attr.to_s] ||= [] of String
        resource_errors[error.attr.to_s].push error.message.to_s
      else
        raise "Currently we support only `Accord::ErrorList` and `Array(Granite::Error)`"
      end
    end

    {
      errors: resource_errors,
    }
  end
end
