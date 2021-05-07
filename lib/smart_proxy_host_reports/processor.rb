class Processor
  def self.new_processor(format, data)
    case format
    when 'puppet'
      PuppetProcessor.new(data)
    else
      NotImplementedError.new
    end
  end
end