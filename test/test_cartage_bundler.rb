# frozen_string_literal: true

require 'minitest_config'

describe 'Cartage::Bundler' do
  let(:config) {
    Cartage::Config.new(
      root_path: '/a/b/c',
      name: 'test',
      timestamp: 'value',
      plugins: { bundler: {} }
    )
  }
  let(:cartage) {
    Cartage.new(config)
  }
  let(:subject) { cartage.bundler }

  it 'is disabled if the Gemfile does not exist' do
    instance_stub Pathname, :exist?, -> { false } do
      assert_true subject.disabled?
    end
  end

  describe '#vendor_dependencies' do
    it 'downloads bundler' do
      # This isn't unsafe here, but we aren't testing it.
      disable_unsafe_method subject, :bundle_install

      stub_dir_chdir Pathname('/a/b/c/tmp/test') do
        stub_cartage_run %w(gem fetch bundler) do
          subject.vendor_dependencies
        end
      end
    end

    describe 'runs bundle install' do
      def bundle_command(jobs: 4, without: %w(development test), gemfile: nil)
        %W(bundle install --deployment --clean --jobs=#{jobs}).tap do |command|
          command.push("--gemfile=#{gemfile}") if gemfile
          command.push('--without', *without) unless without.empty?
        end
      end

      it 'with default parameters' do
        disable_unsafe_method subject, :fetch_bundler

        stub_dir_chdir Pathname('/a/b/c/tmp/test') do
          stub_cartage_run bundle_command do
            subject.vendor_dependencies
          end
        end
      end

      it 'with jobs=2' do
        config.plugins.bundler.jobs = 2
        disable_unsafe_method subject, :fetch_bundler

        stub_dir_chdir Pathname('/a/b/c/tmp/test') do
          stub_cartage_run bundle_command jobs: 2 do
            subject.vendor_dependencies
          end
        end
      end

      it 'with gemfile=jruby/Gemfile' do
        config.plugins.bundler.gemfile = 'jruby/Gemfile'
        disable_unsafe_method subject, :fetch_bundler

        stub_dir_chdir Pathname('/a/b/c/tmp/test') do
          stub_cartage_run bundle_command gemfile: '/a/b/c/tmp/test/jruby/Gemfile' do
            subject.vendor_dependencies
          end
        end
      end

      it 'with no exclusions' do
        config.plugins.bundler.without_groups = []
        disable_unsafe_method subject, :fetch_bundler

        stub_dir_chdir Pathname('/a/b/c/tmp/test') do
          stub_cartage_run bundle_command without: [] do
            subject.vendor_dependencies
          end
        end
      end

      it 'with replaced exclusions' do
        config.plugins.bundler.without_groups = 'replaced'
        disable_unsafe_method subject, :fetch_bundler

        stub_dir_chdir Pathname('/a/b/c/tmp/test') do
          stub_cartage_run bundle_command without: [ 'replaced' ] do
            subject.vendor_dependencies
          end
        end
      end

      it 'with extra exclusions' do
        config.plugins.bundler.extra_without_groups = [ 'extra' ]
        disable_unsafe_method subject, :fetch_bundler

        stub_dir_chdir Pathname('/a/b/c/tmp/test') do
          stub_cartage_run bundle_command without: %w(development test extra) do
            subject.vendor_dependencies
          end
        end
      end
    end
  end

  it "#path returns 'vendor/bundle'" do
    assert_equal 'vendor/bundle', subject.path
  end

  it 'is returned when :vendor_dependencies is requested' do
    instance_stub Cartage::Bundler, :enabled?, -> { true } do
      assert_equal [ subject ], cartage.plugins.send(:offering, :vendor_dependencies)
    end
  end
end
