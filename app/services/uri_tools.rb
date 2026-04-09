module UriTools
  module_function

  def defragment(uri_string)
    uri = URI.parse(uri_string)
    uri.fragment = nil
    uri.to_s
  end

  def fragment(uri_string)
    URI.parse(uri_string).fragment
  rescue URI::InvalidURIError
    nil
  end
end
