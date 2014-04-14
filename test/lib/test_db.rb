require File.expand_path('../../test_helper', __FILE__)
require 'tempfile'

describe StarScope::DB do

  def validate(db)
    files = db.instance_eval('@meta[:files]')
    files.keys.must_include GOLANG_SAMPLE
    files.keys.must_include RUBY_SAMPLE
    files[GOLANG_SAMPLE][:last_updated].must_equal File.mtime(GOLANG_SAMPLE).to_i
    files[RUBY_SAMPLE][:last_updated].must_equal File.mtime(RUBY_SAMPLE).to_i

    tbls = db.instance_eval('@tables')
    defs = tbls[:defs].map {|x| x[:name][-1]}
    assert defs.include? :DB
    assert defs.include? :NoTableError
    assert defs.include? :load
    assert defs.include? :update
    assert defs.include? :files_from_path
  end

  before do
    @db = StarScope::DB.new(false, false)
  end

  it "must raise on invalid tables" do
    proc {@db.dump_table(:foo)}.must_raise StarScope::DB::NoTableError
  end

  it "must correctly add paths" do
    paths = [GOLANG_SAMPLE, 'test/files/**/*']
    @db.add_paths(paths)
    @db.instance_eval('@meta[:paths]').must_equal paths
    validate(@db)
  end

  it "must correctly pick up new files in old paths" do
    @db.instance_eval('@meta[:paths] = ["test/files/**/*"]')
    @db.update
    validate(@db)
  end

  it "must correctly remove old files in existing paths" do
    @db.instance_eval('@meta[:paths] = ["test/files"]')
    @db.instance_eval('@meta[:files] = {"test/files/foo" => {:last_update=>1}}')
    @db.instance_eval('@meta[:files]').keys.must_include 'test/files/foo'
    @db.update
    @db.instance_eval('@meta[:files]').keys.wont_include 'test/files/foo'
  end

  it "must correctly load an old DB file" do
    @db.load('test/files/db_old.json.gz')
    @db.instance_eval('@meta[:paths]').must_equal ['test/files/**/*']
    validate(@db)
  end

  it "must correctly round-trip a database" do
    file = Tempfile.new('starscope_test')
    begin
      @db.add_paths(['test/files'])
      @db.save(file.path)
      tmp = StarScope::DB.new(false, false)
      tmp.load(file.path)
      validate(tmp)
    ensure
      file.close
      file.unlink
    end
  end

  it "must correctly export to ctags" do
    file = Tempfile.new('starscope_test')
    begin
      @db.add_paths(['test/files'])
      @db.export_ctags(file)
      file.rewind
      lines = file.lines.to_a
      lines.must_include "NoTableError\ttest/files/sample_ruby.rb\t/^  class NoTableError < StandardError; end$/;\"\tkind:c\n"
    ensure
      file.close
      file.unlink
    end
  end

  it "must correctly export to cscope" do
    file = Tempfile.new('starscope_test')
    begin
      @db.add_paths(['test/files'])
      @db.export_cscope(file)
      file.rewind
      lines = file.lines.to_a
      lines.must_include "\t@test/files/sample_golang.go\n"
      lines.must_include "\tgSunday\n"
      lines.must_include "\t`add_file\n"
    ensure
      file.close
      file.unlink
    end
  end

  it "must correctly run queries" do
    @db.add_paths(['test/files'])
    @db.query(:calls, "abc").must_equal []
    @db.query(:defs, "xyz").must_equal []
    @db.query(:calls, "new").length.must_equal 5
  end

end
