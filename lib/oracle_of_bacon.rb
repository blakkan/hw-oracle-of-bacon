require 'byebug'                # optional, may be helpful
require 'open-uri'              # allows open('http://...') to return body
require 'cgi'                   # for escaping URIs
require 'nokogiri'              # XML parser
require 'active_model'          # for validations

class OracleOfBacon

  class InvalidError < RuntimeError ; end
  class NetworkError < RuntimeError ; end
  class InvalidKeyError < RuntimeError ; end

  attr_accessor :from, :to
  attr_reader :api_key, :response, :uri
  
  include ActiveModel::Validations
  validates_presence_of :from
  validates_presence_of :to
  validates_presence_of :api_key
  validate :from_does_not_equal_to

  #
  # custom validator (we ascribe the error to :to)
  #
  def from_does_not_equal_to
    if @from == @to
      errors.add(:to, 'From cannot be the same as To')
    end
  end

  #
  # constructor
  #
  def initialize(api_key='')
    @api_key = api_key
    @from = 'Kevin Bacon'
    @to = 'Kevin Bacon'
    
    # your code here
  end

  def find_connections
    make_uri_from_arguments
    begin
      xml = URI.parse(uri).read
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError => e
      # convert all of these into a generic OracleOfBacon::NetworkError,
      #  but keep the original error message
      raise OracleOfBacon::NetworkError, e.message, e.backtrace  #read about 3rd argument; keeps stacktrace
    end
    
    # your code here: create the OracleOfBacon::Response object
    @response = Response.new(xml)
    
  end

  def make_uri_from_arguments
    # your code here: set the @uri attribute to properly-escaped URI
    #   constructed from the @from, @to, @api_key arguments
    @uri = "http://oracleofbacon.org/cgi-bin/xml?p=#{CGI.escape(@api_key)}&a=#{CGI.escape(@from)}&b=#{CGI.escape(@to)}"

  end
      
  class Response
    attr_reader :type, :data
    # create a Response object from a string of XML markup.
    def initialize(xml)
      @doc = Nokogiri::XML(xml)
      parse_response
    end

    private

    def parse_response
      
      #puts @doc.xpath
      
      if ! @doc.xpath('/error').empty?   # If the error field is not empty, then we send the error message
        parse_error_response
        
      elsif ! @doc.xpath('/link').empty?    # it's a link
        parse_link_response

      elsif !  @doc.xpath('/spellcheck').empty?   #it's a spellcheck
        parse_spellcheck_response

      else
        parse_unknown_response

      # your code here: 'elsif' clauses to handle other responses
      # for responses not matching the 3 basic types, the Response
      # object should have type 'unknown' and data 'unknown response'         
      end
    end
    
    def parse_error_response
      #puts "Its error"
      #should we be raising OracleOfBacon::InvalidKey exception here?
      @type = :error
      @data = 'Unauthorized access'
    end
    
    def parse_link_response
      #puts "its a link"
      @type = :graph
      @data = @doc.xpath('//actor|//movie').map{|x| x.children[0].text}
    end
      
    def parse_spellcheck_response
      #puts "It's spellcheck"
      @type = :spellcheck
      @data = @doc.xpath('//match').map{|x| x.children[0].text}
    end
    
    def parse_unknown_response
      #puts "it's unknown"
      #should we be raising OracleOfBacon::Invalid exception here?
      @type = :unknown
      @data = 'unknown reponse'
    end
  end
end

