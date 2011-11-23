Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

provider_class = Puppet::Type.type(:volume_group).provider(:lvm)

describe provider_class do
    before do
        @resource = stub("resource")
        @provider = provider_class.new(@resource)
    end

    describe 'when creating' do
        it "should execute 'vgcreate'" do
            @resource.expects(:[]).with(:name).returns('myvg')
            @resource.expects(:should).with(:physical_volumes).returns(%w{/dev/hda})
            @provider.expects(:vgcreate).with('myvg', '/dev/hda')
            @provider.create
        end
    end

    describe 'when destroying' do
        it "should execute 'vgremove'" do
            @resource.expects(:[]).with(:name).returns('myvg')
            @provider.expects(:vgremove).with('myvg')
            @provider.destroy
        end
    end

    # Bug: Spec for the issue where pvs was returning a string, but
    # the code was expecting an array since it called an enumerable
    # method (inject). The fix was to split on newlines in the output
    # of pvs before calling inject.
    describe "when accessing the physical_volumes property" do
        it "should split the line returned from pvs on each newline" do
          # pvs --version
          # LVM version:     2.02.66(2) (2010-05-20)
          # Library version: 1.02.48 (2010-05-20)
          # Driver version:  4.20.0
          pv = "/dev/sdb"
          vg = "vg-test2"
          @resource.expects(:[]).with(:name).returns(vg).at_least_once
          @provider.expects(:pvs).returns("  PV,VG\n  /dev/sda,vg-test1\n  #{pv},#{vg}\n")
          @provider.physical_volumes.should == [pv]
        end
    end
end
