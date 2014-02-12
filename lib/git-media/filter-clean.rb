require 'digest/sha1'
require 'fileutils'
require 'tempfile'

module GitMedia
  module FilterClean

    def self.run!(filename)
      # determine and initialize our media buffer directory
      media_buffer = GitMedia.get_media_buffer


	  STDOUT.binmode


	  if filename == nil
		filename = "(unknown)"
	  end

		
	  #STDERR.puts "clean : "+filename+" : "+filename


	  sha = STDIN.readpartial(41)
      if STDIN.eof && sha.length == 41 && sha.match(/^[0-9a-fA-F]+$/) != nil
		STDOUT.puts(sha)		
		STDERR.puts ('Media clean detected hash '+sha[0,8]+'.. in '+filename)
	  else

        hashfunc = Digest::SHA1.new
		hashfunc.update(sha)

        tempfile = Tempfile.new('media')
	    tempfile.binmode

		# read in buffered chunks of the data
		#  calculating the SHA and copying to a tempfile
		while data = STDIN.read(4096)
			hashfunc.update(data)
			tempfile.write(data)
		end
		tempfile.close

		# calculate and print the SHA of the data
		STDOUT.print hx = hashfunc.hexdigest 
		STDOUT.write("\n")

		
		
		# move the tempfile to our media buffer area
		media_file = File.join(media_buffer, hx)

		# STDERR.puts ('clean: ' + filename + ' ('+hx[0,8]+')')

		if !File.exists?(media_file)

		
			@push = GitMedia.get_push_transport

			if @push.needs_push(hx)
				STDERR.puts('Skipping media upload: '+hx[0,8])
			else
				if @push.push(hx)
					STDERR.puts('Uploaded media ' + hx[0,8] + '.. '+filename)
				else
					STDERR.puts('Failed to upload media ' + hx[0,8] + '.. '+filename)
					exit(1)
				end
			end
			
			FileUtils.mv(tempfile.path, media_file)
			File.chmod(0640, media_file)

			STDERR.puts('Saved media ' + hx[0,8] + '.. '+ filename)
		end
	  end



    
    end

  end
end
