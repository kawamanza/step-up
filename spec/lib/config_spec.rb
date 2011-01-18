require 'spec_helper'

describe "StepUp::CONFIG" do
  before do
    @c = StepUp::CONFIG
  end

  context "getting an attribute" do
    it "that does not exists" do
      lambda { @c.notes2 }.should raise_error(NoMethodError)
    end
    it "that exists" do
      @c.should_not respond_to(:notes)
      @c.notes.should be_kind_of(Hash)
      @c.notes.should be_kind_of(StepUp::ConfigExt)
      @c.notes.should_not respond_to(:sections)
      @c.notes.sections.should be_kind_of(Array)
      @c.notes.should_not respond_to(:after_versioned)
      @c.notes.after_versioned.should be_kind_of(Hash)
      @c.notes.after_versioned.should be_kind_of(StepUp::ConfigExt)
      @c.notes.after_versioned.should_not respond_to(:section)
      @c.notes.after_versioned.section.should be_kind_of(String)
    end
  end


  context "getting notes sections" do
    it "by names" do
      @c.notes_sections.should be_kind_of(Array)
      @c.notes_sections.should respond_to(:names)
      @c.notes_sections.names.should be == %w[changes bugfixes features deploy_steps]
    end

    it "by prefixes" do
      @c.notes_sections.should be_kind_of(Array)
      @c.notes_sections.should respond_to(:prefixes)
      @c.notes_sections.prefixes.should be == ["change: ", "bugfix: ", "feature: ", "deploy_step: "]
    end

    it "by labels" do
      @c.notes_sections.should be_kind_of(Array)
      @c.notes_sections.should respond_to(:labels)
      @c.notes_sections.labels.should be == ["Changes:", "Bugfixes:", "Features:", "Deploy steps:"]
    end
  end
end
