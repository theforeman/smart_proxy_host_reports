# TODO remove me
class Spool
  class << self
    def initialize
      @client = SpooledHttpClient.new
      @client.start_processing
    end

    def spool(filename, data)
      @client.spool(filename, data)
    end
  end
end
