# MP3Sorter
# A (not so) poor implementation of mp3sorter in Ruby, with additional features.
# See the original C version of mp3sorter: https://github.com/speedismeh/mp3sorter/blob/master/c-mp3sorter/mp3sorter.c
# Author: Shivam Mistry (speedismeh)


require 'fileutils'

class ID3v2

  attr_accessor :major
  attr_accessor :minor
  attr_accessor :flags
  attr_accessor :tag_size
  attr_accessor :fp

  class Frame
    attr_accessor :name
    attr_accessor :size
    attr_accessor :flags
    attr_accessor :data

    def initialize(fp)
      header = fp.read(10)
      @name = header[0..3].to_s.strip
      @size = header[4..7].unpack("N")[0]
      @flags= header[8..9]
      @data = fp.read(@size)
    end

  end

  def initialize(fp)
    @fp = fp
    tag = @fp.read(3)
    if tag == 'ID3'
      @major = @fp.readbyte
      @minor = @fp.readbyte
      @flags = @fp.readbyte
      @tag_size = @fp.read(4).unpack('N')[0]
      if @major >= 3
        if (@flags & 64) != 0
          size = @fp.read(4).unpack('N')[0]
          @fp.seek(size, IO::SEEK_CUR)
        end
      else
        raise "ID3v2.#{@major}.#{@minor} is not supported"
      end

    end
  end


  def next
    if @fp.pos - 10 < @tag_size
      return Frame.new(@fp)
    end
  end

  def has_next?
    return @fp.pos - 10 < @tag_size
  end

end


def sort_v2_v2(f_path, dest_dir)
  if File.file?(f_path)
    fp = File.new(f_path, 'rb')
    begin
      id3 = ID3v2.new(fp)
      puts "ID3v2.#{id3.major}.#{id3.minor} for #{f_path}"
      title = ''
      artist = ''
      album = ''
      trackNo = ''
      while id3.has_next? do
        frame = id3.next
        #puts "Frame name: #{frame.name}"
        if (frame.name == 'TPE1') or (frame.name == 'TP1')
          artist = frame.data.to_s.strip.gsub("\0", '').gsub('/', '_')
        elsif frame.name == 'TALB' or frame.name == 'TAL'
          album = frame.data.to_s.strip.gsub("\0", '').gsub('/', '_')
        elsif frame.name == 'TIT1'or frame.name == 'TT2'
          title = frame.data.to_s.strip.gsub("\0", '').gsub('/', '_')
        elsif frame.name == 'TRCK' or frame.name == 'TRK'
          trackNo = frame.data.to_s.strip.gsub("\0", '')
          if pos = trackNo.to_s.index('/') > 0
            trackNo = trackNo.partition('/').first
          end
        end

      end
      fp.close
      puts "track number: #{trackNo} title: #{title}, artist: #{artist}, album: #{album}"
      dir = File.join(dest_dir, artist)
      dir = File.join(dir, album)
      FileUtils.mkdir_p(dir) unless File.exists? dir
      dir = File.join(dir, ('%02d - ' % trackNo.to_i + title + ".mp3"))
      begin
        File.rename(f_path, dir)
      rescue SystemCallError
        puts "Renaming #{f_path} failed, trying to copy..."
        fp = File.new(f_path, 'r')
        fw = File.new(dir, "w")
        while (c = fp.getc) != NIL do
          fw.putc c
        end
        fw.close
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace.join("\n")
    end

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
      fp.seek(32, IO::SEEK_CUR)
      hasNo = fp.readbyte
      trackNo = hasNo == 0 ? fp.readbyte : -1
      printf(hasNo == 0 ? "%s - %s on %s, track no: %d\n" : "%s - %s on %s\n", title, artist, album, trackNo.to_i)
    else
      fp.close
      sort_v2_v2 f_path, dest_dir
      return;
    end
    fp.close
    dir = File.join(dest_dir, artist)
    dir = File.join(dir, album)
    FileUtils.mkdir_p(dir) unless File.exists? dir
    dir = trackNo == -1 ? File.join(dir, title + '.mp3') : File.join(dir, ('%02d - ' % trackNo.to_i + title + '.mp3'))
    begin
      File.rename(f_path, dir)
    rescue SystemCallError
      puts "Renaming #{f_path} failed, trying to copy..."
      fp = File.new(f_path, 'r')
      fw = File.new(dir, 'w')
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

