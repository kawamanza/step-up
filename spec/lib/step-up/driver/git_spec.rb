require 'spec_helper'

describe StepUp::Driver::Git do
  before do
    @driver = StepUp::Driver::Git.new
  end


  context 'fetching information' do
    it 'should get all commits from history log' do
      @driver.should respond_to :commit_history
      @driver.commit_history("f4cfcc2").should be == ["f4cfcc2c8b1f7edb1b7817b4e8a9063d21db089b", "2fb8a3281fb6777405aadcd699adb852b615a3e4", "d7b0fa26ca547b963569d7a82afd7d7ca11b71ae", "8b38f7c842496fd50b4e1b7ca5e883940b9cbf83", "f76c8d7bf64678963aeef84009be54f1819e3389", "8299243c7dac8f27c3572424a348a7f83ef0ce28", "570fe2e6e7f0b06140ae109e50a1e86628819493", "cdd4d5aa885b22136f4a08c1b35076f888f9536e", "72174c160b50ec73a8f67c8150e0dcd976857411", "b2da007b4fb35e0274858c14a83a836852d055a4", "4f0e7e0f6b3df2d49ed0029ed01998bf2102b28f"]
      @driver.commit_history("f4cfcc2", 3).should be == ["f4cfcc2c8b1f7edb1b7817b4e8a9063d21db089b", "2fb8a3281fb6777405aadcd699adb852b615a3e4", "d7b0fa26ca547b963569d7a82afd7d7ca11b71ae"]
    end
    it "should get commits between a fist commit and a last_commit" do
      @driver.should respond_to :commits_between
      @driver.commits_between("63c8b23", "d133b9e").should be == %w[
        d133b9e3b5be37c8a3332a83e55b410e87d9c3a3
        abd9ee53283de0981fd6fd659af50a2aef4fc5c6
        13de54b5cfdaf05fd4e3c3db57ec9f021362d9c7
        67931ecf42431719b5c67f88ec65cb57e7e11744
      ]
      @driver.commits_between("67931ec", "d133b9e").size.should be == 6
    end
    it "should get all remotes" do
      @driver.fetched_remotes.should be == %w[origin]
    end
  end


  context 'fetching tags' do
    it "should get tags sorted" do
      tags = %w[note-v0.2.0-1 v0.1.0 v0.1.1 v0.1.10 v0.1.2 v0.1.1.rc3]
      @driver.stubs(:all_tags).returns(tags)
      @driver.all_version_tags.should be == %w[v0.1.10 v0.1.2 v0.1.1.rc3 v0.1.1 v0.1.0]
    end

    it "should return last tag visible" do
      @driver.last_version_tag("f4cfcc2").should be == "v0.0.1+"
      @driver.last_version_tag("570fe2e").should be == "v0.0.1"
      @driver.class.last_version("f4cfcc2").should be == "v0.0.1+"
      @driver.class.last_version("570fe2e").should be == "v0.0.1"
    end

    it "should get no tag visible" do
      @driver.last_version_tag("cdd4d5a").should be_nil
    end

    it "should get a blank tag" do
      @driver.mask.blank.should be == "v0.0.0"
      @driver.class.last_version("cdd4d5a").should be == "v0.0.0+"
      @driver.class.last_version("cdd4d5a", true).should be == "v0.0.0+4"
    end

    it "should get last tag visible with the count of commits after it" do
      @driver.last_version_tag("f42bdd1", true).should be == "v0.0.2+22"
      @driver.last_version_tag("13de54b", true).should be == "v0.0.2+22"
      @driver.last_version_tag("d133b9e", true).should be == "v0.0.2+27"
    end
  end


  context "fetching notes" do
    context "from test_* sections" do
      before do
        @driver.stubs(:__notes_sections).returns(%w[test_changes test_bugfixes test_features])
        @objects_with_notes = {"test_changes" => ["8299243c7dac8f27c3572424a348a7f83ef0ce28", "2fb8a3281fb6777405aadcd699adb852b615a3e4"], "test_bugfixes" => ["d7b0fa26ca547b963569d7a82afd7d7ca11b71ae"], "test_features" => []}
        @messages = {"test_changes" => ["removing files from gemspec\n  .gitignore\n  lastversion.gemspec\n", "loading default configuration yaml\n\nloading external configuration yaml\n"], "test_bugfixes" => ["sorting tags according to the mask parser\n"], "test_features" => []}
        @changelog_full = <<-MSG
  - removing files from gemspec (8299243c7dac8f27c3572424a348a7f83ef0ce28)
    - .gitignore
    - lastversion.gemspec
  - loading default configuration yaml (2fb8a3281fb6777405aadcd699adb852b615a3e4)
  - loading external configuration yaml

Test bugfixes:

  - sorting tags according to the mask parser (d7b0fa26ca547b963569d7a82afd7d7ca11b71ae)
