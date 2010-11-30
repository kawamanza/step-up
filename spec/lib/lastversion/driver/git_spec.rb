require 'spec_helper'

describe LastVersion::Driver::Git do
  before do
    @driver = LastVersion::Driver::Git.new
  end


  context 'fetching information' do
    it 'should get all commits from history log' do
      @driver.should respond_to :history_log
      @driver.history_log("f4cfcc2").should == ["f4cfcc2c8b1f7edb1b7817b4e8a9063d21db089b", "2fb8a3281fb6777405aadcd699adb852b615a3e4", "d7b0fa26ca547b963569d7a82afd7d7ca11b71ae", "8b38f7c842496fd50b4e1b7ca5e883940b9cbf83", "f76c8d7bf64678963aeef84009be54f1819e3389", "8299243c7dac8f27c3572424a348a7f83ef0ce28", "570fe2e6e7f0b06140ae109e50a1e86628819493", "cdd4d5aa885b22136f4a08c1b35076f888f9536e", "72174c160b50ec73a8f67c8150e0dcd976857411", "b2da007b4fb35e0274858c14a83a836852d055a4", "4f0e7e0f6b3df2d49ed0029ed01998bf2102b28f"]
      @driver.history_log("f4cfcc2", 3).should == ["f4cfcc2c8b1f7edb1b7817b4e8a9063d21db089b", "2fb8a3281fb6777405aadcd699adb852b615a3e4", "d7b0fa26ca547b963569d7a82afd7d7ca11b71ae"]
    end
  end


  context 'fetching tags' do
    it "should get tags sorted" do
      tags = %w[note-v0.2.0-1 v0.1.0 v0.1.1 v0.1.2 v0.1.1.rc3]
      @driver.stubs(:all_tags).returns(tags)
      @driver.all_version_tags.should be == %w[v0.1.2 v0.1.1.rc3 v0.1.1 v0.1.0]
    end
  end
end
