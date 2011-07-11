require File.join(File.dirname(__FILE__), 'helper.rb')
require File.join(File.dirname(__FILE__), '../lib/cell_filter.rb')

describe CellFilter do
  before(:each) do
    @row_filter = CellFilter.new
  end
  context "for all filtering requests" do
    it "should raise an error if the input filter is an invalid regex" do
      lambda { @row_filter.accept("some value", "invalid[regex") }.should raise_error(RuntimeError)
    end
  end
  context "when filtering" do
    describe "a single value" do
      it "should return true if the filter matches the single value" do
        @row_filter.accept("something", "ome").should be_true
        @row_filter.accept("something", "^some").should be_true
        @row_filter.accept("something", "[^xyz]").should be_true
      end

      it "should return false if the filter value doesn't match the single value" do
        @row_filter.accept("something", "ted").should be_false
        @row_filter.accept("something", "^rather").should be_false
      end

    end

    describe "a comma separated list of values" do
      it "should return true if the filter matches at least one of the values" do
        @row_filter.accept("something,then,other", "ome").should be_true
        @row_filter.accept("something,then,other", "^then").should be_true
        @row_filter.accept("something,else", "[^xyz]").should be_true
      end

      it "should return false if the filter value doesn't match any of the values" do
        @row_filter.accept("something, then", "ted").should be_false
        @row_filter.accept("something, else", "^rather").should be_false
      end
    end

    describe "a value with a list of comma separated list of filters" do
      it "should return true if all filters matches the value" do
        @row_filter.accept("something", "som,eth,ing").should be_true
      end

      it "should return false if at least one filter doesn't match the value" do
        @row_filter.accept("something", "ted,ome,some.hong").should be_false
        @row_filter.accept("something", "ted,bob,^[^s]").should be_false
      end
    end

    describe "a comma separated list of values with a list of comma separated list of filters" do
      it "should return true if all filters matches some values" do
        @row_filter.accept("deal,rates", "de,ra").should be_true
        @row_filter.accept("something,then", "so,th").should be_true
        @row_filter.accept("something,then,rather", "some").should be_true
        @row_filter.accept("something,then,rather", "her,hen").should be_true
        @row_filter.accept("something,then,rather", "so,hen,ra").should be_true
      end

      it "should return true if all filters matches some values specified as array" do
        @row_filter.accept(["deal", "rates"], "de,ra").should be_true
        @row_filter.accept(["something","then"], "so,th").should be_true
        @row_filter.accept(["something","then","rather"], "some").should be_true
        @row_filter.accept(["something","then","rather"], "her,hen").should be_true
        @row_filter.accept(["something","then","rather"], "so,hen,ra").should be_true
      end
      
      it "should return false if no filters matches any of the value" do
        @row_filter.accept("something,then,rather", "so,hen,rep").should be_false
        @row_filter.accept("something,but,nothing", "ted,bob,^[^nbs]").should be_false
      end
    end
  end

end