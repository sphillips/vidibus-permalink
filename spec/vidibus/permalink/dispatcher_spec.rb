require "spec_helper"

describe "Vidibus::Permalink::Dispatcher" do
  describe "Dispatcher" do

    let(:category) {Category.create!}
    let(:asset) {Asset.create!}
    let(:category_permalink) {Permalink.create!(:value => "Something", :linkable => category)}
    let(:asset_permalink) {Permalink.create!(:value => "Pretty", :linkable => asset)}
    let(:this) {Vidibus::Permalink::Dispatcher.new("/something/pretty")}

    describe "initializing" do
      it "should require a path" do
        expect {Vidibus::Permalink::Dispatcher.new}.to raise_error(ArgumentError)
      end

      it "should require an absolute request path" do
        expect {Vidibus::Permalink::Dispatcher.new("something/pretty")}.
          to raise_error(Vidibus::Permalink::Dispatcher::PathError)
      end

      it "should accept an absolute request path" do
        this.should be_a(Vidibus::Permalink::Dispatcher)
      end
    end

    describe "#path" do
      it "should return the given request path" do
        this.path.should eql("/something/pretty")
      end
    end

    describe "#parts" do
      it "should contain the parts of the given path" do
        this.parts.should eql(%w[something pretty])
      end
    end

    describe "#objects" do
      before do
        category_permalink
        asset_permalink
      end

      it "should contain all permalinks of given path" do
        this.objects.should eql([category_permalink, asset_permalink])
      end

      it "should reflect the order of the parts in request path" do
        this = Vidibus::Permalink::Dispatcher.new("/pretty/something")
        this.objects.should eql([asset_permalink, category_permalink])
      end

      it "should contain empty records for unresolvable parts of the path" do
        this = Vidibus::Permalink::Dispatcher.new("/some/pretty")
        this.objects.should eql([nil, asset_permalink])
      end

      it "should not contain more than one permalink per linkable" do
        Permalink.create!(:value => "New", :linkable => asset)
        this = Vidibus::Permalink::Dispatcher.new("/pretty/new")
        this.objects.should eql([asset_permalink, nil])
      end
    end

    describe "found?" do
      before do
        category_permalink
        asset_permalink
      end

      it "should return true if all parts of the request path could be resolved" do
        this.found?.should be_true
      end

      it "should return false if any part of the request path could not be resolved" do
        this = Vidibus::Permalink::Dispatcher.new("/some/pretty")
        this.found?.should be_false
      end
    end

    describe "#redirect?" do
      before do
        category_permalink
        asset_permalink
        Permalink.create!(:value => "New", :linkable => asset)
      end

      it "should return true if any part of the path is not current" do
        this.redirect?.should be_true
      end

      it "should return false if all parts of the request path are current" do
        this = Vidibus::Permalink::Dispatcher.new("/something/new")
        this.redirect?.should be_false
      end

      it "should return nil if path could not be resolved" do
        this = Vidibus::Permalink::Dispatcher.new("/something/ugly")
        this.redirect?.should be_nil
      end
    end

    describe "#redirect_path" do
      before do
        category_permalink
        asset_permalink
        Permalink.create!(:value => "New", :linkable => asset)
      end

      it "should return the current request path" do
        this = Vidibus::Permalink::Dispatcher.new("/something/pretty")
        this.redirect_path.should eql("/something/new")
      end

      it "should return nil if redirecting is not necessary" do
        this = Vidibus::Permalink::Dispatcher.new("/something/new")
        this.redirect_path.should be_nil
      end
    end
  end
end