require 'spec_helper'

describe LastVersion::Parser::VersionMask do
  before do
    lambda {
      @mask = LastVersion::Parser::VersionMask.new("v0.0.0.9.9.rc9")
    }.should_not raise_error ArgumentError
  end


  context "parsing" do
    it "should parse" do
      @mask.parse("v0.1.0.rc3").should be == [0, 1, 0, 0, 0, 3]
      @mask.parse("v0.1.0").should be == [0, 1, 0, 0, 0, 0]
      @mask.parse("v0.1.4.5.rc3").should be == [0, 1, 4, 5, 0, 3]
    end
    it "should not parse" do
      @mask.parse("v0.1.rc3").should be_nil
      @mask.parse("note-v0.1.0-1").should be_nil
    end
  end


  context "formatting" do
    it "should format" do
      @mask.format([0, 1, 0, 0, 0, 3]).should be == "v0.1.0.rc3"
      @mask.format([0, 1, 0, 0, 0, 0]).should be == "v0.1.0"
      @mask.format([0, 1, 4, 5, 0, 3]).should be == "v0.1.4.5.rc3"
    end
    it "should not format" do
      lambda {@mask.format([0, 1, 0, 0, 3])}.should raise_error ArgumentError
      lambda {@mask.format([0, 1, 0, 0, 0, 0, 0])}.should raise_error ArgumentError
    end
  end
end
