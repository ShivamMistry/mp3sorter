# MP3Sorter
# A poor implementation of mp3sorter in Ruby.
# See mp3sorter: http://paste.strictfp.com/27069
# Author: S. Mistry (speed)


def sort_v2(f_path, dest_dir)
	if File.file?(f_path)
		fp = File.new(f_path, "rb")
		tag = fp.read(3)
		if tag == 'ID3'
			puts 'ID3v2 detected for ' + f_path
			major = fp.readbyte
			minor = fp.readbyte
			flags = fp.readbyte 
			tag_size = fp.read(4).unpack("N")[0]
			if major >= 3
				if (flags & 64) != 0 # check if it has an extended header
					size = fp.read(4).unpack("N")[0] # N is unsigned 32bit BE integer
					fp.seek(size, IO::SEEK_CUR)
				end
			else
				puts "The ID3 tag on #{f_path} is obsolete and not supported: ID3v2.#{major}.#{minor}"
				#return;
			end
			title = ''
			artist = ''
			album = ''
			puts "ID3v2.#{major.to_s}.#{minor.to_s}"
			puts "Size of header is " + tag_size.to_s
			while ((title == '' || artist == '' || album == '') && (fp.pos-10 < (tag_size))) do
				if major >= 3
					header = fp.read(10)
					name = header[0..3]
					size = header[4..7].unpack("N")[0]
					flags= header[8..9]
					printf "size: %d name: %s\n",size, name
					if name == "TPE1"
						artist = fp.read(size)
					elsif name == "TALB"
						album = fp.read(size)
					elsif name == "TIT2"
						title = fp.read(size)
						encoding = ""
						if title[0]==0
							encoding = "ASCII"
						elsif title[0] == 1
							encoding = "UTF-16"
						elsif title[0] == 3
							encoding = "UTF-8"
						end
						puts title[1..title.length-1].encode(encoding)
					else
						fp.seek(size, IO::SEEK_CUR)
					end
				else
					header = fp.read(6)
					name = header[0..2]
					puts name
					tsize = [0]
					header[3..5].each_byte{|b| tsize << b}
					size = tsize.to_s.unpack("N")[0]
					puts size.to_i
					fp.seek(size, IO::SEEK_CUR)
				end
			end
			printf "title: %s, artist %s, album: %s\n", title, artist, album
		else
			puts "Tag format for #{f_path} not supported"
		end
		fp.close
	end
end

def sort(f_path, dest_dir)
	if File.file?(f_path)
		fp = File.new(f_path, "r")
		fp.seek(-128, IO::SEEK_END)
		tag = fp.read(3)
		if tag == 'TAG'
			puts 'ID3v1 detected for ' + f_path
			title = fp.read(30).strip.delete File::Separator
			artist = fp.read(30).strip.delete File::Separator
			album = fp.read(30).strip.delete File::Separator
			printf("%s - %s on %s\n", title, artist, album)
		else
			fp.close
			sort_v2 f_path, dest_dir
			return;
		end
		fp.close
		dir = File.join(dest_dir, artist)
		if !File.exists? dir
			Dir.mkdir dir
		end
		dir = File.join(dir, album)
		if !File.exists? dir
			Dir.mkdir dir
		end
		dir = File.join(dir, title + ".mp3")
		begin
			File.rename(f_path, dir)
		rescue SystemCallError
			puts "Renaming #{f_path} failed, trying to copy..."
			fp = File.new(f_path, 'r')
			fw = File.new(dir, "w")
			while (c = fp.getc) != NIL do
				fw.putc c
			end
			fp.close
			fw.close
		end
	end
end

# main code
argc = ARGV.length
if argc == 0
	puts "Usage: mp3sorter  (directory|file)... out-dir"
else 
	if argc >= 1
		dir = argc == 1 ? Dir.pwd : ARGV[argc - 1]
		puts 'Outputting to... ' + dir
		(argc == 1 ? argc : argc - 1).times { |i|
			path = ARGV[i]
			puts 'Processing... ' + path
			if File.directory? path
				Dir.foreach(path) do |item| 
					if item.to_s =~ /\.mp3$/
						puts "Found MP3 file \"#{item}\", processing..."
						sort(File.join(path, item), dir)
					end
				end
			else
				sort(path, dir)
			end
		}
	end
end
