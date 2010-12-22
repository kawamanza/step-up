require "spec_helper"

describe StepUp::RangedNotes do
  before do
    @driver = StepUp::Driver::Git.new
  end

  context "checking notes" do
    it "should bring all notes between v0.0.2 and v0.1.0" do
      @notes = StepUp::RangedNotes.new(@driver, "v0.0.2", "v0.1.0")
      @notes.all_notes.should be == [
        [3, "features", 1, "3baad37d5098ad3b09935229e14e617c3ec8b7ee",
         "command line to show notes for the next version (unversioned notes)\n"]
      ]
    end
  end

  context "testing notes" do
    before do
      notes_sections = %w[test_changes test_bugfixes test_features]
      class << notes_sections
        include StepUp::ConfigSectionsExt
      end
      StepUp::CONFIG.stubs(:notes_sections).returns(notes_sections)
    end
    it "should get all detached notes" do
     @notes = StepUp::RangedNotes.new(@driver, nil, "f4cfcc2") 
     @notes.notes.should be == [
       [5, "test_changes", 1, "8299243c7dac8f27c3572424a348a7f83ef0ce28",
        "removing files from gemspec\n  .gitignore\n  lastversion.gemspec\n"],
       [2, "test_bugfixes", 1, "d7b0fa26ca547b963569d7a82afd7d7ca11b71ae",
        "sorting tags according to the mask parser\n"],
       [1, "test_changes", 1, "2fb8a3281fb6777405aadcd699adb852b615a3e4",
        "loading default configuration yaml\n\nloading external configuration yaml\n"]
     ]
    end
  end
end
