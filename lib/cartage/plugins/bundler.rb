# frozen_string_literal: true

require 'cartage/plugin'
require 'bundler'

# Cartage, a reliable package builder.
class Cartage
  # A utility method for Cartage plug-ins to run a +command+ in the shell
  # without the current Bundler environment. If Bundler is not in use, acts
  # just like #run.
  def run_without_bundler(command)
    runner = -> { run(command) }
    return runner.call unless defined?(::Bundler)
    ::Bundler.with_clean_env(&runner)
  end
end

# Cartage::Bundler is a +:vendor_dependencies+ plug-in for Cartage.
#
# It supports the following configuration options in +plugins.bundler+:
#
# +disabled+:: Whether Cartage::Bundler is disabled. In addition to explicitly
#              disabling Cartage::Bundler, it will disable itself if the
#              Gemfile does not exist.
# +gemfile+:: Provides an alternate name and/or path to the Bundler gemfile.
#             The +gemfile+ option specifies a path relative to the package
#             work path, ending in the name of the gemfile.
#
#                 gemfile: jruby.gemfile
#                 gemfile: jruby/Gemfile
#
# +jobs+:: Provides the number of parallel execution streams.
#
#              jobs: 2
#              jobs: 8
#
# +without_groups+:: An array of the gem groups that should be *excluded* from
#                    installation. If not provided, excludes the +development+
#                    and +test+ groups. Provide an empty array to include all
#                    groups. A specified array for +without_groups+ *replaces*
#                    the default array, so the *default* groups must be
#                    provided in addition to the *new* groups when using this
#                    configuration option.
#
#                        without_groups: [] # All groups will be installed.
#                        # All groups except development, test, and assets.
#                        without_groups:
#                          - development
#                          - test
#                          - assets
#
# +extra_without_groups+:: An array of *additional* gem groups that should be
#                          *excluded* from installation. This adds to the
#                          default list of +without_groups+ (groups
#                          +development+ and +test+).
#
#                               # All groups except development, test, and assets.
#                               extra_without_groups:
#                                 - assets
class Cartage::Bundler < Cartage::Plugin
  VERSION = '1.2' # :nodoc:

  # Cartage::Bundler is only enabled if the Gemfile exists.
  def disabled?
    super || !gemfile.exist?
  end

  # <tt>:vendor_dependencies#vendor_dependencies</tt> performs the steps
  # required to vendor the dependencies introduced by Bundler.
  def vendor_dependencies
    fetch_bundler
    bundle_install
  end

  # <tt>:vendor_dependencies#path</tt> returns the location or locations where
  # Bundler vendors its dependencies. This release of Cartage::Bundler only
  # supports the default location (+vendor/bundle+).
  def path
    'vendor/bundle'
  end

  private

  attr_reader :gemfile, :jobs, :without_groups

  def resolve_plugin_config!(config)
    @gemfile = cartage.work_path.join(config.gemfile || 'Gemfile').expand_path
    @jobs = config.jobs || 4
    @without_groups = Array(config.without_groups || %w(development test))
    @without_groups += Array(config.extra_without_groups) if config.extra_without_groups

    if config.gemfile && config.gemfile != 'Gemfile'
      bundle_command << "--gemfile=#{gemfile}"
    end

    return if without_groups.empty?
    bundle_command.push('--without', *without_groups)
  end

  def fetch_bundler
    Dir.chdir(cartage.work_path) do
      cartage.run %w(gem fetch bundler)
    end
  end

  def bundle_install
    Bundler.with_clean_env do
      Dir.chdir(cartage.work_path) do
        cartage.run bundle_command
      end
    end

    cartage.plugins.request(:post_bundle_install)
  end

  def bundle_command
    @bundle_command ||= [
      'bundle', 'install',
      '--deployment',
      '--clean',
      "--jobs=#{jobs}"
    ]
  end
end
