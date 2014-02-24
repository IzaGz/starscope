require File.expand_path('../../test_helper', __FILE__)

class TestGolang < Minitest::Test
  def setup
    @db = {}
    StarScope::Lang::Go.extract(GOLANG_SAMPLE) do |tbl, key, args|
      key = key.to_sym
      @db[tbl] ||= {}
      @db[tbl][key] ||= []
      @db[tbl][key] << args
    end
  end

  def test_recognition
    assert StarScope::Lang::Go.match_file(GOLANG_SAMPLE)
    refute StarScope::Lang::Go.match_file(RUBY_SAMPLE)
    refute StarScope::Lang::Go.match_file(EMPTY_FILE)
  end

  def test_defs
    assert @db.keys.include? :defs
    defs = @db[:defs].keys
    assert defs.include? :a
    assert defs.include? :b
    assert defs.include? :c
    assert defs.include? :ttt
    assert defs.include? :main
    assert defs.include? :v1
    assert defs.include? :v2
    assert defs.include? :Sunday
    assert defs.include? :Monday
  end

  def test_function_ends
    assert @db.keys.include? :end
    ends = @db[:end]
    assert ends.keys.count == 1
    assert ends.values.first.count == 5
  end

  def test_function_calls
    assert @db.keys.include? :calls
    calls = @db[:calls]
    assert calls.keys.include? :a
    assert calls.keys.include? :b
    assert calls.keys.include? :c
    assert calls.keys.include? :ttt
    assert calls[:a].count == 3
    assert calls[:b].count == 4
    assert calls[:c].count == 2
    assert calls[:ttt].count == 2
  end

  def test_variable_assigns
    assert @db.keys.include? :assigns
    assigns = @db[:assigns]
    assert assigns.keys.include? :x
    assert assigns.keys.include? :y
    assert assigns.keys.include? :z
    assert assigns.keys.include? :n
    assert assigns.keys.include? :m
    assert assigns[:x].count == 2
    assert assigns[:y].count == 1
    assert assigns[:z].count == 1
    assert assigns[:n].count == 1
    assert assigns[:m].count == 2
  end
end
