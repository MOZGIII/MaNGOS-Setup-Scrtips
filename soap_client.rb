require 'savon'

class MaNGOS_SOAP_Transport
  def initialize login, password
    @client = Savon::Client.new do
      wsdl.endpoint = "http://127.0.0.1:7878"
      wsdl.namespace = "urn:MaNGOS"
    end
    @client.http.auth.basic(login, password)
  end
  
  def command text
    @client.request(:urn, :execute_command) do |soap|
      soap.body = { :command => text }
    end.to_hash[:execute_command_response][:result]
  end
end




puts MaNGOS_SOAP_Transport.new("MOZGIII", "...").command "help"