MSG
        @changelog = @changelog_full.gsub(/\s\(\w+\)$/, '')
        @all_objects_with_notes = @driver.all_objects_with_notes("f4cfcc2")
      end
      it "should get all objects with notes" do
        @all_objects_with_notes.should be == @objects_with_notes
      end
      it "should get all notes messages" do
        @all_objects_with_notes.should respond_to(:messages)
        @all_objects_with_notes.messages.should be == @messages
      end
      it "should get changelog message" do
        @all_objects_with_notes.should respond_to(:to_changelog)
        @all_objects_with_notes.sections.should be == @driver.__notes_sections
        @all_objects_with_notes.messages.should be == @messages
        @all_objects_with_notes.messages.to_changelog.should be == @changelog
        @all_objects_with_notes.to_changelog.should be == @changelog
        @all_objects_with_notes.messages.to_changelog(:mode => :with_objects).should be == @changelog_full
        @all_objects_with_notes.to_changelog(:mode => :with_objects).should be == @changelog_full
      end
      it "should get unversioned changelog message" do
        @all_objects_with_notes.should be == @objects_with_notes
        object = @objects_with_notes["test_changes"].shift
        @all_objects_with_notes.stubs(:kept_notes).returns([object])
        @all_objects_with_notes.should respond_to(:unversioned_only)
        @all_objects_with_notes.unversioned_only.should be == @objects_with_notes
      end
    end

    context "from default sections" do
      before do
        @all_objects_with_notes = @driver.all_objects_with_notes("v0.1.0")
        @objects_with_notes = {"deploy_steps"=>[], "bugfixes"=>[], "features"=>["3baad37d5098ad3b09935229e14e617c3ec8b7ee"], "changes"=>[]}
      end
      it "should get versioned changelog message" do
        @all_objects_with_notes.should be == @objects_with_notes
        @all_objects_with_notes.available_on("v0.1.0").should be == @objects_with_notes
      end
    end
  end


  context "adding notes" do
    before do
      @steps = <<-STEPS
      git fetch

      git notes --ref=jjj_changes add -m "alteracao na variavel de ambiente \\"\\$ENV\\"" v0.1.0~1

      git push origin refs/notes/jjj_changes
      STEPS
      @steps = @steps.chomp.split(/\n\n/).collect{ |step| step.gsub(/^\s{6}/, '') }
    end
    it "should return steps" do
      @driver.steps_for_add_notes("jjj_changes", "alteracao na variavel de ambiente \"$ENV\"", "v0.1.0~1").should be == @steps
    end
  end


  context "increasing version" do
    before do
      @driver.stubs(:__notes_sections).returns(%w[test_changes test_bugfixes test_features])
      @driver.__notes.after_versioned.stubs(:section).returns("test_versioning")
    end


    context "using 'remove' as after_versioned:strategy" do
      before do
        @driver.__notes.after_versioned.stubs(:strategy).returns("remove")
        @steps = <<-STEPS
        git fetch

        git tag -a -m "  - removing files from gemspec
            - .gitignore
            - lastversion.gemspec
          - loading default configuration yaml
          - loading external configuration yaml
        
        Test bugfixes:
        
          - sorting tags according to the mask parser
        " v0.1.0

        git push --tags

        git notes --ref=test_changes remove 8299243c7dac8f27c3572424a348a7f83ef0ce28

        git notes --ref=test_changes remove 2fb8a3281fb6777405aadcd699adb852b615a3e4

        git push origin refs/notes/test_changes

        git notes --ref=test_bugfixes remove d7b0fa26ca547b963569d7a82afd7d7ca11b71ae

        git push origin refs/notes/test_bugfixes
        STEPS
        @steps = @steps.chomp.split(/\n\n/).collect{ |step| step.gsub(/^\s{8}/, '') }
      end
      it "should return steps" do
        @driver.should respond_to :increase_version_tag
        @driver.increase_version_tag("minor", "f4cfcc2").should be == @steps
      end
    end


    context "using 'keep' as after_versioned:strategy" do
      before do
        @driver.__notes.after_versioned.stubs(:strategy).returns("keep")
        @steps = <<-STEPS
        git fetch

        git tag -a -m "  - removing files from gemspec
            - .gitignore
            - lastversion.gemspec
          - loading default configuration yaml
          - loading external configuration yaml
        
        Test bugfixes:
        
          - sorting tags according to the mask parser
        " v0.1.0

        git push --tags

        git notes --ref=test_versioning add -m "available on v0.1.0" 8299243c7dac8f27c3572424a348a7f83ef0ce28

        git notes --ref=test_versioning add -m "available on v0.1.0" 2fb8a3281fb6777405aadcd699adb852b615a3e4

        git notes --ref=test_versioning add -m "available on v0.1.0" d7b0fa26ca547b963569d7a82afd7d7ca11b71ae

        git push origin refs/notes/test_versioning
        STEPS
        @steps = @steps.chomp.split(/\n\n/).collect{ |step| step.gsub(/^\s{8}/, '') }
      end
      it "should return steps" do
        @driver.should respond_to :increase_version_tag
        @driver.increase_version_tag("minor", "f4cfcc2").should be == @steps
      end
    end
  end


  context "checking helper methods" do
    it "should load default notes' sections" do
      @driver.send(:__notes_sections).should be == StepUp::CONFIG["notes"]["sections"]
    end
  end
end
