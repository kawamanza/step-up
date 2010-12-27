require 'spec_helper'

describe StepUp::Parser::VersionMask do
  before do
    lambda {
      @mask = StepUp::Parser::VersionMask.new("v0.0.0.9.9.rc9")
    }.should_not raise_error ArgumentError
  end
  
  it "should be able to provide a blank mask" do
    @mask.blank.should be == "v0.0.0"
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


  context "increasing version" do
    before do
      @mask.stubs(:version_levels).returns(%w[major minor tiny patch build rc])
    end
    it "should increase by levels" do
      version = "v2.3.1.6.4.rc5"
      @mask.increase_version(version, "major").should be == "v3.0.0"
      @mask.increase_version(version, "minor").should be == "v2.4.0"
      @mask.increase_version(version, "tiny").should be == "v2.3.2"
      @mask.increase_version(version, "patch").should be == "v2.3.1.7"
      @mask.increase_version(version, "build").should be == "v2.3.1.6.5"
      @mask.increase_version(version, "rc").should be == "v2.3.1.6.4.rc6"
    end
  end


  context "getting Regepx" do
    it "should get regexp string" do
      @mask.should respond_to(:to_regex)
      @mask.to_regex.should be == "(?:v(\\d+))(?:\\.(\\d+))(?:\\.(\\d+))(?:\\.(\\d+))?(?:\\.(\\d+))?(?:\\.rc(\\d+))?"
    end
    it "should parse message" do
      re = /^available on (?:#{ @mask.to_regex })$/
      "available on v0.1.0".should =~ re
      "available on v0.1.0.rc3".should =~ re
      "available on v0.1.0.1.rc3".should =~ re
      "available on v0.1.0.2.4.rc3".should =~ re
    end
    it "should not parse message" do
      re = /^available on (?:#{ @mask.to_regex })$/
      "available on v0.1".should_not =~ re
      "now in v0.1.0".should_not =~ re
      "available on v0.1.0 tag".should_not =~ re
    end
  end
end
