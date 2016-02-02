controller :meta do

  friendly_name "Meta API"
  description <<-DESC
    The meta API provides you with access to information about the API itself.
  DESC

  action :version do
    description "Return the current software version"
    returns :string, :eg => "v1.2.3"
    action { LlamaCom::VERSION }
  end

end
