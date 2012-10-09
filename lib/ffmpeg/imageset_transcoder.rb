module FFMPEG
  class ImagesetTranscoder < Transcoder
    
    # ffmpeg <  0.8: frame=  413 fps= 48 q=31.0 size=    2139kB time=16.52 bitrate=1060.6kbits/s
    # ffmpeg >= 0.8: frame= 4855 fps= 46 q=31.0 size=   45306kB time=00:02:42.28 bitrate=2287.0kbits/
    def run
      command = "#{FFMPEG.ffmpeg_binary} -y #{@raw_options} -i #{Shellwords.escape(@movie.path)} #{Shellwords.escape(@output_file)}"
      FFMPEG.logger.info("Running transcoding...\n#{command}\n")
      output = ""
      last_output = nil
      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        begin
          yield(0.0) if block_given?
          next_line = Proc.new do |line|
            fix_encoding(line)
            output << line
            # if line.include?("time=")
            #   if line =~ /time=(\d+):(\d+):(\d+.\d+)/ # ffmpeg 0.8 and above style
            #     time = ($1.to_i * 3600) + ($2.to_i * 60) + $3.to_f
            #   elsif line =~ /time=(\d+.\d+)/ # ffmpeg 0.7 and below style
            #     time = $1.to_f
            #   else # better make sure it wont blow up in case of unexpected output
            #     time = 0.0
            #   end
            #   progress = time / @movie.duration
            #   yield(progress) if block_given?
            # end
            if line =~ /Unsupported codec/
              FFMPEG.logger.error "Failed encoding...\nCommand\n#{command}\nOutput\n#{output}\n"
              raise "Failed encoding: #{line}"
            end
          end
          
          if @@timeout
            stderr.each_with_timeout(wait_thr.pid, @@timeout, "r", &next_line)
          else
            stderr.each("r", &next_line)
          end
            
        rescue Timeout::Error => e
          FFMPEG.logger.error "Process hung...\nCommand\n#{command}\nOutput\n#{output}\n"
          raise FFMPEG::Error, "Process hung. Full output: #{output}"
        end
      end

      if encoding_succeeded?
        yield(1.0) if block_given?
        FFMPEG.logger.info "Transcoding of #{@movie.path} to #{@output_file} succeeded\n"
      else
        errors = "Errors: #{@errors.join(", ")}. "
        FFMPEG.logger.error "Failed encoding...\n#{command}\n\n#{output}\n#{errors}\n"
        raise FFMPEG::Error, "Failed encoding.#{errors}Full output: #{output}"
      end
      
      encoded
    end
    
  end
end
