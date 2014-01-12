require 'date'
require 'zlib'

LANGS = [
  StarScope::Lang::Go,
  StarScope::Lang::Ruby
]

class StarScope::DB

  PBAR_FORMAT = '%t: %c/%C %E ||%b>%i||'

  class NoTableError < StandardError; end

  def initialize(progress)
    @progress = progress
    @paths = []
    @files = {}
    @tables = {}
  end

  def load(file)
    File.open(file, 'r') do |file|
      Zlib::GzipReader.wrap(file) do |file|
        format = file.gets.to_i
        if format == DB_FORMAT
          @paths  = Oj.load(file.gets)
          @files  = Oj.load(file.gets)
          @tables = Oj.load(file.gets, symbol_keys: true)
        elsif format <= 2
          # Old format (pre-json), so read the directories segment then rebuild
          len = file.gets.to_i
          add_paths(Marshal::load(file.read(len)))
        elsif format < DB_FORMAT
          # Old format, so read the directories segment then rebuild
          add_paths(Oj.load(file.gets))
        elsif format > DB_FORMAT
          raise UnknownDBFormatError
        end
      end
    end
  end

  def save(file)
    File.open(file, 'w') do |file|
      Zlib::GzipWriter.wrap(file) do |file|
        file.puts DB_FORMAT
        file.puts Oj.dump @paths
        file.puts Oj.dump @files
        file.puts Oj.dump @tables
      end
    end
  end

  def add_paths(paths)
    paths -= @paths
    return if paths.empty?
    @paths += paths
    files = paths.map {|p| self.class.files_from_path(p)}.flatten
    return if files.empty?
    if @progress
      pbar = ProgressBar.create(title: "Building", total: files.length, format: PBAR_FORMAT, length: 80)
    end
    files.each do |f|
      add_file(f)
      pbar.increment if @progress
    end
  end

  def update
    new_files = (@paths.map {|p| self.class.files_from_path(p)}.flatten) - @files.keys
    if @progress
      pbar = ProgressBar.create(title: "Updating", total: new_files.length + @files.length, format: PBAR_FORMAT, length: 80)
    end
    changed = @files.keys.map do |f|
      changed = update_file(f)
      pbar.increment if @progress
      changed
    end
    new_files.each do |f|
      add_file(f)
      pbar.increment if @progress
    end
    changed.any? || !new_files.empty?
  end

  def summary
    ret = {}

    @tables.each_key do |key|
      ret[key] = @tables[key].keys.count
    end

    ret
  end

  private

  def self.files_from_path(path)
    if File.file?(path)
      [path]
    elsif File.directory?(path)
      Dir[File.join(path, "**", "*")].select {|p| File.file?(p)}
    else
      []
    end
  end

  def db_by_line()
    tmpdb = {}
    @tables.each do |tbl, vals|
      vals.each do |key, val|
        val.each do |entry|
          if entry[:line_no]
            tmpdb[entry[:file]] ||= {}
            tmpdb[entry[:file]][entry[:line_no]] ||= []
            tmpdb[entry[:file]][entry[:line_no]] << {tbl: tbl, key: key, entry: entry}
          end
        end
      end
    end
    return tmpdb
  end

  def add_file(file)
    return if not File.file? file

    @files[file] = File.mtime(file).to_s

    LANGS.each do |lang|
      next if not lang.match_file file
      lang.extract file do |tbl, key, args|
        key = key.to_sym
        @tables[tbl] ||= {}
        @tables[tbl][key] ||= []
        @tables[tbl][key] << StarScope::Datum.build(file, key, args)
      end
    end
  end

  def remove_file(file)
    @files.delete(file)
    @tables.each do |name, tbl|
      tbl.each do |key, val|
        val.delete_if {|dat| dat[:file] == file}
      end
    end
  end

  def update_file(file)
    if not File.exists?(file) or not File.file?(file)
      remove_file(file)
      true
    elsif DateTime.parse(@files[file]).to_time < File.mtime(file)
      remove_file(file)
      add_file(file)
      true
    else
      false
    end
  end

end