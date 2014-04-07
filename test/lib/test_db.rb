require File.expand_path('../../test_helper', __FILE__)
require 'tempfile'

describe StarScope::DB do

  before do
    @db = StarScope::DB.new(false)
  end

  it "must raise on invalid tables" do
    proc {@db.dump_table(:foo)}.must_raise StarScope::DB::NoTableError
  end

  it "must correctly add paths" do
    paths = [GOLANG_SAMPLE, 'test/files']
    @db.add_paths(paths)
    @db.instance_eval('@meta[:paths]').must_equal paths
    files = @db.instance_eval('@meta[:files]').map{|x|x[:name]}
    files.must_include GOLANG_SAMPLE
    files.must_include RUBY_SAMPLE
  end

  it "must correctly pick up new files in old paths" do
    @db.instance_eval('@meta[:paths] = ["test/files"]')
    @db.update
    files = @db.instance_eval('@meta[:files]').map{|x|x[:name]}
    files.must_include GOLANG_SAMPLE
    files.must_include RUBY_SAMPLE
  end

  it "must correctly remove old files in existing paths" do
    @db.instance_eval('@meta[:paths] = ["test/files"]')
    @db.instance_eval('@meta[:files] = [{:name=>"test/files/foo", :last_update=>1}]')
    @db.instance_eval('@meta[:files]').map{|x|x[:name]}.must_include 'test/files/foo'
    @db.update
    @db.instance_eval('@meta[:files]').map{|x|x[:name]}.wont_include 'test/files/foo'
  end

  it "must correctly load an old DB file" do
    @db.load('test/files/db_old.json.gz')
    @db.instance_eval('@meta[:paths]').must_equal ['test/files']
    files = @db.instance_eval('@meta[:files]').map{|x|x[:name]}
    files.must_include GOLANG_SAMPLE
    files.must_include RUBY_SAMPLE
  end

  it "must correctly round-trip a database" do
    file = Tempfile.new('starscope_test')
    begin
      @db.add_paths(['test/files'])
      @db.save(file.path)
      StarScope::DB.new(false).load(file.path)
    ensure
      file.close
      file.unlink
    end
  end

  it "must correctly run queries" do
    @db.add_paths(['test/files'])
    @db.query(:calls, "abc")
    @db.query(:defs, "xyz")
  end

end
