namespace :vcr do
  desc 'Clear VCR maps'
  task :clear_maps do
    sh "rm #{ Rails.root.join('spec', 'vcr') }/**/map"
  end

  desc 'Indentify recordings not included in the maps'
  task :unused do
    puts(*unused())
    $stderr.puts 'No unused recordings!' if unused.length == 0
  end

  desc 'Remove unused recordings'
  task :remove_unused do
    unused().each do |f|
      puts(f)
      FileUtils.rm(f)
    end
  end
end

def unused()
  vcr_dir = Dir.new(Rails.root.join('spec', 'vcr'))
  unused = []
  vcr_dir.children.each do |command|
    begin
      rec_dir = Pathname.new(vcr_dir).join(command)
      map_file = rec_dir.join('map')
      digests = File.new(map_file).readlines.collect do |map_line|
        map_line.split("\t").first
      end
      filenames = Dir.new(rec_dir).children
      filenames.delete('map')
      (filenames - digests).each { |f| unused.push(rec_dir.join(f)) }
    rescue
      next
    end
  end
  return unused
end
