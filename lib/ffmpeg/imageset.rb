module FFMPEG
  class Imageset < Movie
    
    def initialize(path)
      @path = path
    end
    
    def transcode(output_file, options = EncodingOptions.new, transcoder_options = {}, &block)
      ImagesetTranscoder.new(self, output_file, options, transcoder_options).run &block
    end
    
  end
end
