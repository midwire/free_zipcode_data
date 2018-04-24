# frozen_string_literal: true

require 'rake'
require 'readline'
require 'fileutils'

# rubocop:disable Metrics/BlockLength
namespace :version do
  PROJECT_ROOT = File.expand_path(FileUtils.pwd).freeze
  PROJECT_NAME = ENV['PROJECT_NAME'] || File.basename(PROJECT_ROOT)

  desc 'Write changes to the CHANGELOG'
  task :changes do
    text = ask('CHANGELOG Entry:')
    text.insert(
      0,
      "*#{read_version.join('.')}* (#{Time.now.strftime('%B %d, %Y')})\n\n"
    )
    text << "\n"
    prepend_changelog(text)
    launch_editor(changelog)
  end

  desc 'Increment the patch version and write changes to the changelog'
  task :bump_patch do
    exit unless check_branch_and_warn
    major, minor, patch = read_version
    patch = patch.to_i + 1
    write_version_file([major, minor, patch])
    update_readme_version_strings
    Rake::Task['version:changes'].invoke
  end

  desc 'Alias for :bump_patch'
  task bump: :bump_patch

  desc 'Increment the minor version and write changes to the changelog'
  task :bump_minor do
    exit unless check_branch_and_warn
    major, minor, _patch = read_version
    minor = minor.to_i + 1
    patch = 0
    write_version_file([major, minor, patch])
    update_readme_version_strings
    Rake::Task['version:changes'].invoke
  end

  desc 'Increment the major version and write changes to the changelog'
  task :bump_major do
    exit unless check_branch_and_warn
    major, _minor, _patch = read_version
    major = major.to_i + 1
    minor = 0
    patch = 0
    write_version_file([major, minor, patch])
    update_readme_version_strings
    Rake::Task['version:changes'].invoke
  end

  private

  def version_file_path
    split = PROJECT_NAME.split('-')
    "#{PROJECT_ROOT}/lib/#{split.join('/')}/version.rb"
  end

  def module_name
    if PROJECT_NAME =~ /-/
      PROJECT_NAME.split('-').map(&:capitalize).join('::')
    elsif PROJECT_NAME =~ /_/
      PROJECT_NAME.split('_').map(&:capitalize).join
    else
      PROJECT_NAME.capitalize
    end
  end

  def read_version
    silence_warnings do
      load version_file_path
    end
    text = eval("#{module_name}::VERSION")
    text.split('.')
  end

  def write_version_file(version_array)
    version = version_array.join('.')
    new_version = %(  VERSION = '#{version}'.freeze)
    lines = File.readlines(version_file_path)
    File.open(version_file_path, 'w') do |f|
      lines.each do |line|
        if line =~ /VERSION/
          f.write("#{new_version}\n")
        else
          f.write(line)
        end
      end
    end
  end

  def update_readme_version_strings
    version_string = read_version.join('.')
    readme = open('README.md').read
    regex = /^\*\*Version: [0-9\.]+\*\*$/i
    return nil unless readme =~ regex
    File.open('README.md', 'w') do |f|
      f.write(readme.gsub(regex, "**Version: #{version_string}**"))
    end
  end

  def changelog
    return @changelog_path if @changelog_path
    @changelog_path = File.join(PROJECT_ROOT, 'CHANGELOG')
    FileUtils.touch(@changelog_path)
    @changelog_path
  end

  def prepend_changelog(text_array)
    old = File.read(changelog).to_s.chomp
    text_array.push(old)
    File.open(changelog, 'w') do |f|
      text_array.flatten.each do |line|
        f.puts(line)
      end
    end
  end

  # rubocop:disable Lint/AssignmentInCondition
  def ask(message)
    response = []
    puts message
    puts 'Hit <Control>-D when finished:'
    while line = Readline.readline('* ', false)
      response << "* #{line.chomp}" unless line.nil?
    end
    response
  end
  # rubocop:enable Lint/AssignmentInCondition

  def current_branch
    `git symbolic-ref --short HEAD`.chomp
  end

  def branch_warning_message
    <<~STRING
      You typically do not want to bump versions on the 'master' branch
      unless you plan to rebase or back-merge into 'develop'.

      If you don't care or don't know what I'm talking about just enter 'y'
      and continue.

      Optionally, you can hit 'n' to abort and switch your branch to 'develop'
      or whatever branch you use for development, bump the version, merge to
      'master' then 'rake release'.

      Do you really want to bump the version on your 'master' branch? (y/n)
    STRING
  end

  def check_branch_and_warn
    return true unless current_branch == 'master'
    puts(branch_warning_message)
    while (line = $stdin.gets.chomp)
      return true if line =~ /[yY]/
      puts 'Aborting version bump.'
      return false
    end
  end

  def launch_editor(file)
    system("#{ENV['EDITOR']} #{file}") if ENV['EDITOR']
  end

  def silence_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = original_verbosity
  end
end
# rubocop:enable Metrics/BlockLength
